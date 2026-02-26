use chacha20poly1305::aead::{Aead, KeyInit, Payload};
use chacha20poly1305::{XChaCha20Poly1305, XNonce};

use crate::config::{KEY_LEN, NONCE_LEN};
use crate::error::{CryptError, Result};

/// Encrypt a plaintext chunk using XChaCha20-Poly1305 with AAD.
///
/// AAD (Associated Authenticated Data) binds the ciphertext to
/// contextual metadata (uuid, version, chunk index, etc.) so that
/// chunks cannot be reordered, swapped between files, or
/// transplanted from one context to another without detection.
///
/// Returns ciphertext with appended 16-byte Poly1305 tag.
pub fn encrypt_chunk(
    key: &[u8; KEY_LEN],
    nonce: &[u8; NONCE_LEN],
    plaintext: &[u8],
    aad: &[u8],
) -> Result<Vec<u8>> {
    let cipher = XChaCha20Poly1305::new_from_slice(key)
        .map_err(|e| CryptError::Encryption(format!("Cipher init: {e}")))?;

    let xnonce = XNonce::from_slice(nonce);

    cipher
        .encrypt(xnonce, Payload { msg: plaintext, aad })
        .map_err(|e| CryptError::Encryption(format!("Encrypt: {e}")))
}

/// Decrypt a ciphertext chunk using XChaCha20-Poly1305 with AAD.
///
/// The same AAD that was provided during encryption must be
/// supplied here, otherwise decryption will fail (tag mismatch).
///
/// Input must include the 16-byte Poly1305 tag.
pub fn decrypt_chunk(
    key: &[u8; KEY_LEN],
    nonce: &[u8; NONCE_LEN],
    ciphertext: &[u8],
    aad: &[u8],
) -> Result<Vec<u8>> {
    let cipher = XChaCha20Poly1305::new_from_slice(key)
        .map_err(|e| CryptError::Decryption(format!("Cipher init: {e}")))?;

    let xnonce = XNonce::from_slice(nonce);

    cipher
        .decrypt(xnonce, Payload { msg: ciphertext, aad })
        .map_err(|_| CryptError::InvalidPassword)
}

/// Encrypt metadata bytes using the header key, nonce, and AAD.
///
/// AAD should be the serialized public header, binding the
/// encrypted metadata to its header context.
pub fn encrypt_metadata(
    header_key: &[u8; KEY_LEN],
    header_nonce: &[u8; NONCE_LEN],
    plaintext: &[u8],
    aad: &[u8],
) -> Result<Vec<u8>> {
    encrypt_chunk(header_key, header_nonce, plaintext, aad)
}

/// Decrypt metadata bytes using the header key, nonce, and AAD.
pub fn decrypt_metadata(
    header_key: &[u8; KEY_LEN],
    header_nonce: &[u8; NONCE_LEN],
    ciphertext: &[u8],
    aad: &[u8],
) -> Result<Vec<u8>> {
    decrypt_chunk(header_key, header_nonce, ciphertext, aad)
}

/// Build AAD for a data chunk: uuid || version || chunk_index.
pub fn build_chunk_aad(
    uuid: &str,
    version: u16,
    chunk_index: u64,
) -> Vec<u8> {
    let mut aad = Vec::with_capacity(uuid.len() + 2 + 8);
    aad.extend_from_slice(uuid.as_bytes());
    aad.extend_from_slice(&version.to_le_bytes());
    aad.extend_from_slice(&chunk_index.to_le_bytes());
    aad
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::crypto::nonce;

    #[test]
    fn test_encrypt_decrypt_round_trip() {
        let key = [0xABu8; KEY_LEN];
        let nonce_val = nonce::generate_header_nonce();
        let plaintext = b"Hello, HOPLIXI encryption!";
        let aad = b"test-aad-context";

        let ct = encrypt_chunk(&key, &nonce_val, plaintext, aad).unwrap();
        assert_ne!(&ct[..], plaintext);
        assert_eq!(ct.len(), plaintext.len() + 16);

        let pt = decrypt_chunk(&key, &nonce_val, &ct, aad).unwrap();
        assert_eq!(&pt[..], plaintext);
    }

    #[test]
    fn test_wrong_key_fails() {
        let key = [0xABu8; KEY_LEN];
        let wrong_key = [0xCDu8; KEY_LEN];
        let nonce_val = nonce::generate_header_nonce();
        let plaintext = b"secret data";
        let aad = b"context";

        let ct = encrypt_chunk(&key, &nonce_val, plaintext, aad).unwrap();
        let result = decrypt_chunk(&wrong_key, &nonce_val, &ct, aad);
        assert!(result.is_err());
    }

    #[test]
    fn test_wrong_nonce_fails() {
        let key = [0xABu8; KEY_LEN];
        let n1 = nonce::generate_header_nonce();
        let n2 = nonce::generate_header_nonce();
        let plaintext = b"secret data";
        let aad = b"context";

        let ct = encrypt_chunk(&key, &n1, plaintext, aad).unwrap();
        let result = decrypt_chunk(&key, &n2, &ct, aad);
        assert!(result.is_err());
    }

    #[test]
    fn test_wrong_aad_fails() {
        let key = [0xABu8; KEY_LEN];
        let nonce_val = nonce::generate_header_nonce();
        let plaintext = b"secret data";

        let ct =
            encrypt_chunk(&key, &nonce_val, plaintext, b"correct-aad")
                .unwrap();
        let result =
            decrypt_chunk(&key, &nonce_val, &ct, b"wrong-aad");
        assert!(result.is_err());
    }

    #[test]
    fn test_corrupted_ciphertext_fails() {
        let key = [0xABu8; KEY_LEN];
        let nonce_val = nonce::generate_header_nonce();
        let plaintext = b"important data";
        let aad = b"ctx";

        let mut ct =
            encrypt_chunk(&key, &nonce_val, plaintext, aad).unwrap();
        ct[0] ^= 0xFF; // flip a bit

        let result = decrypt_chunk(&key, &nonce_val, &ct, aad);
        assert!(result.is_err());
    }

    #[test]
    fn test_metadata_round_trip() {
        let key = [0x42u8; KEY_LEN];
        let nonce_val = nonce::generate_header_nonce();
        let meta = b"filename.txt";
        let aad = b"header-bytes";

        let encrypted =
            encrypt_metadata(&key, &nonce_val, meta, aad).unwrap();
        let decrypted =
            decrypt_metadata(&key, &nonce_val, &encrypted, aad).unwrap();
        assert_eq!(&decrypted[..], meta);
    }

    #[test]
    fn test_empty_plaintext() {
        let key = [0x01u8; KEY_LEN];
        let nonce_val = nonce::generate_header_nonce();
        let aad = b"";

        let ct = encrypt_chunk(&key, &nonce_val, b"", aad).unwrap();
        assert_eq!(ct.len(), 16); // only tag

        let pt = decrypt_chunk(&key, &nonce_val, &ct, aad).unwrap();
        assert!(pt.is_empty());
    }

    #[test]
    fn test_build_chunk_aad() {
        let aad = build_chunk_aad("test-uuid", 1, 42);
        assert_eq!(aad.len(), 9 + 2 + 8); // "test-uuid" + u16 + u64
        assert_eq!(&aad[..9], b"test-uuid");
        assert_eq!(&aad[9..11], &1u16.to_le_bytes());
        assert_eq!(&aad[11..19], &42u64.to_le_bytes());
    }
}
