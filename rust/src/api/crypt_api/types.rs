use hoplixi_file_crypt::config::{DEFAULT_DESKTOP_CHUNK_SIZE, DEFAULT_MOBILE_CHUNK_SIZE};
use hoplixi_file_crypt::progress::{ProgressEvent, ProgressStage};

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
            ProgressStage::CompressingDirectory => FrbProgressStage::CompressingDirectory,
            ProgressStage::CompressingGzip => FrbProgressStage::CompressingGzip,
            ProgressStage::Encrypting => FrbProgressStage::Encrypting,
            ProgressStage::Decrypting => FrbProgressStage::Decrypting,
            ProgressStage::DecompressingGzip => FrbProgressStage::DecompressingGzip,
            ProgressStage::DecompressingDirectory => FrbProgressStage::DecompressingDirectory,
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
    /// Completion percentage 0.0-100.0. 0 when total is unknown.
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
    /// Emitted exactly once at the end - carries the final result.
    Done(FrbEncryptResult),
    /// Operation failed. Always the last event in the stream.
    Error(String),
}

/// Event emitted by `decrypt_file`.
#[derive(Debug, Clone)]
pub enum FrbDecryptEvent {
    /// Intermediate progress update.
    Progress(FrbProgressEvent),
    /// Emitted exactly once at the end - carries the final result.
    Done(FrbDecryptResult),
    /// Operation failed. Always the last event in the stream.
    Error(String),
}

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

/// Key-value metadata entry stored in the encrypted header.
#[derive(Debug, Clone)]
pub struct FrbKeyValue {
    pub key: String,
    pub value: String,
}

/// Chunk-size preset.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum FrbChunkSizePreset {
    /// 1 MB - optimised for desktop (default).
    Desktop,
    /// 256 KB - optimised for mobile.
    Mobile,
    /// Custom size in bytes.
    Custom(u32),
}

impl FrbChunkSizePreset {
    pub(super) fn bytes(self) -> u32 {
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
