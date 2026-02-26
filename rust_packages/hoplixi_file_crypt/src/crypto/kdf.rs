use argon2::{Algorithm, Argon2, Params, Version};
use hkdf::Hkdf;
use sha2::Sha256;
use zeroize::Zeroize;

use crate::config::{HKDF_INFO_DATA, HKDF_INFO_HEADER, KEY_LEN, SALT_LEN};
use crate::error::{CryptError, Result};

/// Argon2id parameters for key derivation.
#[derive(Debug, Clone, Copy)]
pub struct Argon2Params {
    pub t_cost: u32,
    pub m_cost_kib: u32,
    pub parallelism: u32,
}

impl Default for Argon2Params {
    fn default() -> Self {
        use crate::config::argon2_defaults;
        Self {
            t_cost: argon2_defaults::T_COST,
            m_cost_kib: argon2_defaults::M_COST_KIB,
            parallelism: argon2_defaults::PARALLELISM,
        }
    }
}

/// Container for derived keys with automatic zeroization on drop.
pub struct DerivedKeys {
    pub header_key: [u8; KEY_LEN],
    pub data_key: [u8; KEY_LEN],
}

impl Drop for DerivedKeys {
    fn drop(&mut self) {
        self.header_key.zeroize();
        self.data_key.zeroize();
    }
}

/// Derive the master key from a password and salt using Argon2id.
fn derive_master_key(
    password: &[u8],
    salt: &[u8; SALT_LEN],
    params: &Argon2Params,
) -> Result<[u8; KEY_LEN]> {
    let argon2_params = Params::new(
        params.m_cost_kib,
        params.t_cost,
        params.parallelism,
        Some(KEY_LEN),
    )
    .map_err(|e| CryptError::KeyDerivation(format!("Argon2 params: {e}")))?;

    let argon2 = Argon2::new(Algorithm::Argon2id, Version::V0x13, argon2_params);

    let mut master_key = [0u8; KEY_LEN];
    argon2
        .hash_password_into(password, salt, &mut master_key)
        .map_err(|e| CryptError::KeyDerivation(format!("Argon2 hash: {e}")))?;

    Ok(master_key)
}

/// Derive a sub-key from the master key using HKDF-SHA256.
fn hkdf_derive(master_key: &[u8; KEY_LEN], info: &[u8]) -> Result<[u8; KEY_LEN]> {
    let hk =
        Hkdf::<Sha256>::new(None, master_key);
    let mut output = [0u8; KEY_LEN];
    hk.expand(info, &mut output)
        .map_err(|e| CryptError::KeyDerivation(format!("HKDF expand: {e}")))?;
    Ok(output)
}

/// Derive both header and data keys from a password and salt.
///
/// 1. `Argon2id(password, salt)` → `master_key`
/// 2. `HKDF(master_key, "hoplixi-header-key-v1")` → `header_key`
/// 3. `HKDF(master_key, "hoplixi-data-key-v1")` → `data_key`
pub fn derive_keys(
    password: &str,
    salt: &[u8; SALT_LEN],
    params: &Argon2Params,
) -> Result<DerivedKeys> {
    let mut master_key = derive_master_key(password.as_bytes(), salt, params)?;

    let header_key = hkdf_derive(&master_key, HKDF_INFO_HEADER)?;
    let data_key = hkdf_derive(&master_key, HKDF_INFO_DATA)?;

    master_key.zeroize();

    Ok(DerivedKeys {
        header_key,
        data_key,
    })
}

/// Generate a cryptographically secure random salt.
pub fn generate_salt() -> [u8; SALT_LEN] {
    let mut salt = [0u8; SALT_LEN];
    rand::fill(&mut salt);
    salt
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_derive_keys_deterministic() {
        let salt = [42u8; SALT_LEN];
        let params = Argon2Params {
            t_cost: 1,
            m_cost_kib: 64,
            parallelism: 1,
        };

        let keys1 = derive_keys("test-password", &salt, &params).unwrap();
        let keys2 = derive_keys("test-password", &salt, &params).unwrap();

        assert_eq!(keys1.header_key, keys2.header_key);
        assert_eq!(keys1.data_key, keys2.data_key);
    }

    #[test]
    fn test_header_key_differs_from_data_key() {
        let salt = [1u8; SALT_LEN];
        let params = Argon2Params {
            t_cost: 1,
            m_cost_kib: 64,
            parallelism: 1,
        };

        let keys = derive_keys("password", &salt, &params).unwrap();
        assert_ne!(keys.header_key, keys.data_key);
    }

    #[test]
    fn test_different_passwords_different_keys() {
        let salt = [7u8; SALT_LEN];
        let params = Argon2Params {
            t_cost: 1,
            m_cost_kib: 64,
            parallelism: 1,
        };

        let keys_a = derive_keys("password-a", &salt, &params).unwrap();
        let keys_b = derive_keys("password-b", &salt, &params).unwrap();

        assert_ne!(keys_a.header_key, keys_b.header_key);
        assert_ne!(keys_a.data_key, keys_b.data_key);
    }

    #[test]
    fn test_different_salts_different_keys() {
        let params = Argon2Params {
            t_cost: 1,
            m_cost_kib: 64,
            parallelism: 1,
        };

        let keys_a = derive_keys("same-pw", &[1u8; SALT_LEN], &params).unwrap();
        let keys_b = derive_keys("same-pw", &[2u8; SALT_LEN], &params).unwrap();

        assert_ne!(keys_a.header_key, keys_b.header_key);
        assert_ne!(keys_a.data_key, keys_b.data_key);
    }

    #[test]
    fn test_generate_salt_unique() {
        let s1 = generate_salt();
        let s2 = generate_salt();
        assert_ne!(s1, s2);
    }
}
