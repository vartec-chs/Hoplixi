/// Magic bytes identifying the encrypted file format.
pub const MAGIC: &[u8; 7] = b"HOPLIXI";

/// Current format version.
pub const VERSION: u16 = 1;

/// Salt length in bytes.
pub const SALT_LEN: usize = 32;

/// XChaCha20-Poly1305 nonce length (24 bytes).
pub const NONCE_LEN: usize = 24;

/// Poly1305 authentication tag length (16 bytes).
pub const TAG_LEN: usize = 16;

/// Encryption key length (256 bits).
pub const KEY_LEN: usize = 32;

/// Random portion of data base nonce (bytes).
pub const NONCE_RANDOM_LEN: usize = 16;

/// Counter portion of data base nonce (bytes).
pub const NONCE_COUNTER_LEN: usize = 8;

/// Default chunk size for desktop platforms (1 MB).
pub const DEFAULT_DESKTOP_CHUNK_SIZE: u32 = 1024 * 1024;

/// Default chunk size for mobile platforms (256 KB).
pub const DEFAULT_MOBILE_CHUNK_SIZE: u32 = 256 * 1024;

/// Default file extension for encrypted files.
pub const DEFAULT_EXTENSION: &str = ".enc";

/// Argon2 default parameters.
pub mod argon2_defaults {
    /// Number of iterations.
    pub const T_COST: u32 = 3;

    /// Memory cost in KiB (32 MB).
    pub const M_COST_KIB: u32 = 32 * 1024;

    /// Degree of parallelism.
    pub const PARALLELISM: u32 = 4;
}

/// Public header fixed size in bytes.
/// MAGIC(7) + VERSION(2) + SALT(32) + ARGON2_T(4) + ARGON2_M(4)
/// + ARGON2_P(4) + CHUNK_SIZE(4) + DATA_BASE_NONCE(24)
/// + HEADER_NONCE(24) + ENCRYPTED_META_LEN(4) = 109
pub const PUBLIC_HEADER_SIZE: usize = 109;

/// HKDF info string for deriving the header encryption key.
pub const HKDF_INFO_HEADER: &[u8] = b"hoplixi-header-key-v1";

/// HKDF info string for deriving the data encryption key.
pub const HKDF_INFO_DATA: &[u8] = b"hoplixi-data-key-v1";

// ── Header validation limits (anti-DoS) ──────────────────────

/// Minimum allowed chunk size (64 bytes).
pub const MIN_CHUNK_SIZE: u32 = 64;

/// Maximum allowed chunk size (64 MB).
pub const MAX_CHUNK_SIZE: u32 = 64 * 1024 * 1024;

/// Maximum allowed encrypted metadata length (1 MB).
pub const MAX_ENCRYPTED_META_LEN: u32 = 1024 * 1024;

/// Maximum Argon2 t_cost (iterations).
pub const MAX_ARGON2_T_COST: u32 = 100;

/// Maximum Argon2 m_cost_kib (4 GB).
pub const MAX_ARGON2_M_COST_KIB: u32 = 4 * 1024 * 1024;

/// Maximum Argon2 parallelism.
pub const MAX_ARGON2_PARALLELISM: u32 = 255;
