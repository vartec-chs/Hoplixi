use std::collections::HashMap;
use std::path::PathBuf;

use crate::header::encrypted::EncryptedMetadata;
use crate::progress::ProgressCallback;

/// Options for file encryption.
pub struct EncryptOptions {
    /// Path to the input file or directory.
    pub input_path: PathBuf,
    /// Directory where the encrypted output will be saved.
    pub output_dir: PathBuf,
    /// Optional UUID for the output file name.
    /// Generated automatically if not provided.
    pub uuid: Option<String>,
    /// User password (used for key derivation).
    pub password: String,
    /// Optional progress callback.
    pub progress: Option<ProgressCallback>,
    /// Whether to apply gzip compression before encryption.
    pub gzip_compressed: bool,
    /// Output file extension (default: ".enc").
    pub output_extension: Option<String>,
    /// Temporary directory for intermediate files.
    pub temp_dir: Option<PathBuf>,
    /// Additional key-value metadata to store in the
    /// encrypted header.
    pub metadata: Option<HashMap<String, String>>,
}

/// Options for file decryption.
pub struct DecryptOptions {
    /// Path to the encrypted `.enc` file.
    pub input_path: PathBuf,
    /// Directory where the decrypted output will be saved.
    pub output_dir: PathBuf,
    /// User password.
    pub password: String,
    /// Optional progress callback.
    pub progress: Option<ProgressCallback>,
    /// Temporary directory for intermediate files.
    pub temp_dir: Option<PathBuf>,
}

/// Result returned after successful encryption.
#[derive(Debug)]
pub struct EncryptResult {
    /// Path to the encrypted output file.
    pub output_path: PathBuf,
    /// UUID assigned to the encrypted file.
    pub uuid: String,
    /// Original file size before compression/encryption.
    pub original_size: u64,
}

/// Result returned after successful decryption.
#[derive(Debug)]
pub struct DecryptResult {
    /// Path to the decrypted output file or directory.
    pub output_path: PathBuf,
    /// Metadata from the encrypted header.
    pub metadata: EncryptedMetadata,
}
