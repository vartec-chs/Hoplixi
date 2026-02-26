use std::collections::HashMap;

use serde::{Deserialize, Serialize};

use crate::config::{KEY_LEN, NONCE_LEN};
use crate::crypto::cipher;
use crate::error::{CryptError, Result};

/// Encrypted metadata stored in the file header.
///
/// Contains sensitive information about the original file
/// that should not be visible without the correct password.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct EncryptedMetadata {
    /// Original filename (without extension).
    pub original_filename: String,
    /// Original file extension (e.g. "txt", "pdf").
    pub original_extension: String,
    /// Whether the data was gzip-compressed before encryption.
    pub gzip_compressed: bool,
    /// Original file size in bytes (before any compression).
    pub original_size: u64,
    /// Unique identifier for this encrypted file.
    pub uuid: String,
    /// Additional user-defined metadata.
    pub metadata: HashMap<String, String>,
}

impl EncryptedMetadata {
    /// Serialize to bincode, then encrypt with the header key.
    ///
    /// `header_aad` should be the serialized public header bytes,
    /// binding the metadata to its header context.
    pub fn seal(
        &self,
        header_key: &[u8; KEY_LEN],
        header_nonce: &[u8; NONCE_LEN],
        header_aad: &[u8],
    ) -> Result<Vec<u8>> {
        let encoded = bincode::serde::encode_to_vec(
            self,
            bincode::config::standard(),
        )
        .map_err(|e| {
            CryptError::Serialization(format!("Bincode encode: {e}"))
        })?;

        cipher::encrypt_metadata(
            header_key,
            header_nonce,
            &encoded,
            header_aad,
        )
    }

    /// Decrypt and deserialize from bincode.
    ///
    /// `header_aad` must match the AAD used during `seal`.
    pub fn unseal(
        encrypted: &[u8],
        header_key: &[u8; KEY_LEN],
        header_nonce: &[u8; NONCE_LEN],
        header_aad: &[u8],
    ) -> Result<Self> {
        let decrypted = cipher::decrypt_metadata(
            header_key,
            header_nonce,
            encrypted,
            header_aad,
        )?;

        let (meta, _) = bincode::serde::decode_from_slice::<Self, _>(
            &decrypted,
            bincode::config::standard(),
        )
        .map_err(|e| {
            CryptError::Serialization(format!("Bincode decode: {e}"))
        })?;

        Ok(meta)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn sample_metadata() -> EncryptedMetadata {
        let mut metadata = HashMap::new();
        metadata
            .insert("author".to_string(), "test-user".to_string());

        EncryptedMetadata {
            original_filename: "document".to_string(),
            original_extension: "pdf".to_string(),
            gzip_compressed: true,
            original_size: 1_048_576,
            uuid: "550e8400-e29b-41d4-a716-446655440000".to_string(),
            metadata,
        }
    }

    #[test]
    fn test_seal_unseal_round_trip() {
        let meta = sample_metadata();
        let key = [0x42u8; KEY_LEN];
        let nonce = [0x13u8; NONCE_LEN];
        let aad = b"public-header-bytes";

        let sealed = meta.seal(&key, &nonce, aad).unwrap();
        let unsealed =
            EncryptedMetadata::unseal(&sealed, &key, &nonce, aad)
                .unwrap();

        assert_eq!(unsealed.original_filename, meta.original_filename);
        assert_eq!(
            unsealed.original_extension,
            meta.original_extension
        );
        assert_eq!(unsealed.gzip_compressed, meta.gzip_compressed);
        assert_eq!(unsealed.original_size, meta.original_size);
        assert_eq!(unsealed.uuid, meta.uuid);
        assert_eq!(unsealed.metadata, meta.metadata);
    }

    #[test]
    fn test_wrong_key_fails() {
        let meta = sample_metadata();
        let key = [0x42u8; KEY_LEN];
        let wrong_key = [0x99u8; KEY_LEN];
        let nonce = [0x13u8; NONCE_LEN];
        let aad = b"header";

        let sealed = meta.seal(&key, &nonce, aad).unwrap();
        let result =
            EncryptedMetadata::unseal(&sealed, &wrong_key, &nonce, aad);
        assert!(result.is_err());
    }

    #[test]
    fn test_wrong_aad_fails() {
        let meta = sample_metadata();
        let key = [0x42u8; KEY_LEN];
        let nonce = [0x13u8; NONCE_LEN];

        let sealed = meta.seal(&key, &nonce, b"correct-header").unwrap();
        let result = EncryptedMetadata::unseal(
            &sealed,
            &key,
            &nonce,
            b"tampered-header",
        );
        assert!(result.is_err());
    }

    #[test]
    fn test_empty_metadata() {
        let meta = EncryptedMetadata {
            original_filename: String::new(),
            original_extension: String::new(),
            gzip_compressed: false,
            original_size: 0,
            uuid: String::new(),
            metadata: HashMap::new(),
        };

        let key = [0x01u8; KEY_LEN];
        let nonce = [0x02u8; NONCE_LEN];
        let aad = b"";

        let sealed = meta.seal(&key, &nonce, aad).unwrap();
        let unsealed =
            EncryptedMetadata::unseal(&sealed, &key, &nonce, aad)
                .unwrap();
        assert_eq!(unsealed.original_filename, "");
        assert_eq!(unsealed.original_size, 0);
    }
}
