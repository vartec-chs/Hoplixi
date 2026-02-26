use std::path::PathBuf;
use std::sync::Arc;

use hoplixi_file_crypt::{
    DecryptOptions, EncryptOptions, FileCrypt, ProgressEvent,
};

#[tokio::main]
async fn main() {
    let args: Vec<String> = std::env::args().collect();

    if args.len() < 4 {
        eprintln!(
            "Usage:\n  \
             hoplixi-crypt encrypt <input> <output-dir> <password> [--gzip]\n  \
             hoplixi-crypt decrypt <input.enc> <output-dir> <password>"
        );
        std::process::exit(1);
    }

    let command = &args[1];
    let input = PathBuf::from(&args[2]);
    let output_dir = PathBuf::from(&args[3]);
    let password = args[4].clone();

    let progress: Option<hoplixi_file_crypt::ProgressCallback> =
        Some(Arc::new(|event: ProgressEvent| {
            if event.total_bytes > 0 {
                println!(
                    "[{:?}] {:.1}%  ({}/{})",
                    event.stage,
                    event.percentage(),
                    event.bytes_processed,
                    event.total_bytes
                );
            } else {
                println!("[{:?}]", event.stage);
            }
        }));

    let crypt = FileCrypt::default();

    match command.as_str() {
        "encrypt" => {
            let gzip = args.iter().any(|a| a == "--gzip");

            match crypt
                .encrypt(EncryptOptions {
                    input_path: input,
                    output_dir,
                    uuid: None,
                    password,
                    progress,
                    gzip_compressed: gzip,
                    output_extension: None,
                    temp_dir: None,
                    metadata: None,
                })
                .await
            {
                Ok(result) => {
                    println!("Encrypted: {}", result.output_path.display());
                    println!("UUID: {}", result.uuid);
                    println!("Original size: {} bytes", result.original_size);
                }
                Err(e) => {
                    eprintln!("Encryption failed: {e}");
                    std::process::exit(1);
                }
            }
        }
        "decrypt" => {
            match crypt
                .decrypt(DecryptOptions {
                    input_path: input,
                    output_dir,
                    password,
                    progress,
                    temp_dir: None,
                })
                .await
            {
                Ok(result) => {
                    println!("Decrypted: {}", result.output_path.display());
                    println!(
                        "Original: {}.{}",
                        result.metadata.original_filename,
                        result.metadata.original_extension
                    );
                }
                Err(e) => {
                    eprintln!("Decryption failed: {e}");
                    std::process::exit(1);
                }
            }
        }
        _ => {
            eprintln!("Unknown command: {command}. Use 'encrypt' or 'decrypt'.");
            std::process::exit(1);
        }
    }
}
