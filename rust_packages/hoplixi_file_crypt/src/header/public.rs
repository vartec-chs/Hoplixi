use std::io::{Read, Write};

use crate::config::{
    MAGIC, MAX_ARGON2_M_COST_KIB, MAX_ARGON2_PARALLELISM,
    MAX_ARGON2_T_COST, MAX_CHUNK_SIZE, MAX_ENCRYPTED_META_LEN,
    MIN_CHUNK_SIZE, NONCE_LEN, SALT_LEN, VERSION,
};
use crate::crypto::kdf::Argon2Params;
use crate::error::{CryptError, Result};

/// Public (unencrypted) portion of the file header.
///
/// Written at the start of every encrypted file. Contains all
/// parameters needed to derive keys and locate encrypted metadata.
#[derive(Debug, Clone)]
pub struct PublicHeader {
    pub version: u16,
    pub salt: [u8; SALT_LEN],
    pub argon2_params: Argon2Params,
    pub chunk_size: u32,
    pub data_base_nonce: [u8; NONCE_LEN],
    pub header_nonce: [u8; NONCE_LEN],
    pub encrypted_meta_len: u32,
}

impl PublicHeader {
    /// Serialize the public header into a writer.
    pub fn write_to<W: Write>(&self, w: &mut W) -> Result<()> {
        w.write_all(MAGIC)?;
        w.write_all(&self.version.to_le_bytes())?;
        w.write_all(&self.salt)?;
        w.write_all(&self.argon2_params.t_cost.to_le_bytes())?;
        w.write_all(&self.argon2_params.m_cost_kib.to_le_bytes())?;
        w.write_all(&self.argon2_params.parallelism.to_le_bytes())?;
        w.write_all(&self.chunk_size.to_le_bytes())?;
        w.write_all(&self.data_base_nonce)?;
        w.write_all(&self.header_nonce)?;
        w.write_all(&self.encrypted_meta_len.to_le_bytes())?;
        Ok(())
    }

    /// Serialize the public header to a byte vector (for AAD).
    pub fn to_bytes(&self) -> Vec<u8> {
        let mut buf = Vec::with_capacity(128);
        // write_to always succeeds on a Vec
        self.write_to(&mut buf).expect("Vec write failed");
        buf
    }

    /// Deserialize a public header from a reader.
    ///
    /// Validates all fields against safety limits to prevent
    /// DoS via malicious header values (OOM, CPU exhaustion).
    pub fn read_from<R: Read>(r: &mut R) -> Result<Self> {
        // Read and verify magic bytes.
        let mut magic = [0u8; MAGIC.len()];
        r.read_exact(&mut magic)?;
        if &magic != MAGIC {
            return Err(CryptError::InvalidMagic);
        }

        // Version.
        let mut buf2 = [0u8; 2];
        r.read_exact(&mut buf2)?;
        let version = u16::from_le_bytes(buf2);
        if version != VERSION {
            return Err(CryptError::UnsupportedVersion(version));
        }

        // Salt.
        let mut salt = [0u8; SALT_LEN];
        r.read_exact(&mut salt)?;

        // Argon2 params.
        let mut buf4 = [0u8; 4];

        r.read_exact(&mut buf4)?;
        let t_cost = u32::from_le_bytes(buf4);

        r.read_exact(&mut buf4)?;
        let m_cost_kib = u32::from_le_bytes(buf4);

        r.read_exact(&mut buf4)?;
        let parallelism = u32::from_le_bytes(buf4);

        // Chunk size.
        r.read_exact(&mut buf4)?;
        let chunk_size = u32::from_le_bytes(buf4);

        // Nonces.
        let mut data_base_nonce = [0u8; NONCE_LEN];
        r.read_exact(&mut data_base_nonce)?;

        let mut header_nonce = [0u8; NONCE_LEN];
        r.read_exact(&mut header_nonce)?;

        // Encrypted metadata length.
        r.read_exact(&mut buf4)?;
        let encrypted_meta_len = u32::from_le_bytes(buf4);

        // ── Validate limits (anti-DoS) ──────────────────────
        if !(MIN_CHUNK_SIZE..=MAX_CHUNK_SIZE).contains(&chunk_size) {
            return Err(CryptError::InvalidHeader(format!(
                "chunk_size {chunk_size} out of range \
                 [{MIN_CHUNK_SIZE}..{MAX_CHUNK_SIZE}]"
            )));
        }

        if encrypted_meta_len > MAX_ENCRYPTED_META_LEN {
            return Err(CryptError::InvalidHeader(format!(
                "encrypted_meta_len {encrypted_meta_len} exceeds \
                 max {MAX_ENCRYPTED_META_LEN}"
            )));
        }

        if t_cost == 0 || t_cost > MAX_ARGON2_T_COST {
            return Err(CryptError::InvalidHeader(format!(
                "argon2 t_cost {t_cost} out of range \
                 [1..{MAX_ARGON2_T_COST}]"
            )));
        }

        if m_cost_kib == 0 || m_cost_kib > MAX_ARGON2_M_COST_KIB {
            return Err(CryptError::InvalidHeader(format!(
                "argon2 m_cost_kib {m_cost_kib} out of range \
                 [1..{MAX_ARGON2_M_COST_KIB}]"
            )));
        }

        if parallelism == 0 || parallelism > MAX_ARGON2_PARALLELISM {
            return Err(CryptError::InvalidHeader(format!(
                "argon2 parallelism {parallelism} out of range \
                 [1..{MAX_ARGON2_PARALLELISM}]"
            )));
        }

        Ok(Self {
            version,
            salt,
            argon2_params: Argon2Params {
                t_cost,
                m_cost_kib,
                parallelism,
            },
            chunk_size,
            data_base_nonce,
            header_nonce,
            encrypted_meta_len,
        })
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::io::Cursor;

    fn sample_header() -> PublicHeader {
        PublicHeader {
            version: VERSION,
            salt: [0xAA; SALT_LEN],
            argon2_params: Argon2Params {
                t_cost: 3,
                m_cost_kib: 32768,
                parallelism: 4,
            },
            chunk_size: 1024 * 1024,
            data_base_nonce: [0xBB; NONCE_LEN],
            header_nonce: [0xCC; NONCE_LEN],
            encrypted_meta_len: 256,
        }
    }

    #[test]
    fn test_write_read_round_trip() {
        let original = sample_header();
        let mut buf = Vec::new();
        original.write_to(&mut buf).unwrap();

        let mut cursor = Cursor::new(&buf);
        let parsed = PublicHeader::read_from(&mut cursor).unwrap();

        assert_eq!(parsed.version, original.version);
        assert_eq!(parsed.salt, original.salt);
        assert_eq!(parsed.argon2_params.t_cost, original.argon2_params.t_cost);
        assert_eq!(
            parsed.argon2_params.m_cost_kib,
            original.argon2_params.m_cost_kib
        );
        assert_eq!(
            parsed.argon2_params.parallelism,
            original.argon2_params.parallelism
        );
        assert_eq!(parsed.chunk_size, original.chunk_size);
        assert_eq!(parsed.data_base_nonce, original.data_base_nonce);
        assert_eq!(parsed.header_nonce, original.header_nonce);
        assert_eq!(
            parsed.encrypted_meta_len,
            original.encrypted_meta_len
        );
    }

    #[test]
    fn test_invalid_magic() {
        let mut buf = Vec::new();
        buf.extend_from_slice(b"BADMGIC");
        buf.extend_from_slice(&[0u8; 200]);

        let mut cursor = Cursor::new(&buf);
        let result = PublicHeader::read_from(&mut cursor);
        assert!(matches!(result, Err(CryptError::InvalidMagic)));
    }

    #[test]
    fn test_unsupported_version() {
        let mut buf = Vec::new();
        buf.extend_from_slice(MAGIC);
        buf.extend_from_slice(&99u16.to_le_bytes());
        buf.extend_from_slice(&[0u8; 200]);

        let mut cursor = Cursor::new(&buf);
        let result = PublicHeader::read_from(&mut cursor);
        assert!(matches!(
            result,
            Err(CryptError::UnsupportedVersion(99))
        ));
    }

    #[test]
    fn test_invalid_chunk_size_too_small() {
        let mut h = sample_header();
        h.chunk_size = 10; // below MIN_CHUNK_SIZE
        let mut buf = Vec::new();
        h.write_to(&mut buf).unwrap();

        let mut cursor = Cursor::new(&buf);
        let result = PublicHeader::read_from(&mut cursor);
        assert!(matches!(result, Err(CryptError::InvalidHeader(_))));
    }

    #[test]
    fn test_invalid_chunk_size_too_large() {
        let mut h = sample_header();
        h.chunk_size = 128 * 1024 * 1024; // above MAX_CHUNK_SIZE
        let mut buf = Vec::new();
        h.write_to(&mut buf).unwrap();

        let mut cursor = Cursor::new(&buf);
        let result = PublicHeader::read_from(&mut cursor);
        assert!(matches!(result, Err(CryptError::InvalidHeader(_))));
    }

    #[test]
    fn test_invalid_meta_len_too_large() {
        let mut h = sample_header();
        h.encrypted_meta_len = 2 * 1024 * 1024; // above MAX
        let mut buf = Vec::new();
        h.write_to(&mut buf).unwrap();

        let mut cursor = Cursor::new(&buf);
        let result = PublicHeader::read_from(&mut cursor);
        assert!(matches!(result, Err(CryptError::InvalidHeader(_))));
    }

    #[test]
    fn test_invalid_argon2_t_cost_zero() {
        let mut h = sample_header();
        h.argon2_params.t_cost = 0;
        let mut buf = Vec::new();
        h.write_to(&mut buf).unwrap();

        let mut cursor = Cursor::new(&buf);
        let result = PublicHeader::read_from(&mut cursor);
        assert!(matches!(result, Err(CryptError::InvalidHeader(_))));
    }

    #[test]
    fn test_invalid_argon2_m_cost_overflow() {
        let mut h = sample_header();
        h.argon2_params.m_cost_kib = u32::MAX;
        let mut buf = Vec::new();
        h.write_to(&mut buf).unwrap();

        let mut cursor = Cursor::new(&buf);
        let result = PublicHeader::read_from(&mut cursor);
        assert!(matches!(result, Err(CryptError::InvalidHeader(_))));
    }

    #[test]
    fn test_to_bytes_matches_write_to() {
        let h = sample_header();
        let bytes = h.to_bytes();

        let mut buf = Vec::new();
        h.write_to(&mut buf).unwrap();
        assert_eq!(bytes, buf);
    }
}
