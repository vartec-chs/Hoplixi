pub mod operations;
pub mod types;

use crate::frb_generated::StreamSink;

pub use types::*;

impl FrbEncryptOptions {
    /// Minimal constructor: only the required fields.
    pub fn simple(input_path: String, output_dir: String, password: String) -> Self {
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

impl FrbDecryptOptions {
    /// Minimal constructor.
    pub fn simple(input_path: String, output_dir: String, password: String) -> Self {
        FrbDecryptOptions {
            input_path,
            output_dir,
            password,
            temp_dir: None,
            chunk_size: FrbChunkSizePreset::Desktop,
        }
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
pub async fn encrypt_file(opts: FrbEncryptOptions, sink: StreamSink<FrbEncryptEvent>) {
    operations::encrypt_file(opts, sink).await;
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
pub async fn decrypt_file(opts: FrbDecryptOptions, sink: StreamSink<FrbDecryptEvent>) {
    operations::decrypt_file(opts, sink).await;
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
    operations::encrypt_batch(opts, sink).await
}

/// Decrypt multiple `.enc` files sequentially.
///
/// Events (per-file progress, per-file results, final summary) are emitted
/// through `sink`. Processing continues even if individual files fail.
pub async fn decrypt_batch(
    opts: FrbBatchDecryptOptions,
    sink: StreamSink<FrbBatchDecryptEvent>,
) -> anyhow::Result<()> {
    operations::decrypt_batch(opts, sink).await
}

/// Read only the header of an encrypted file without decrypting the data.
///
/// Returns the decoded metadata (filename, extension, UUID, tags, etc.)
/// using the provided password to decrypt the header.
///
/// Much faster than a full `decrypt_file` - suitable for showing file
/// information in the UI before the user decides to decrypt.
pub async fn read_encrypted_header(
    input_path: String,
    password: String,
) -> anyhow::Result<FrbDecryptedMetadata> {
    operations::read_encrypted_header(input_path, password).await
}
