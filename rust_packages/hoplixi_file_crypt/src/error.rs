use thiserror::Error;

/// All possible errors in the encryption/decryption pipeline.
#[derive(Debug, Error)]
pub enum CryptError {
    #[error("I/O error: {0}")]
    Io(#[from] std::io::Error),

    #[error("Encryption failed: {0}")]
    Encryption(String),

    #[error("Decryption failed: {0}")]
    Decryption(String),

    #[error("Invalid magic bytes: expected HOPLIXI")]
    InvalidMagic,

    #[error("Unsupported format version: {0}")]
    UnsupportedVersion(u16),

    #[error("Invalid password or corrupted data")]
    InvalidPassword,

    #[error("Corrupted data: {0}")]
    CorruptedData(String),

    #[error("Compression error: {0}")]
    Compression(String),

    #[error("Key derivation error: {0}")]
    KeyDerivation(String),

    #[error("Header parse error: {0}")]
    HeaderParse(String),

    #[error("Invalid header: {0}")]
    InvalidHeader(String),

    #[error("Serialization error: {0}")]
    Serialization(String),
}

pub type Result<T> = std::result::Result<T, CryptError>;
