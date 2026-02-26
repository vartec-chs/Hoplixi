use std::fs::File;
use std::path::{Path, PathBuf};

use sevenz_rust2::ArchiveEntry;
use walkdir::WalkDir;

use crate::error::{CryptError, Result};

/// Compress a directory into a 7z archive.
///
/// Walks the directory recursively and adds all files.
/// Returns the path to the created archive.
pub fn compress_directory(
    dir_path: &Path,
    output_path: &Path,
) -> Result<PathBuf> {
    if !dir_path.is_dir() {
        return Err(CryptError::Compression(format!(
            "Not a directory: {}",
            dir_path.display()
        )));
    }

    let archive_path = output_path.to_path_buf();
    let output_file = File::create(&archive_path)?;
    let mut writer = sevenz_rust2::ArchiveWriter::new(output_file)
        .map_err(|e| CryptError::Compression(format!("7z writer init: {e}")))?;

    for entry in WalkDir::new(dir_path) {
        let entry =
            entry.map_err(|e| CryptError::Compression(format!("Walk: {e}")))?;

        let abs_path = entry.path();
        let rel_path = abs_path
            .strip_prefix(dir_path)
            .map_err(|e| CryptError::Compression(format!("Strip prefix: {e}")))?;

        if rel_path.as_os_str().is_empty() {
            continue;
        }

        let entry_name = rel_path
            .to_str()
            .ok_or_else(|| {
                CryptError::Compression("Non-UTF8 path".to_string())
            })?
            .replace('\\', "/");

        if abs_path.is_dir() {
            let sz_entry = ArchiveEntry::new_directory(&entry_name);
            writer
                .push_archive_entry::<&[u8]>(sz_entry, None)
                .map_err(|e| {
                    CryptError::Compression(format!("7z add dir: {e}"))
                })?;
        } else {
            let file_data = std::fs::read(abs_path)?;
            let sz_entry = ArchiveEntry::new_file(&entry_name);
            writer
                .push_archive_entry(
                    sz_entry,
                    Some(file_data.as_slice()),
                )
                .map_err(|e| {
                    CryptError::Compression(format!("7z add file: {e}"))
                })?;
        }
    }

    writer
        .finish()
        .map_err(|e| CryptError::Compression(format!("7z finish: {e}")))?;

    Ok(archive_path)
}

/// Decompress a 7z archive into a directory.
pub fn decompress_archive(
    archive_path: &Path,
    output_dir: &Path,
) -> Result<()> {
    sevenz_rust2::decompress_file(archive_path, output_dir)
        .map_err(|e| CryptError::Compression(format!("7z decompress: {e}")))?;
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use tempfile::TempDir;

    #[test]
    fn test_compress_decompress_directory() {
        let dir = TempDir::new().unwrap();

        // Create a test directory structure.
        let src_dir = dir.path().join("source");
        std::fs::create_dir_all(src_dir.join("subdir")).unwrap();
        std::fs::write(src_dir.join("file1.txt"), b"Hello from file1")
            .unwrap();
        std::fs::write(
            src_dir.join("subdir/file2.txt"),
            b"Hello from file2",
        )
        .unwrap();

        // Compress.
        let archive = dir.path().join("test.7z");
        compress_directory(&src_dir, &archive).unwrap();
        assert!(archive.exists());

        // Decompress.
        let out_dir = dir.path().join("output");
        decompress_archive(&archive, &out_dir).unwrap();

        // Verify contents.
        let f1 = std::fs::read_to_string(out_dir.join("file1.txt")).unwrap();
        assert_eq!(f1, "Hello from file1");

        let f2 =
            std::fs::read_to_string(out_dir.join("subdir/file2.txt")).unwrap();
        assert_eq!(f2, "Hello from file2");
    }

    #[test]
    fn test_compress_not_a_directory() {
        let dir = TempDir::new().unwrap();
        let file = dir.path().join("not_a_dir.txt");
        std::fs::write(&file, b"data").unwrap();

        let archive = dir.path().join("test.7z");
        let result = compress_directory(&file, &archive);
        assert!(result.is_err());
    }
}
