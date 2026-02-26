use crate::config::{NONCE_LEN, NONCE_RANDOM_LEN};

/// Generate a random nonce for header encryption (24 bytes, fully random).
pub fn generate_header_nonce() -> [u8; NONCE_LEN] {
    let mut nonce = [0u8; NONCE_LEN];
    rand::fill(&mut nonce);
    nonce
}

/// Generate a data base nonce (24 bytes: 16 random + 8 zero counter).
///
/// For each chunk, the nonce is constructed as:
/// `base_nonce[0..16] || chunk_index.to_le_bytes()`
pub fn generate_data_base_nonce() -> [u8; NONCE_LEN] {
    let mut nonce = [0u8; NONCE_LEN];
    rand::fill(&mut nonce[..NONCE_RANDOM_LEN]);
    // Last 8 bytes are zero (counter starts at 0).
    nonce
}

/// Compute the nonce for a specific chunk index.
///
/// The nonce is `base_nonce[0..16] || chunk_index as u64 LE`.
pub fn chunk_nonce(base_nonce: &[u8; NONCE_LEN], chunk_index: u64) -> [u8; NONCE_LEN] {
    let mut nonce = [0u8; NONCE_LEN];
    nonce[..NONCE_RANDOM_LEN].copy_from_slice(&base_nonce[..NONCE_RANDOM_LEN]);
    nonce[NONCE_RANDOM_LEN..].copy_from_slice(&chunk_index.to_le_bytes());
    nonce
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_header_nonce_unique() {
        let n1 = generate_header_nonce();
        let n2 = generate_header_nonce();
        assert_ne!(n1, n2);
    }

    #[test]
    fn test_data_base_nonce_has_zero_counter() {
        let nonce = generate_data_base_nonce();
        assert_eq!(
            &nonce[NONCE_RANDOM_LEN..],
            &[0u8; 8]
        );
    }

    #[test]
    fn test_chunk_nonce_increments() {
        let base = generate_data_base_nonce();
        let n0 = chunk_nonce(&base, 0);
        let n1 = chunk_nonce(&base, 1);
        let n2 = chunk_nonce(&base, 2);

        // Random prefix is shared.
        assert_eq!(&n0[..NONCE_RANDOM_LEN], &n1[..NONCE_RANDOM_LEN]);

        // Counter differs.
        assert_ne!(n0, n1);
        assert_ne!(n1, n2);

        // Counter bytes match expected values.
        assert_eq!(&n0[NONCE_RANDOM_LEN..], &0u64.to_le_bytes());
        assert_eq!(&n1[NONCE_RANDOM_LEN..], &1u64.to_le_bytes());
        assert_eq!(&n2[NONCE_RANDOM_LEN..], &2u64.to_le_bytes());
    }

    #[test]
    fn test_chunk_nonce_max_index() {
        let base = generate_data_base_nonce();
        let n = chunk_nonce(&base, u64::MAX);
        assert_eq!(
            &n[NONCE_RANDOM_LEN..],
            &u64::MAX.to_le_bytes()
        );
    }
}
