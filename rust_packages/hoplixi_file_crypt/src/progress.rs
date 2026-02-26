use std::sync::Arc;

/// Stage of the encryption/decryption pipeline.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ProgressStage {
    /// Compressing a directory to 7z.
    CompressingDirectory,
    /// Applying optional gzip compression.
    CompressingGzip,
    /// Encrypting data chunks.
    Encrypting,
    /// Decrypting data chunks.
    Decrypting,
    /// Decompressing gzip data.
    DecompressingGzip,
    /// Decompressing 7z archive.
    DecompressingDirectory,
    /// Operation completed.
    Done,
}

/// Progress event emitted during encryption/decryption.
#[derive(Debug, Clone)]
pub struct ProgressEvent {
    /// Current pipeline stage.
    pub stage: ProgressStage,
    /// Bytes processed so far in the current stage.
    pub bytes_processed: u64,
    /// Total bytes expected (0 if unknown).
    pub total_bytes: u64,
}

impl ProgressEvent {
    /// Create a new event.
    pub fn new(
        stage: ProgressStage,
        bytes_processed: u64,
        total_bytes: u64,
    ) -> Self {
        Self {
            stage,
            bytes_processed,
            total_bytes,
        }
    }

    /// Percentage complete (0.0 – 100.0). Returns 0 if total is unknown.
    pub fn percentage(&self) -> f64 {
        if self.total_bytes == 0 {
            return 0.0;
        }
        (self.bytes_processed as f64 / self.total_bytes as f64) * 100.0
    }
}

/// Thread-safe progress callback type.
pub type ProgressCallback = Arc<dyn Fn(ProgressEvent) + Send + Sync>;
