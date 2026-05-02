use std::collections::HashMap;
use std::path::PathBuf;
use std::sync::Arc;

use anyhow::Context;
use hoplixi_file_crypt::progress::ProgressEvent;
use hoplixi_file_crypt::{DecryptOptions, EncryptOptions, FileCrypt};

use crate::frb_generated::StreamSink;

use super::types::*;

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
pub(super) async fn encrypt_file(opts: FrbEncryptOptions, sink: StreamSink<FrbEncryptEvent>) {
    let chunk_size = opts.chunk_size.bytes();
    let sink = Arc::new(sink);
    let sink_clone = Arc::clone(&sink);

    let progress_cb: hoplixi_file_crypt::progress::ProgressCallback =
        Arc::new(move |event: ProgressEvent| {
            let _ = sink_clone.add(FrbEncryptEvent::Progress(event.into()));
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
            let _ = sink.add(FrbEncryptEvent::Error(format!("{e:#}")));
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
pub(super) async fn decrypt_file(opts: FrbDecryptOptions, sink: StreamSink<FrbDecryptEvent>) {
    let chunk_size = opts.chunk_size.bytes();
    let sink = Arc::new(sink);
    let sink_clone = Arc::clone(&sink);

    let progress_cb: hoplixi_file_crypt::progress::ProgressCallback =
        Arc::new(move |event: ProgressEvent| {
            let _ = sink_clone.add(FrbDecryptEvent::Progress(event.into()));
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
            let _ = sink.add(FrbDecryptEvent::Error(format!("{e:#}")));
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
pub(super) async fn encrypt_batch(
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
                let _ = sink_file.add(FrbBatchEncryptEvent::FileProgress {
                    file_index,
                    total_files,
                    current_file: current_file_clone.clone(),
                    progress: event.into(),
                });
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
                    output_path: result.output_path.to_string_lossy().into_owned(),
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
pub(super) async fn decrypt_batch(
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
                let _ = sink_file.add(FrbBatchDecryptEvent::FileProgress {
                    file_index,
                    total_files,
                    current_file: current_file_clone.clone(),
                    progress: event.into(),
                });
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
/// Much faster than a full `decrypt_file` - suitable for showing file
/// information in the UI before the user decides to decrypt.
pub(super) async fn read_encrypted_header(
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
