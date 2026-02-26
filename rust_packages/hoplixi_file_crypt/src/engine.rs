use std::fs::{self, File};
use std::io::{BufReader, BufWriter, Read, Write};

use tempfile::NamedTempFile;
use uuid::Uuid;

use crate::compress;
use crate::config::{
    DEFAULT_DESKTOP_CHUNK_SIZE, DEFAULT_EXTENSION, TAG_LEN, VERSION,
};
use crate::crypto::{cipher, kdf, nonce};
use crate::error::{CryptError, Result};
use crate::header::encrypted::EncryptedMetadata;
use crate::header::public::PublicHeader;
use crate::progress::{
    ProgressCallback, ProgressEvent, ProgressStage,
};
pub use crate::types::{
    DecryptOptions, DecryptResult, EncryptOptions,
    EncryptResult,
};

use crate::cleanup::TempCleanup;

// ── FileCrypt engine ─────────────────────────────────────

/// Main encryption/decryption engine.
///
/// Configurable chunk size and Argon2 parameters.
pub struct FileCrypt {
    chunk_size: u32,
    argon2_params: kdf::Argon2Params,
}

impl Default for FileCrypt {
    fn default() -> Self {
        Self {
            chunk_size: DEFAULT_DESKTOP_CHUNK_SIZE,
            argon2_params: kdf::Argon2Params::default(),
        }
    }
}

impl FileCrypt {
    /// Create with custom chunk size.
    pub fn with_chunk_size(chunk_size: u32) -> Self {
        Self {
            chunk_size,
            ..Default::default()
        }
    }

    /// Create with custom Argon2 parameters.
    pub fn with_argon2_params(
        params: kdf::Argon2Params,
    ) -> Self {
        Self {
            argon2_params: params,
            ..Default::default()
        }
    }

    /// Create with custom chunk size and Argon2 parameters.
    pub fn new(
        chunk_size: u32,
        argon2_params: kdf::Argon2Params,
    ) -> Self {
        Self {
            chunk_size,
            argon2_params,
        }
    }

    /// Encrypt a file or directory.
    ///
    /// If the input is a directory, it is first compressed to 7z.
    /// Returns the path to the encrypted output and its UUID.
    ///
    /// All temporary files are cleaned up on both success and
    /// error (via RAII guard).
    pub async fn encrypt(
        &self,
        opts: EncryptOptions,
    ) -> Result<EncryptResult> {
        let input_path = opts.input_path.clone();
        let is_dir = input_path.is_dir();

        let temp_parent = opts
            .temp_dir
            .clone()
            .unwrap_or_else(|| opts.output_dir.clone());

        // RAII guard: cleans up all tracked temp files on any
        // exit path (success or error / early return via `?`).
        let mut cleanup = TempCleanup::new();

        // Step 1: If directory, compress to 7z first.
        let (file_to_encrypt, original_filename, original_extension) =
            if is_dir {
                let dir_name = input_path
                    .file_name()
                    .and_then(|n| n.to_str())
                    .unwrap_or("archive")
                    .to_string();

                let temp_archive =
                    NamedTempFile::new_in(&temp_parent)?;
                let temp_archive_path =
                    temp_archive.path().to_path_buf();

                self.emit_progress(
                    &opts.progress,
                    ProgressStage::CompressingDirectory,
                    0,
                    0,
                );

                let src_dir = input_path.clone();
                let archive_dst = temp_archive_path.clone();
                tokio::task::spawn_blocking(move || {
                    compress::sevenz::compress_directory(
                        &src_dir,
                        &archive_dst,
                    )
                })
                .await
                .map_err(|e| {
                    CryptError::Compression(format!("Join: {e}"))
                })?
                .map_err(|e| {
                    CryptError::Compression(format!("{e}"))
                })?;

                let kept = temp_archive
                    .into_temp_path()
                    .keep()
                    .map_err(|e| CryptError::Io(e.error))?;
                cleanup.track(kept.clone());
                (kept, dir_name, "7z".to_string())
            } else {
                let filename = input_path
                    .file_stem()
                    .and_then(|s| s.to_str())
                    .unwrap_or("file")
                    .to_string();
                let extension = input_path
                    .extension()
                    .and_then(|s| s.to_str())
                    .unwrap_or("")
                    .to_string();
                (input_path.clone(), filename, extension)
            };

        // Step 2: Optional gzip compression.
        let (source_to_encrypt, gzip_applied) =
            if opts.gzip_compressed {
                let temp_gz =
                    NamedTempFile::new_in(&temp_parent)?;
                let temp_gz_path =
                    temp_gz.path().to_path_buf();

                self.emit_progress(
                    &opts.progress,
                    ProgressStage::CompressingGzip,
                    0,
                    0,
                );

                let src = file_to_encrypt.clone();
                let dst = temp_gz_path.clone();
                tokio::task::spawn_blocking(move || {
                    compress::gzip::gzip_compress(&src, &dst)
                })
                .await
                .map_err(|e| {
                    CryptError::Compression(format!("Join: {e}"))
                })?
                .map_err(|e| {
                    CryptError::Compression(format!("{e}"))
                })?;

                // 7z temp is no longer needed.
                if is_dir {
                    cleanup.remove_now(&file_to_encrypt);
                }

                let kept_gz = temp_gz
                    .into_temp_path()
                    .keep()
                    .map_err(|e| CryptError::Io(e.error))?;
                cleanup.track(kept_gz.clone());
                (kept_gz, true)
            } else {
                (file_to_encrypt.clone(), false)
            };

        // Get original size of the file being encrypted.
        let original_size =
            fs::metadata(&source_to_encrypt)?.len();

        // Step 3: Generate cryptographic parameters.
        let salt = kdf::generate_salt();
        let header_nonce = nonce::generate_header_nonce();
        let data_base_nonce = nonce::generate_data_base_nonce();
        let file_uuid = opts
            .uuid
            .unwrap_or_else(|| Uuid::new_v4().to_string());

        let password = opts.password.clone();
        let salt_copy = salt;
        let params = self.argon2_params;
        let keys = tokio::task::spawn_blocking(move || {
            kdf::derive_keys(&password, &salt_copy, &params)
        })
        .await
        .map_err(|e| {
            CryptError::KeyDerivation(format!("Join: {e}"))
        })??;

        // Step 4: Build metadata and public header.
        let enc_meta = EncryptedMetadata {
            original_filename: original_filename.clone(),
            original_extension: original_extension.clone(),
            gzip_compressed: gzip_applied,
            original_size,
            uuid: file_uuid.clone(),
            metadata: opts.metadata.unwrap_or_default(),
        };

        let chunk_size = self.chunk_size;
        let mut public_header = PublicHeader {
            version: VERSION,
            salt,
            argon2_params: self.argon2_params,
            chunk_size,
            data_base_nonce,
            header_nonce,
            encrypted_meta_len: 0, // placeholder
        };

        let header_aad = public_header.to_bytes();
        let sealed_meta = enc_meta.seal(
            &keys.header_key,
            &header_nonce,
            &header_aad,
        )?;
        public_header.encrypted_meta_len =
            sealed_meta.len() as u32;

        // Step 5: Write the encrypted file.
        let ext = opts
            .output_extension
            .as_deref()
            .unwrap_or(DEFAULT_EXTENSION);
        let output_path =
            opts.output_dir.join(format!("{file_uuid}{ext}"));

        // Write to temp file, then atomic rename.
        // NamedTempFile auto-deletes on drop if persist/keep is
        // not called — acts as its own cleanup for the output.
        let temp_output =
            NamedTempFile::new_in(&opts.output_dir)?;
        let progress_cb = opts.progress.clone();

        {
            let mut writer =
                BufWriter::new(temp_output.as_file());
            public_header.write_to(&mut writer)?;
            writer.write_all(&sealed_meta)?;

            // Step 6: Encrypt data in chunks with AAD.
            let file_in = File::open(&source_to_encrypt)?;
            let file_size = file_in.metadata()?.len();
            let mut reader = BufReader::new(file_in);

            let mut buf = vec![0u8; chunk_size as usize];
            let mut chunk_index: u64 = 0;
            let mut bytes_processed: u64 = 0;

            loop {
                let n = read_full(&mut reader, &mut buf)?;
                if n == 0 {
                    break;
                }

                let cn = nonce::chunk_nonce(
                    &data_base_nonce,
                    chunk_index,
                );
                let chunk_aad = cipher::build_chunk_aad(
                    &file_uuid, VERSION, chunk_index,
                );
                let encrypted = cipher::encrypt_chunk(
                    &keys.data_key,
                    &cn,
                    &buf[..n],
                    &chunk_aad,
                )?;
                writer.write_all(&encrypted)?;

                chunk_index += 1;
                bytes_processed += n as u64;

                self.emit_progress(
                    &progress_cb,
                    ProgressStage::Encrypting,
                    bytes_processed,
                    file_size,
                );
            }

            writer.flush()?;
        }

        // Atomic rename.
        temp_output.persist(&output_path).map_err(|e| {
            CryptError::Io(std::io::Error::other(format!(
                "Persist: {e}"
            )))
        })?;

        // Success — remove intermediate temp files.
        cleanup.finish();

        self.emit_progress(
            &opts.progress,
            ProgressStage::Done,
            0,
            0,
        );

        Ok(EncryptResult {
            output_path,
            uuid: file_uuid,
            original_size,
        })
    }

    /// Read and decrypt only the header of an encrypted file.
    ///
    /// This is a fast, lightweight operation — it derives the keys and
    /// decrypts only the small metadata block without touching the
    /// actual encrypted payload.
    ///
    /// Returns the [`EncryptedMetadata`] on success.
    pub async fn decrypt_header(
        &self,
        input_path: std::path::PathBuf,
        password: String,
    ) -> Result<EncryptedMetadata> {
        let input_file = File::open(&input_path)?;
        let mut reader = BufReader::new(input_file);

        // Read and validate public header.
        let public_header =
            PublicHeader::read_from(&mut reader)?;

        // Read encrypted metadata bytes.
        let mut sealed_meta =
            vec![0u8; public_header.encrypted_meta_len as usize];
        reader.read_exact(&mut sealed_meta)?;

        // Derive keys (CPU-heavy – offload to blocking thread).
        let salt = public_header.salt;
        let params = public_header.argon2_params;
        let keys = tokio::task::spawn_blocking(move || {
            kdf::derive_keys(&password, &salt, &params)
        })
        .await
        .map_err(|e| {
            CryptError::KeyDerivation(format!("Join: {e}"))
        })??;

        // Decrypt metadata with AAD matching the public header.
        let mut header_for_aad = public_header.clone();
        header_for_aad.encrypted_meta_len = 0;
        let header_aad = header_for_aad.to_bytes();

        let metadata = EncryptedMetadata::unseal(
            &sealed_meta,
            &keys.header_key,
            &public_header.header_nonce,
            &header_aad,
        )?;

        Ok(metadata)
    }

    /// Decrypt an encrypted file.
    ///
    /// Returns the path to the decrypted output and its metadata.
    ///
    /// All temporary files are cleaned up on both success and
    /// error (via RAII guard).
    pub async fn decrypt(
        &self,
        opts: DecryptOptions,
    ) -> Result<DecryptResult> {
        let input_file = File::open(&opts.input_path)?;
        let mut reader = BufReader::new(input_file);

        // Step 1: Read and validate public header.
        let public_header =
            PublicHeader::read_from(&mut reader)?;

        // Step 2: Read encrypted metadata.
        let mut sealed_meta =
            vec![0u8; public_header.encrypted_meta_len as usize];
        reader.read_exact(&mut sealed_meta)?;

        // Step 3: Derive keys.
        let password = opts.password.clone();
        let salt = public_header.salt;
        let params = public_header.argon2_params;
        let keys = tokio::task::spawn_blocking(move || {
            kdf::derive_keys(&password, &salt, &params)
        })
        .await
        .map_err(|e| {
            CryptError::KeyDerivation(format!("Join: {e}"))
        })??;

        // Step 4: Decrypt metadata with AAD.
        let mut header_for_aad = public_header.clone();
        header_for_aad.encrypted_meta_len = 0;
        let header_aad = header_for_aad.to_bytes();

        let metadata = EncryptedMetadata::unseal(
            &sealed_meta,
            &keys.header_key,
            &public_header.header_nonce,
            &header_aad,
        )?;

        // RAII guard for all temp files created below.
        let temp_parent = opts
            .temp_dir
            .clone()
            .unwrap_or_else(|| opts.output_dir.clone());
        let mut cleanup = TempCleanup::new();

        // Step 5: Decrypt data chunks into a temp file.
        let temp_decrypted =
            NamedTempFile::new_in(&temp_parent)?;

        let chunk_size = public_header.chunk_size as usize;
        let encrypted_chunk_size = chunk_size + TAG_LEN;
        let progress_cb = opts.progress.clone();

        {
            let mut writer =
                BufWriter::new(temp_decrypted.as_file());
            let mut encrypted_buf =
                vec![0u8; encrypted_chunk_size];
            let mut chunk_index: u64 = 0;
            let mut bytes_decrypted: u64 = 0;

            loop {
                let n = read_full(
                    &mut reader,
                    &mut encrypted_buf,
                )?;
                if n == 0 {
                    break;
                }

                let cn = nonce::chunk_nonce(
                    &public_header.data_base_nonce,
                    chunk_index,
                );
                let chunk_aad = cipher::build_chunk_aad(
                    &metadata.uuid,
                    public_header.version,
                    chunk_index,
                );
                let decrypted = cipher::decrypt_chunk(
                    &keys.data_key,
                    &cn,
                    &encrypted_buf[..n],
                    &chunk_aad,
                )?;

                writer.write_all(&decrypted)?;

                chunk_index += 1;
                bytes_decrypted += decrypted.len() as u64;

                self.emit_progress(
                    &progress_cb,
                    ProgressStage::Decrypting,
                    bytes_decrypted,
                    metadata.original_size,
                );
            }

            writer.flush()?;
        }

        // Convert NamedTempFile → kept path & track it.
        let temp_decrypted_kept = temp_decrypted
            .into_temp_path()
            .keep()
            .map_err(|e| CryptError::Io(e.error))?;
        cleanup.track(temp_decrypted_kept.clone());

        // Step 6: Decompress if gzip was applied.
        let data_path = if metadata.gzip_compressed {
            self.emit_progress(
                &opts.progress,
                ProgressStage::DecompressingGzip,
                0,
                0,
            );

            let temp_ungz =
                NamedTempFile::new_in(&temp_parent)?;
            let temp_ungz_kept = temp_ungz
                .into_temp_path()
                .keep()
                .map_err(|e| CryptError::Io(e.error))?;
            cleanup.track(temp_ungz_kept.clone());

            let src = temp_decrypted_kept.clone();
            let dst = temp_ungz_kept.clone();

            tokio::task::spawn_blocking(move || {
                compress::gzip::gzip_decompress(&src, &dst)
            })
            .await
            .map_err(|e| {
                CryptError::Compression(format!("Join: {e}"))
            })?
            .map_err(|e| {
                CryptError::Compression(format!("{e}"))
            })?;

            // Encrypted temp no longer needed.
            cleanup.remove_now(&temp_decrypted_kept);
            temp_ungz_kept
        } else {
            temp_decrypted_kept
        };

        // Step 7: If the original was a directory (7z),
        // decompress the archive.
        let output_path =
            if metadata.original_extension == "7z" {
                self.emit_progress(
                    &opts.progress,
                    ProgressStage::DecompressingDirectory,
                    0,
                    0,
                );

                let out_dir = opts
                    .output_dir
                    .join(&metadata.original_filename);
                let archive = data_path.clone();
                let target = out_dir.clone();

                tokio::task::spawn_blocking(move || {
                    compress::sevenz::decompress_archive(
                        &archive, &target,
                    )
                })
                .await
                .map_err(|e| {
                    CryptError::Compression(format!("Join: {e}"))
                })?
                .map_err(|e| {
                    CryptError::Compression(format!("{e}"))
                })?;

                // data_path is tracked — will be removed by
                // cleanup.finish() below.
                out_dir
            } else {
                // Rename temp file to original name.
                let ext_part =
                    if metadata.original_extension.is_empty() {
                        String::new()
                    } else {
                        format!(
                            ".{}",
                            metadata.original_extension
                        )
                    };
                let final_name = format!(
                    "{}{}",
                    metadata.original_filename, ext_part
                );
                let final_path =
                    opts.output_dir.join(final_name);

                // Move the temp file to its final location.
                // Stop tracking it first so cleanup doesn't
                // delete the final output.
                cleanup.paths.retain(|p| *p != data_path);

                fs::rename(&data_path, &final_path).or_else(
                    |_| {
                        // rename may fail across drives.
                        fs::copy(&data_path, &final_path)?;
                        fs::remove_file(&data_path)?;
                        Ok::<_, std::io::Error>(())
                    },
                )?;

                final_path
            };

        // Remove any remaining temp files.
        cleanup.finish();

        self.emit_progress(
            &opts.progress,
            ProgressStage::Done,
            0,
            0,
        );

        Ok(DecryptResult {
            output_path,
            metadata,
        })
    }

    fn emit_progress(
        &self,
        cb: &Option<ProgressCallback>,
        stage: ProgressStage,
        bytes: u64,
        total: u64,
    ) {
        if let Some(callback) = cb {
            callback(ProgressEvent::new(stage, bytes, total));
        }
    }
}

/// Read as many bytes as possible to fill the buffer.
///
/// Unlike `read`, this loops until the buffer is full or EOF.
fn read_full<R: Read>(
    reader: &mut R,
    buf: &mut [u8],
) -> Result<usize> {
    let mut total = 0;
    while total < buf.len() {
        match reader.read(&mut buf[total..])? {
            0 => break,
            n => total += n,
        }
    }
    Ok(total)
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::{collections::HashMap, sync::atomic::{AtomicU32, Ordering}};
    use tempfile::TempDir;

    fn fast_crypt() -> FileCrypt {
        FileCrypt::new(
            256,
            kdf::Argon2Params {
                t_cost: 1,
                m_cost_kib: 64,
                parallelism: 1,
            },
        )
    }

    #[tokio::test]
    async fn test_encrypt_decrypt_file_round_trip() {
        let dir = TempDir::new().unwrap();
        let original = dir.path().join("hello.txt");
        fs::write(&original, b"Hello, HOPLIXI encryption!")
            .unwrap();

        let crypt = fast_crypt();

        let enc_result = crypt
            .encrypt(EncryptOptions {
                input_path: original.clone(),
                output_dir: dir.path().to_path_buf(),
                uuid: None,
                password: "test-password".to_string(),
                progress: None,
                gzip_compressed: false,
                output_extension: None,
                temp_dir: None,
                metadata: None,
            })
            .await
            .unwrap();

        assert!(enc_result.output_path.exists());

        let out_dir = dir.path().join("decrypted");
        fs::create_dir_all(&out_dir).unwrap();

        let dec_result = crypt
            .decrypt(DecryptOptions {
                input_path: enc_result.output_path,
                output_dir: out_dir.clone(),
                password: "test-password".to_string(),
                progress: None,
                temp_dir: None,
            })
            .await
            .unwrap();

        let decrypted =
            fs::read_to_string(&dec_result.output_path)
                .unwrap();
        assert_eq!(decrypted, "Hello, HOPLIXI encryption!");
        assert_eq!(
            dec_result.metadata.original_filename,
            "hello"
        );
        assert_eq!(
            dec_result.metadata.original_extension,
            "txt"
        );
    }

    #[tokio::test]
    async fn test_encrypt_decrypt_with_gzip() {
        let dir = TempDir::new().unwrap();
        let original = dir.path().join("data.bin");
        let data = vec![0xABu8; 10_000];
        fs::write(&original, &data).unwrap();

        let crypt = fast_crypt();

        let enc_result = crypt
            .encrypt(EncryptOptions {
                input_path: original,
                output_dir: dir.path().to_path_buf(),
                uuid: Some("test-uuid".to_string()),
                password: "gzip-pass".to_string(),
                progress: None,
                gzip_compressed: true,
                output_extension: Some(
                    ".encrypted".to_string(),
                ),
                temp_dir: None,
                metadata: None,
            })
            .await
            .unwrap();

        assert!(enc_result.output_path.exists());
        assert!(enc_result
            .output_path
            .to_str()
            .unwrap()
            .ends_with(".encrypted"));

        let out_dir = dir.path().join("out");
        fs::create_dir_all(&out_dir).unwrap();

        let dec_result = crypt
            .decrypt(DecryptOptions {
                input_path: enc_result.output_path,
                output_dir: out_dir.clone(),
                password: "gzip-pass".to_string(),
                progress: None,
                temp_dir: None,
            })
            .await
            .unwrap();

        let result = fs::read(&dec_result.output_path).unwrap();
        assert_eq!(result, data);
        assert!(dec_result.metadata.gzip_compressed);
    }

    #[tokio::test]
    async fn test_wrong_password_fails() {
        let dir = TempDir::new().unwrap();
        let original = dir.path().join("secret.txt");
        fs::write(&original, b"top secret").unwrap();

        let crypt = fast_crypt();

        let enc_result = crypt
            .encrypt(EncryptOptions {
                input_path: original,
                output_dir: dir.path().to_path_buf(),
                uuid: None,
                password: "correct-password".to_string(),
                progress: None,
                gzip_compressed: false,
                output_extension: None,
                temp_dir: None,
                metadata: None,
            })
            .await
            .unwrap();

        let out_dir = dir.path().join("out");
        fs::create_dir_all(&out_dir).unwrap();

        let result = crypt
            .decrypt(DecryptOptions {
                input_path: enc_result.output_path,
                output_dir: out_dir,
                password: "wrong-password".to_string(),
                progress: None,
                temp_dir: None,
            })
            .await;

        assert!(result.is_err());

        // Verify no temp files leaked in out_dir.
        let leaked: Vec<_> = fs::read_dir(
            dir.path().join("out"),
        )
        .unwrap()
        .filter_map(|e| e.ok())
        .collect();
        assert!(
            leaked.is_empty(),
            "temp files leaked on error: {leaked:?}"
        );
    }

    #[tokio::test]
    async fn test_progress_callback() {
        let dir = TempDir::new().unwrap();
        let original = dir.path().join("progress.txt");
        fs::write(
            &original,
            b"progress test data that spans chunks",
        )
        .unwrap();

        let crypt = fast_crypt();
        let call_count =
            std::sync::Arc::new(AtomicU32::new(0));
        let cc = call_count.clone();

        let progress = std::sync::Arc::new(
            move |_event: ProgressEvent| {
                cc.fetch_add(1, Ordering::SeqCst);
            },
        );

        let _ = crypt
            .encrypt(EncryptOptions {
                input_path: original,
                output_dir: dir.path().to_path_buf(),
                uuid: None,
                password: "progress-pw".to_string(),
                progress: Some(progress),
                gzip_compressed: false,
                output_extension: None,
                temp_dir: None,
                metadata: None,
            })
            .await
            .unwrap();

        // At least the encrypting + done events.
        assert!(call_count.load(Ordering::SeqCst) >= 2);
    }

    #[tokio::test]
    async fn test_encrypt_decrypt_directory() {
        let dir = TempDir::new().unwrap();

        // Create directory structure.
        let src = dir.path().join("my_folder");
        fs::create_dir_all(src.join("sub")).unwrap();
        fs::write(src.join("a.txt"), b"file a content")
            .unwrap();
        fs::write(
            src.join("sub/b.txt"),
            b"file b content",
        )
        .unwrap();

        let crypt = fast_crypt();

        let enc_result = crypt
            .encrypt(EncryptOptions {
                input_path: src,
                output_dir: dir.path().to_path_buf(),
                uuid: None,
                password: "dir-pass".to_string(),
                progress: None,
                gzip_compressed: false,
                output_extension: None,
                temp_dir: None,
                metadata: None,
            })
            .await
            .unwrap();

        let out_dir = dir.path().join("out");
        fs::create_dir_all(&out_dir).unwrap();

        let dec_result = crypt
            .decrypt(DecryptOptions {
                input_path: enc_result.output_path,
                output_dir: out_dir.clone(),
                password: "dir-pass".to_string(),
                progress: None,
                temp_dir: None,
            })
            .await
            .unwrap();

        // Should have extracted the directory.
        assert!(dec_result.output_path.is_dir());

        let fa = fs::read_to_string(
            dec_result.output_path.join("a.txt"),
        )
        .unwrap();
        assert_eq!(fa, "file a content");

        let fb = fs::read_to_string(
            dec_result.output_path.join("sub/b.txt"),
        )
        .unwrap();
        assert_eq!(fb, "file b content");
    }

    #[tokio::test]
    async fn test_multi_chunk_file() {
        let dir = TempDir::new().unwrap();
        let original = dir.path().join("big.bin");

        // File bigger than chunk size (256 bytes).
        let data: Vec<u8> =
            (0..1000).map(|i| (i % 256) as u8).collect();
        fs::write(&original, &data).unwrap();

        let crypt = fast_crypt();

        let enc_result = crypt
            .encrypt(EncryptOptions {
                input_path: original,
                output_dir: dir.path().to_path_buf(),
                uuid: None,
                password: "multi-chunk".to_string(),
                progress: None,
                gzip_compressed: false,
                output_extension: None,
                temp_dir: None,
                metadata: None,
            })
            .await
            .unwrap();

        let out_dir = dir.path().join("out");
        fs::create_dir_all(&out_dir).unwrap();

        let dec_result = crypt
            .decrypt(DecryptOptions {
                input_path: enc_result.output_path,
                output_dir: out_dir,
                password: "multi-chunk".to_string(),
                progress: None,
                temp_dir: None,
            })
            .await
            .unwrap();

        let result =
            fs::read(&dec_result.output_path).unwrap();
        assert_eq!(result, data);
    }

    #[tokio::test]
    async fn test_metadata_preserved() {
        let dir = TempDir::new().unwrap();
        let original = dir.path().join("meta.txt");
        fs::write(&original, b"metadata test").unwrap();

        let crypt = fast_crypt();
        let mut custom_meta = HashMap::new();
        custom_meta.insert(
            "author".to_string(),
            "test".to_string(),
        );
        custom_meta.insert(
            "version".to_string(),
            "1.0".to_string(),
        );

        let enc_result = crypt
            .encrypt(EncryptOptions {
                input_path: original,
                output_dir: dir.path().to_path_buf(),
                uuid: Some("custom-uuid-123".to_string()),
                password: "meta-pw".to_string(),
                progress: None,
                gzip_compressed: false,
                output_extension: None,
                temp_dir: None,
                metadata: Some(custom_meta.clone()),
            })
            .await
            .unwrap();

        assert_eq!(enc_result.uuid, "custom-uuid-123");

        let out_dir = dir.path().join("out");
        fs::create_dir_all(&out_dir).unwrap();

        let dec_result = crypt
            .decrypt(DecryptOptions {
                input_path: enc_result.output_path,
                output_dir: out_dir,
                password: "meta-pw".to_string(),
                progress: None,
                temp_dir: None,
            })
            .await
            .unwrap();

        assert_eq!(
            dec_result.metadata.uuid,
            "custom-uuid-123"
        );
        assert_eq!(
            dec_result.metadata.metadata,
            custom_meta
        );
    }
}
