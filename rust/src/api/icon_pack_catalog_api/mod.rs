pub mod constants;
pub mod errors;
pub mod import;
pub mod storage;
pub mod types;
pub mod utils;

use crate::frb_generated::StreamSink;

pub use types::*;

/// Normalize a user-provided pack name into a stable catalog key.
#[flutter_rust_bridge::frb(sync)]
pub fn normalize_pack_key(value: String) -> String {
    utils::normalize_pack_key_impl(&value)
}

/// Normalize an icon-relative path before generating the catalog key.
#[flutter_rust_bridge::frb(sync)]
pub fn normalize_icon_path_without_extension(value: String) -> String {
    utils::normalize_icon_path_without_extension_impl(&value)
}

/// List all imported icon packs.
pub async fn list_packs(root_path: String) -> anyhow::Result<Vec<FrbIconPackSummary>> {
    storage::list_packs(root_path).await
}

/// Delete an imported icon pack by its catalog key.
pub async fn delete_pack(root_path: String, pack_key: String) -> anyhow::Result<()> {
    storage::delete_pack(root_path, pack_key).await
}

/// List icon entries, optionally scoped to a single pack and filtered by query.
pub async fn list_icons(
    root_path: String,
    pack_key: Option<String>,
    query: String,
    offset: i32,
    limit: i32,
) -> anyhow::Result<Vec<FrbIconPackEntry>> {
    storage::list_icons(root_path, pack_key, query, offset, limit).await
}

/// Read the SVG contents for a catalog icon key.
pub async fn read_svg_by_key(
    root_path: String,
    icon_key: String,
) -> anyhow::Result<Option<String>> {
    storage::read_svg_by_key(root_path, icon_key).await
}

/// Import a ZIP or 7Z archive and emit progress events while unpacking SVG files.
pub async fn import_pack(
    root_path: String,
    archive_path: String,
    display_name: String,
    sink: StreamSink<FrbIconPackImportEvent>,
) {
    import::import_pack(root_path, archive_path, display_name, sink).await;
}

/// Import a directory containing SVG files and emit progress events while unpacking.
pub async fn import_directory(
    root_path: String,
    directory_path: String,
    display_name: String,
    sink: StreamSink<FrbIconPackImportEvent>,
) {
    import::import_directory(root_path, directory_path, display_name, sink).await;
}
