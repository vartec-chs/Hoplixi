use std::collections::HashMap;
use std::path::PathBuf;
use std::sync::Arc;

use anyhow::Context;
use hoplixi_file_crypt::{
    DecryptOptions, EncryptOptions, FileCrypt,
};
use hoplixi_file_crypt::config::{
    DEFAULT_DESKTOP_CHUNK_SIZE, DEFAULT_MOBILE_CHUNK_SIZE,
};
use hoplixi_file_crypt::progress::{ProgressEvent, ProgressStage};

use crate::frb_generated::StreamSink;

// ─── Progress types ───────────────────────────────────────────────────────────

/// Stage of the encryption/decryption pipeline.
#[derive(Debug, Clone)]
pub enum FrbProgressStage {
    CompressingDirectory,
    CompressingGzip,
    Encrypting,
    Decrypting,
    DecompressingGzip,
    DecompressingDirectory,
    Done,
}

impl From<ProgressStage> for FrbProgressStage {
    fn from(stage: ProgressStage) -> Self {
        match stage {
            ProgressStage::CompressingDirectory => {
                FrbProgressStage::CompressingDirectory
            }
            ProgressStage::CompressingGzip => {
                FrbProgressStage::CompressingGzip
            }
            ProgressStage::Encrypting => FrbProgressStage::Encrypting,
            ProgressStage::Decrypting => FrbProgressStage::Decrypting,
            ProgressStage::DecompressingGzip => {
                FrbProgressStage::DecompressingGzip
            }
            ProgressStage::DecompressingDirectory => {
                FrbProgressStage::DecompressingDirectory
            }
            ProgressStage::Done => FrbProgressStage::Done,
        }
    }
}

/// Progress event emitted during encryption/decryption.
#[derive(Debug, Clone)]
pub struct FrbProgressEvent {
    /// Current pipeline stage.
    pub stage: FrbProgressStage,
    /// Bytes processed so far.
    pub bytes_processed: u64,
    /// Total bytes expected (0 if unknown).
    pub total_bytes: u64,
    /// Completion percentage 0.0–100.0. 0 when total is unknown.
    pub percentage: f64,
}

impl From<ProgressEvent> for FrbProgressEvent {
    fn from(e: ProgressEvent) -> Self {
        FrbProgressEvent {
            stage: e.stage.into(),
            bytes_processed: e.bytes_processed,
            total_bytes: e.total_bytes,
            percentage: e.percentage(),
        }
    }
}

// ─── Single-file event ────────────────────────────────────────────────────────

/// Event emitted by `encrypt_file` / `decrypt_file`.
///
/// Listen to the stream in Dart:
/// ```dart
/// final stream = encryptFile(opts: opts);
/// await for (final event in stream) {
///   switch (event) {
///     case FrbEncryptEvent_Progress(:final field0): // update UI
///     case FrbEncryptEvent_Done(:final field0):     // result ready
///   }
/// }
/// ```
#[derive(Debug, Clone)]
pub enum FrbEncryptEvent {
    /// Intermediate progress update.
    Progress(FrbProgressEvent),
    /// Emitted exactly once at the end – carries the final result.
    Done(FrbEncryptResult),
    /// Operation failed. Always the last event in the stream.
    Error(String),
}

/// Event emitted by `decrypt_file`.
#[derive(Debug, Clone)]
pub enum FrbDecryptEvent {
    /// Intermediate progress update.
    Progress(FrbProgressEvent),
    /// Emitted exactly once at the end – carries the final result.
    Done(FrbDecryptResult),
    /// Operation failed. Always the last event in the stream.
    Error(String),
}

// ─── Batch event ──────────────────────────────────────────────────────────────

/// Event emitted by `encrypt_batch`.
#[derive(Debug, Clone)]
pub enum FrbBatchEncryptEvent {
    /// Progress for the currently processed file.
    FileProgress {
        file_index: u32,
        total_files: u32,
        current_file: String,
        progress: FrbProgressEvent,
    },
    /// One file finished successfully.
    FileDone {
        file_index: u32,
        result: FrbEncryptResult,
    },
    /// One file failed; processing continues for the rest.
    FileError {
        file_index: u32,
        input_path: String,
        error: String,
    },
    /// Emitted once when all files are processed.
    AllDone(FrbBatchEncryptResult),
}

/// Event emitted by `decrypt_batch`.
#[derive(Debug, Clone)]
pub enum FrbBatchDecryptEvent {
    /// Progress for the currently processed file.
    FileProgress {
        file_index: u32,
        total_files: u32,
        current_file: String,
        progress: FrbProgressEvent,
    },
    /// One file finished successfully.
    FileDone {
        file_index: u32,
        result: FrbDecryptResult,
    },
    /// One file failed; processing continues for the rest.
    FileError {
        file_index: u32,
        input_path: String,
        error: String,
    },
    /// Emitted once when all files are processed.
    AllDone(FrbBatchDecryptResult),
}

// ─── Options ──────────────────────────────────────────────────────────────────

/// Key-value metadata entry stored in the encrypted header.
#[derive(Debug, Clone)]
pub struct FrbKeyValue {
    pub key: String,
    pub value: String,
}

/// Chunk-size preset.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum FrbChunkSizePreset {
    /// 1 MB – optimised for desktop (default).
    Desktop,
    /// 256 KB – optimised for mobile.
    Mobile,
    /// Custom size in bytes.
    Custom(u32),
}

impl FrbChunkSizePreset {
    fn bytes(self) -> u32 {
        match self {
            FrbChunkSizePreset::Desktop => DEFAULT_DESKTOP_CHUNK_SIZE,
            FrbChunkSizePreset::Mobile => DEFAULT_MOBILE_CHUNK_SIZE,
            FrbChunkSizePreset::Custom(n) => n,
        }
    }
}

/// Options for encrypting a single file or directory.
#[derive(Debug, Clone)]
pub struct FrbEncryptOptions {
    /// Path to the input file or directory.
    pub input_path: String,
    /// Directory where the encrypted output will be saved.
    pub output_dir: String,
    /// User password used for key derivation.
    pub password: String,
    /// Whether to apply Gzip compression before encryption.
    pub gzip_compressed: bool,
    /// Optional UUID to embed in the output filename and header.
    /// Auto-generated if `None`.
    pub uuid: Option<String>,
    /// Output file extension. Defaults to `.enc`.
    pub output_extension: Option<String>,
    /// Temporary directory for intermediate files.
    /// Defaults to `output_dir`.
    pub temp_dir: Option<String>,
    /// Additional metadata to embed in the encrypted header.
    pub metadata: Vec<FrbKeyValue>,
    /// Chunk-size preset (desktop is the default).
    pub chunk_size: FrbChunkSizePreset,
}

impl FrbEncryptOptions {
    /// Minimal constructor: only the required fields.
    pub fn simple(
        input_path: String,
        output_dir: String,
        password: String,
    ) -> Self {
        FrbEncryptOptions {
            input_path,
            output_dir,
            password,
            gzip_compressed: false,
            uuid: None,
            output_extension: None,
            temp_dir: None,
            metadata: Vec::new(),
            chunk_size: FrbChunkSizePreset::Desktop,
        }
    }
}

/// Options for decrypting a single `.enc` file.
#[derive(Debug, Clone)]
pub struct FrbDecryptOptions {
    /// Path to the encrypted `.enc` file.
    pub input_path: String,
    /// Directory where the decrypted output will be saved.
    pub output_dir: String,
    /// User password.
    pub password: String,
    /// Temporary directory for intermediate files.
    pub temp_dir: Option<String>,
    /// Chunk-size preset.
    pub chunk_size: FrbChunkSizePreset,
}

impl FrbDecryptOptions {
    /// Minimal constructor.
    pub fn simple(
        input_path: String,
        output_dir: String,
        password: String,
    ) -> Self {
        FrbDecryptOptions {
            input_path,
            output_dir,
            password,
            temp_dir: None,
            chunk_size: FrbChunkSizePreset::Desktop,
        }
    }
}

/// Options for encrypting multiple files in a batch.
#[derive(Debug, Clone)]
pub struct FrbBatchEncryptOptions {
    /// Paths to input files or directories.
    pub input_paths: Vec<String>,
    /// Common output directory for all encrypted files.
    pub output_dir: String,
    /// User password (same for every file in the batch).
    pub password: String,
    /// Whether to apply Gzip compression before encryption.
    pub gzip_compressed: bool,
    /// Temporary directory for intermediate files.
    pub temp_dir: Option<String>,
    /// Additional metadata to embed in every encrypted header.
    pub metadata: Vec<FrbKeyValue>,
    /// Chunk-size preset.
    pub chunk_size: FrbChunkSizePreset,
}

/// Options for decrypting multiple `.enc` files in a batch.
#[derive(Debug, Clone)]
pub struct FrbBatchDecryptOptions {
    /// Paths to encrypted `.enc` files.
    pub input_paths: Vec<String>,
    /// Common output directory for all decrypted files.
    pub output_dir: String,
    /// User password.
    pub password: String,
    /// Temporary directory for intermediate files.
    pub temp_dir: Option<String>,
    /// Chunk-size preset.
    pub chunk_size: FrbChunkSizePreset,
}

// ─── Results ──────────────────────────────────────────────────────────────────

/// Returned after a successful encryption.
#[derive(Debug, Clone)]
pub struct FrbEncryptResult {
    /// Absolute path to the encrypted output file.
    pub output_path: String,
    /// UUID embedded in the encrypted header.
    pub uuid: String,
    /// Original file size (bytes) before any compression.
    pub original_size: u64,
}

/// Metadata decoded from an encrypted header.
#[derive(Debug, Clone)]
pub struct FrbDecryptedMetadata {
    pub original_filename: String,
    pub original_extension: String,
    pub gzip_compressed: bool,
    pub original_size: u64,
    pub uuid: String,
    pub metadata: Vec<FrbKeyValue>,
}

/// Returned after a successful decryption.
#[derive(Debug, Clone)]
pub struct FrbDecryptResult {
    /// Absolute path to the decrypted output file / directory.
    pub output_path: String,
    /// Decoded metadata from the encrypted header.
    pub metadata: FrbDecryptedMetadata,
}

/// Error record for a single failed item in a batch operation.
#[derive(Debug, Clone)]
pub struct FrbBatchError {
    pub input_path: String,
    pub error: String,
}

/// Summary returned as the final `AllDone` event of `encrypt_batch`.
#[derive(Debug, Clone)]
pub struct FrbBatchEncryptResult {
    pub succeeded: Vec<FrbEncryptResult>,
    pub failed: Vec<FrbBatchError>,
}

/// Summary returned as the final `AllDone` event of `decrypt_batch`.
#[derive(Debug, Clone)]
pub struct FrbBatchDecryptResult {
    pub succeeded: Vec<FrbDecryptResult>,
    pub failed: Vec<FrbBatchError>,
}

// ─── Internal helpers ─────────────────────────────────────────────────────────

fn kv_to_map(pairs: Vec<FrbKeyValue>) -> HashMap<String, String> {
    pairs.into_iter().map(|kv| (kv.key, kv.value)).collect()
}

fn map_to_kv(map: HashMap<String, String>) -> Vec<FrbKeyValue> {
    map.into_iter()
        .map(|(key, value)| FrbKeyValue { key, value })
        .collect()
}

fn build_encrypt_opts(
    opts: FrbEncryptOptions,
    progress_cb: Option<hoplixi_file_crypt::progress::ProgressCallback>,
) -> EncryptOptions {
    let metadata = if opts.metadata.is_empty() {
        None
    } else {
        Some(kv_to_map(opts.metadata))
    };

    EncryptOptions {
        input_path: PathBuf::from(&opts.input_path),
        output_dir: PathBuf::from(&opts.output_dir),
        password: opts.password,
        gzip_compressed: opts.gzip_compressed,
        uuid: opts.uuid,
        output_extension: opts.output_extension,
        temp_dir: opts.temp_dir.map(PathBuf::from),
        metadata,
        progress: progress_cb,
    }
}

fn build_decrypt_opts(
    opts: FrbDecryptOptions,
    progress_cb: Option<hoplixi_file_crypt::progress::ProgressCallback>,
) -> DecryptOptions {
    DecryptOptions {
        input_path: PathBuf::from(&opts.input_path),
        output_dir: PathBuf::from(&opts.output_dir),
        password: opts.password,
        temp_dir: opts.temp_dir.map(PathBuf::from),
        progress: progress_cb,
    }
}

// ─── Public API ───────────────────────────────────────────────────────────────

/// Encrypt a single file or directory.
///
/// Events (progress + final result) are emitted through `sink`.
/// The stream is always closed after the final `FrbEncryptEvent::Done`
/// or when an error is forwarded.
///
/// # Dart usage
/// ```dart
/// final stream = api.encryptFile(opts: opts);
/// await for (final event in stream) {
///   switch (event) {
///     case FrbEncryptEvent_Progress(:final field0):
///       updateProgress(field0);
///     case FrbEncryptEvent_Done(:final field0):
///       handleResult(field0);
///   }
/// }
/// ```
pub async fn encrypt_file(
    opts: FrbEncryptOptions,
    sink: StreamSink<FrbEncryptEvent>,
) {
    let chunk_size = opts.chunk_size.bytes();
    let sink = Arc::new(sink);
    let sink_clone = Arc::clone(&sink);

    let progress_cb: hoplixi_file_crypt::progress::ProgressCallback =
        Arc::new(move |event: ProgressEvent| {
            let _ = sink_clone
                .add(FrbEncryptEvent::Progress(event.into()));
        });

    let engine = FileCrypt::with_chunk_size(chunk_size);
    let internal_opts = build_encrypt_opts(opts, Some(progress_cb));

    match engine.encrypt(internal_opts).await {
        Ok(result) => {
            let frb_result = FrbEncryptResult {
                output_path: result.output_path.to_string_lossy().into_owned(),
                uuid: result.uuid,
                original_size: result.original_size,
            };
            let _ = sink.add(FrbEncryptEvent::Done(frb_result));
        }
        Err(e) => {
            let _ = sink.add(FrbEncryptEvent::Error(
                format!("{e:#}"),
            ));
        }
    }
}

/// Decrypt a single `.enc` file.
///
/// Events (progress + final result) are emitted through `sink`.
///
/// # Dart usage
/// ```dart
/// final stream = api.decryptFile(opts: opts);
/// await for (final event in stream) {
///   switch (event) {
///     case FrbDecryptEvent_Progress(:final field0):
///       updateProgress(field0);
///     case FrbDecryptEvent_Done(:final field0):
///       handleResult(field0);
///   }
/// }
/// ```
pub async fn decrypt_file(
    opts: FrbDecryptOptions,
    sink: StreamSink<FrbDecryptEvent>,
) {
    let chunk_size = opts.chunk_size.bytes();
    let sink = Arc::new(sink);
    let sink_clone = Arc::clone(&sink);

    let progress_cb: hoplixi_file_crypt::progress::ProgressCallback =
        Arc::new(move |event: ProgressEvent| {
            let _ = sink_clone
                .add(FrbDecryptEvent::Progress(event.into()));
        });

    let engine = FileCrypt::with_chunk_size(chunk_size);
    let internal_opts = build_decrypt_opts(opts, Some(progress_cb));

    match engine.decrypt(internal_opts).await {
        Ok(result) => {
            let frb_metadata = FrbDecryptedMetadata {
                original_filename: result.metadata.original_filename,
                original_extension: result.metadata.original_extension,
                gzip_compressed: result.metadata.gzip_compressed,
                original_size: result.metadata.original_size,
                uuid: result.metadata.uuid,
                metadata: map_to_kv(result.metadata.metadata),
            };
            let frb_result = FrbDecryptResult {
                output_path: result.output_path.to_string_lossy().into_owned(),
                metadata: frb_metadata,
            };
            let _ = sink.add(FrbDecryptEvent::Done(frb_result));
        }
        Err(e) => {
            let _ = sink.add(FrbDecryptEvent::Error(
                format!("{e:#}"),
            ));
        }
    }
}

/// Encrypt multiple files sequentially.
///
/// Events (per-file progress, per-file results, final summary) are emitted
/// through `sink`. Processing continues even if individual files fail.
///
/// # Dart usage
/// ```dart
/// final stream = api.encryptBatch(opts: opts);
/// await for (final event in stream) {
///   switch (event) {
///     case FrbBatchEncryptEvent_FileProgress(...): ...
///     case FrbBatchEncryptEvent_FileDone(...):    ...
///     case FrbBatchEncryptEvent_FileError(...):   ...
///     case FrbBatchEncryptEvent_AllDone(...):     ...
///   }
/// }
/// ```
pub async fn encrypt_batch(
    opts: FrbBatchEncryptOptions,
    sink: StreamSink<FrbBatchEncryptEvent>,
) -> anyhow::Result<()> {
    let total_files = opts.input_paths.len() as u32;
    let sink = Arc::new(sink);

    let mut succeeded = Vec::new();
    let mut failed = Vec::new();

    for (idx, input_path) in opts.input_paths.iter().enumerate() {
        let file_index = idx as u32;
        let current_file = input_path.clone();

        let sink_file = Arc::clone(&sink);
        let current_file_clone = current_file.clone();

        let progress_cb: hoplixi_file_crypt::progress::ProgressCallback =
            Arc::new(move |event: ProgressEvent| {
                let _ = sink_file.add(
                    FrbBatchEncryptEvent::FileProgress {
                        file_index,
                        total_files,
                        current_file: current_file_clone.clone(),
                        progress: event.into(),
                    },
                );
            });

        let metadata = if opts.metadata.is_empty() {
            None
        } else {
            Some(kv_to_map(opts.metadata.clone()))
        };

        let internal_opts = EncryptOptions {
            input_path: PathBuf::from(input_path),
            output_dir: PathBuf::from(&opts.output_dir),
            password: opts.password.clone(),
            gzip_compressed: opts.gzip_compressed,
            uuid: None,
            output_extension: None,
            temp_dir: opts.temp_dir.as_deref().map(PathBuf::from),
            metadata,
            progress: Some(progress_cb),
        };

        let engine = FileCrypt::with_chunk_size(opts.chunk_size.bytes());

        match engine.encrypt(internal_opts).await {
            Ok(result) => {
                let frb_result = FrbEncryptResult {
                    output_path: result
                        .output_path
                        .to_string_lossy()
                        .into_owned(),
                    uuid: result.uuid,
                    original_size: result.original_size,
                };
                let _ = sink.add(FrbBatchEncryptEvent::FileDone {
                    file_index,
                    result: frb_result.clone(),
                });
                succeeded.push(frb_result);
            }
            Err(e) => {
                let _ = sink.add(FrbBatchEncryptEvent::FileError {
                    file_index,
                    input_path: current_file.clone(),
                    error: e.to_string(),
                });
                failed.push(FrbBatchError {
                    input_path: current_file,
                    error: e.to_string(),
                });
            }
        }
    }

    let summary = FrbBatchEncryptResult { succeeded, failed };
    let _ = sink.add(FrbBatchEncryptEvent::AllDone(summary));
    Ok(())
}

/// Decrypt multiple `.enc` files sequentially.
///
/// Events (per-file progress, per-file results, final summary) are emitted
/// through `sink`. Processing continues even if individual files fail.
pub async fn decrypt_batch(
    opts: FrbBatchDecryptOptions,
    sink: StreamSink<FrbBatchDecryptEvent>,
) -> anyhow::Result<()> {
    let total_files = opts.input_paths.len() as u32;
    let sink = Arc::new(sink);

    let mut succeeded = Vec::new();
    let mut failed = Vec::new();

    for (idx, input_path) in opts.input_paths.iter().enumerate() {
        let file_index = idx as u32;
        let current_file = input_path.clone();

        let sink_file = Arc::clone(&sink);
        let current_file_clone = current_file.clone();

        let progress_cb: hoplixi_file_crypt::progress::ProgressCallback =
            Arc::new(move |event: ProgressEvent| {
                let _ = sink_file.add(
                    FrbBatchDecryptEvent::FileProgress {
                        file_index,
                        total_files,
                        current_file: current_file_clone.clone(),
                        progress: event.into(),
                    },
                );
            });

        let internal_opts = DecryptOptions {
            input_path: PathBuf::from(input_path),
            output_dir: PathBuf::from(&opts.output_dir),
            password: opts.password.clone(),
            temp_dir: opts.temp_dir.as_deref().map(PathBuf::from),
            progress: Some(progress_cb),
        };

        let engine = FileCrypt::with_chunk_size(opts.chunk_size.bytes());

        match engine.decrypt(internal_opts).await {
            Ok(result) => {
                let frb_metadata = FrbDecryptedMetadata {
                    original_filename: result.metadata.original_filename,
                    original_extension: result
                        .metadata
                        .original_extension,
                    gzip_compressed: result.metadata.gzip_compressed,
                    original_size: result.metadata.original_size,
                    uuid: result.metadata.uuid,
                    metadata: map_to_kv(result.metadata.metadata),
                };
                let frb_result = FrbDecryptResult {
                    output_path: result
                        .output_path
                        .to_string_lossy()
                        .into_owned(),
                    metadata: frb_metadata,
                };
                let _ = sink.add(FrbBatchDecryptEvent::FileDone {
                    file_index,
                    result: frb_result.clone(),
                });
                succeeded.push(frb_result);
            }
            Err(e) => {
                let _ = sink.add(FrbBatchDecryptEvent::FileError {
                    file_index,
                    input_path: current_file.clone(),
                    error: e.to_string(),
                });
                failed.push(FrbBatchError {
                    input_path: current_file,
                    error: e.to_string(),
                });
            }
        }
    }

    let summary = FrbBatchDecryptResult { succeeded, failed };
    let _ = sink.add(FrbBatchDecryptEvent::AllDone(summary));
    Ok(())
}

/// Read only the header of an encrypted file without decrypting the data.
///
/// Returns the decoded metadata (filename, extension, UUID, tags, etc.)
/// using the provided password to decrypt the header.
///
/// Much faster than a full `decrypt_file` — suitable for showing file
/// information in the UI before the user decides to decrypt.
pub async fn read_encrypted_header(
    input_path: String,
    password: String,
) -> anyhow::Result<FrbDecryptedMetadata> {
    let engine = FileCrypt::default();

    let metadata = engine
        .decrypt_header(PathBuf::from(&input_path), password)
        .await
        .context("read_encrypted_header failed")?;

    Ok(FrbDecryptedMetadata {
        original_filename: metadata.original_filename,
        original_extension: metadata.original_extension,
        gzip_compressed: metadata.gzip_compressed,
        original_size: metadata.original_size,
        uuid: metadata.uuid,
        metadata: map_to_kv(metadata.metadata),
    })
}
