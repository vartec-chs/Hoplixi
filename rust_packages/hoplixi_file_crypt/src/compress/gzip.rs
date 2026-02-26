use std::fs::File;
use std::io::{BufReader, BufWriter, Read, Write};
use std::path::Path;

use flate2::read::GzDecoder;
use flate2::write::GzEncoder;
use flate2::Compression;

use crate::error::Result;

const BUF_SIZE: usize = 64 * 1024;

/// Gzip-compress a file in streaming mode.
///
/// Reads from `input_path` and writes compressed data to `output_path`.
pub fn gzip_compress(input_path: &Path, output_path: &Path) -> Result<()> {
    let input = File::open(input_path)?;
    let mut reader = BufReader::with_capacity(BUF_SIZE, input);

    let output = File::create(output_path)?;
    let writer = BufWriter::with_capacity(BUF_SIZE, output);
    let mut encoder = GzEncoder::new(writer, Compression::default());

    let mut buf = vec![0u8; BUF_SIZE];
    loop {
        let n = reader.read(&mut buf)?;
        if n == 0 {
            break;
        }
        encoder.write_all(&buf[..n])?;
    }

    encoder.finish()?;
    Ok(())
}

/// Gzip-decompress a file in streaming mode.
///
/// Reads from `input_path` and writes decompressed data to `output_path`.
pub fn gzip_decompress(input_path: &Path, output_path: &Path) -> Result<()> {
    let input = File::open(input_path)?;
    let reader = BufReader::with_capacity(BUF_SIZE, input);
    let mut decoder = GzDecoder::new(reader);

    let output = File::create(output_path)?;
    let mut writer = BufWriter::with_capacity(BUF_SIZE, output);

    let mut buf = vec![0u8; BUF_SIZE];
    loop {
        let n = decoder.read(&mut buf)?;
        if n == 0 {
            break;
        }
        writer.write_all(&buf[..n])?;
    }

    writer.flush()?;
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use tempfile::TempDir;

    #[test]
    fn test_gzip_round_trip() {
        let dir = TempDir::new().unwrap();
        let original = dir.path().join("original.txt");
        let compressed = dir.path().join("compressed.gz");
        let decompressed = dir.path().join("decompressed.txt");

        let data = b"Hello, gzip compression test! Repeated data: "
            .repeat(100);
        std::fs::write(&original, &data).unwrap();

        gzip_compress(&original, &compressed).unwrap();

        // Compressed file should exist and be smaller.
        let compressed_size = std::fs::metadata(&compressed).unwrap().len();
        assert!(compressed_size < data.len() as u64);

        gzip_decompress(&compressed, &decompressed).unwrap();

        let result = std::fs::read(&decompressed).unwrap();
        assert_eq!(result, data);
    }

    #[test]
    fn test_gzip_empty_file() {
        let dir = TempDir::new().unwrap();
        let original = dir.path().join("empty.txt");
        let compressed = dir.path().join("empty.gz");
        let decompressed = dir.path().join("empty_out.txt");

        std::fs::write(&original, b"").unwrap();

        gzip_compress(&original, &compressed).unwrap();
        gzip_decompress(&compressed, &decompressed).unwrap();

        let result = std::fs::read(&decompressed).unwrap();
        assert!(result.is_empty());
    }
}
