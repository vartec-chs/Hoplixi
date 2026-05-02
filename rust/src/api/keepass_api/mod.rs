pub mod export;
pub mod types;

pub use types::*;

impl FrbKeepassExportOptions {
    pub fn simple(input_path: String, password: String) -> Self {
        Self {
            input_path,
            password: Some(password),
            keyfile_path: None,
            include_history: true,
            include_attachments: true,
        }
    }
}

/// Open a KeePass database and export it into a normalized structure.
///
/// The result is intentionally storage-oriented:
/// - groups are flattened and linked by `parent_uuid`
/// - entries are flattened and reference their group
/// - every field preserves the `protected` flag
/// - history, attachments and OTP data can be imported without reparsing KDBX
pub async fn export_keepass_database(
    opts: FrbKeepassExportOptions,
) -> anyhow::Result<FrbKeepassDatabaseExport> {
    export::export_keepass_database(opts).await
}
