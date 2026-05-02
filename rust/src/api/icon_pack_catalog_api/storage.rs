use std::fs;
use std::path::Path;

use super::constants::{INDEX_FILE_NAME, MANIFEST_FILE_NAME};
use super::errors::{CatalogError, IconPackCatalogErrorCode, pack_error};
use super::types::{EntryFile, FrbIconPackEntry, FrbIconPackSummary, ManifestFile};
use super::utils::{normalize_pack_key_impl, parse_rfc3339_to_millis, resolve_root_path};

fn list_pack_keys(root_path: &Path) -> Result<Vec<String>, CatalogError> {
    if !root_path.exists() {
        return Ok(Vec::new());
    }

    let mut keys = Vec::new();
    for entry in fs::read_dir(root_path).map_err(|error| {
        pack_error(
            IconPackCatalogErrorCode::ImportFailed,
            format!("Не удалось прочитать каталог паков: {error}"),
        )
    })? {
        let entry = entry.map_err(|error| {
            pack_error(
                IconPackCatalogErrorCode::ImportFailed,
                format!("Не удалось прочитать запись каталога паков: {error}"),
            )
        })?;

        let file_type = entry.file_type().map_err(|error| {
            pack_error(
                IconPackCatalogErrorCode::ImportFailed,
                format!("Не удалось определить тип записи каталога паков: {error}"),
            )
        })?;

        if !file_type.is_dir() {
            continue;
        }

        let directory_name = entry.file_name().to_string_lossy().into_owned();
        if directory_name.starts_with('.') {
            continue;
        }

        let manifest_path = entry.path().join(MANIFEST_FILE_NAME);
        if !manifest_path.exists() {
            continue;
        }

        let manifest_source = match fs::read_to_string(&manifest_path) {
            Ok(source) => source,
            Err(error) => {
                log::error!(
                    target: "IconPackCatalogService",
                    "Failed to read icon pack manifest from {}: {}",
                    manifest_path.display(),
                    error,
                );
                continue;
            }
        };

        match serde_json::from_str::<ManifestFile>(&manifest_source) {
            Ok(manifest) => keys.push(manifest.pack_key),
            Err(error) => {
                log::error!(
                    target: "IconPackCatalogService",
                    "Failed to parse icon pack manifest from {}: {}",
                    manifest_path.display(),
                    error,
                );
            }
        }
    }

    Ok(keys)
}

fn read_manifest(root_path: &Path, pack_key: &str) -> Result<ManifestFile, CatalogError> {
    let manifest_path = root_path.join(pack_key).join(MANIFEST_FILE_NAME);
    let source = fs::read_to_string(&manifest_path).map_err(|error| {
        pack_error(
            IconPackCatalogErrorCode::ImportFailed,
            format!("Не удалось прочитать manifest: {error}"),
        )
    })?;

    serde_json::from_str::<ManifestFile>(&source).map_err(|error| {
        pack_error(
            IconPackCatalogErrorCode::ImportFailed,
            format!("Не удалось разобрать manifest: {error}"),
        )
    })
}

fn manifest_to_summary(manifest: ManifestFile) -> Result<FrbIconPackSummary, CatalogError> {
    Ok(FrbIconPackSummary {
        pack_key: manifest.pack_key,
        display_name: manifest.display_name,
        source_archive_name: manifest.source_archive_name,
        imported_at_millis: parse_rfc3339_to_millis(&manifest.imported_at)?,
        icon_count: manifest.icon_count,
    })
}

pub(super) fn read_entry_file(index_path: &Path) -> Result<Vec<EntryFile>, CatalogError> {
    if !index_path.exists() {
        return Ok(Vec::new());
    }

    let source = fs::read_to_string(index_path).map_err(|error| {
        pack_error(
            IconPackCatalogErrorCode::ImportFailed,
            format!("Не удалось прочитать index: {error}"),
        )
    })?;

    let mut entries = Vec::new();
    for line in source.lines() {
        let trimmed = line.trim();
        if trimmed.is_empty() {
            continue;
        }

        let entry = serde_json::from_str::<EntryFile>(trimmed).map_err(|error| {
            pack_error(
                IconPackCatalogErrorCode::ImportFailed,
                format!("Не удалось разобрать запись index: {error}"),
            )
        })?;
        entries.push(entry);
    }

    Ok(entries)
}

fn entry_file_to_bridge(entry: EntryFile) -> Result<FrbIconPackEntry, CatalogError> {
    Ok(FrbIconPackEntry {
        key: entry.key,
        pack_key: entry.pack_key,
        pack_name: entry.pack_name,
        icon_key: entry.icon_key,
        name: entry.name,
        relative_path: entry.relative_path,
        svg_path: entry.svg_path,
        imported_at_millis: parse_rfc3339_to_millis(&entry.imported_at)?,
    })
}

pub(super) fn read_svg_text(
    root_path: &Path,
    pack_key: &str,
    svg_path: &str,
) -> Result<Option<String>, CatalogError> {
    let svg_file = root_path.join(pack_key).join(Path::new(svg_path));
    if !svg_file.exists() {
        return Ok(None);
    }

    let content = fs::read_to_string(&svg_file).map_err(|error| {
        pack_error(
            IconPackCatalogErrorCode::ImportFailed,
            format!("Не удалось прочитать SVG: {error}"),
        )
    })?;

    Ok(Some(content))
}

pub(super) fn build_summary_from_fields(
    pack_key: String,
    display_name: String,
    source_archive_name: String,
    imported_at_millis: i64,
    icon_count: i32,
) -> FrbIconPackSummary {
    FrbIconPackSummary {
        pack_key,
        display_name,
        source_archive_name,
        imported_at_millis,
        icon_count,
    }
}

pub(super) fn write_entry_file(
    path: &Path,
    entries: &[FrbIconPackEntry],
    imported_at: &str,
) -> Result<(), CatalogError> {
    let lines = entries
        .iter()
        .map(|entry| EntryFile {
            key: entry.key.clone(),
            pack_key: entry.pack_key.clone(),
            pack_name: entry.pack_name.clone(),
            icon_key: entry.icon_key.clone(),
            name: entry.name.clone(),
            relative_path: entry.relative_path.clone(),
            svg_path: entry.svg_path.clone(),
            imported_at: imported_at.to_owned(),
        })
        .map(|entry| {
            serde_json::to_string(&entry).map_err(|error| {
                pack_error(
                    IconPackCatalogErrorCode::ImportFailed,
                    format!("Не удалось сериализовать index: {error}"),
                )
            })
        })
        .collect::<Result<Vec<_>, _>>()?
        .join("\n");

    fs::write(path, lines).map_err(|error| {
        pack_error(
            IconPackCatalogErrorCode::ImportFailed,
            format!("Не удалось записать index: {error}"),
        )
    })
}

pub(super) fn write_manifest_file(
    path: &Path,
    manifest: &ManifestFile,
) -> Result<(), CatalogError> {
    let content = serde_json::to_string_pretty(manifest).map_err(|error| {
        pack_error(
            IconPackCatalogErrorCode::ImportFailed,
            format!("Не удалось сериализовать manifest: {error}"),
        )
    })?;

    fs::write(path, content).map_err(|error| {
        pack_error(
            IconPackCatalogErrorCode::ImportFailed,
            format!("Не удалось записать manifest: {error}"),
        )
    })
}

pub(super) fn delete_directory_if_exists(path: &Path) {
    if !path.exists() {
        return;
    }

    if let Err(error) = fs::remove_dir_all(path) {
        log::error!(
            target: "IconPackCatalogService",
            "Failed to cleanup {}: {}",
            path.display(),
            error,
        );
    }
}

/// List all imported icon packs.
pub(super) async fn list_packs(root_path: String) -> anyhow::Result<Vec<FrbIconPackSummary>> {
    let resolved_root = resolve_root_path(&root_path)?;
    let pack_keys = list_pack_keys(&resolved_root).map_err(CatalogError::into_anyhow)?;
    let mut summaries = Vec::new();

    for pack_key in pack_keys {
        let manifest = match read_manifest(&resolved_root, &pack_key) {
            Ok(manifest) => manifest,
            Err(error) => {
                log::error!(
                    target: "IconPackCatalogService",
                    "Failed to read icon pack manifest for {}: {}",
                    pack_key,
                    error,
                );
                continue;
            }
        };

        match manifest_to_summary(manifest) {
            Ok(summary) => summaries.push(summary),
            Err(error) => {
                log::error!(
                    target: "IconPackCatalogService",
                    "Failed to convert icon pack manifest for {}: {}",
                    pack_key,
                    error,
                );
            }
        }
    }

    summaries.sort_by(|left, right| right.imported_at_millis.cmp(&left.imported_at_millis));
    Ok(summaries)
}

/// Delete an imported icon pack by its catalog key.
pub(super) async fn delete_pack(root_path: String, pack_key: String) -> anyhow::Result<()> {
    let resolved_root = resolve_root_path(&root_path)?;
    let trimmed_key = pack_key.trim();
    let normalized_key = normalize_pack_key_impl(trimmed_key);

    if normalized_key.is_empty() || normalized_key != trimmed_key {
        return Err(pack_error(
            IconPackCatalogErrorCode::InvalidPackName,
            "Ключ пака иконок недопустим.",
        )
        .into_anyhow());
    }

    let pack_dir = resolved_root.join(&normalized_key);
    if !pack_dir.exists() {
        return Err(pack_error(
            IconPackCatalogErrorCode::PackNotFound,
            "Пак иконок не найден.",
        )
        .into_anyhow());
    }

    if !pack_dir.is_dir() || !pack_dir.join(MANIFEST_FILE_NAME).is_file() {
        return Err(pack_error(
            IconPackCatalogErrorCode::InvalidDirectory,
            "Каталог пака иконок повреждён или не содержит manifest.json.",
        )
        .into_anyhow());
    }

    fs::remove_dir_all(&pack_dir).map_err(|error| {
        pack_error(
            IconPackCatalogErrorCode::ImportFailed,
            format!("Не удалось удалить пак иконок: {error}"),
        )
        .into_anyhow()
    })?;

    log::info!(
        target: "IconPackCatalogService",
        "Deleted icon pack {}",
        normalized_key,
    );

    Ok(())
}

/// List icon entries, optionally scoped to a single pack and filtered by query.
pub(super) async fn list_icons(
    root_path: String,
    pack_key: Option<String>,
    query: String,
    offset: i32,
    limit: i32,
) -> anyhow::Result<Vec<FrbIconPackEntry>> {
    let resolved_root = resolve_root_path(&root_path)?;
    let keys = match pack_key {
        Some(pack_key) => vec![pack_key],
        None => list_packs(root_path.clone())
            .await?
            .into_iter()
            .map(|pack| pack.pack_key)
            .collect(),
    };

    let normalized_query = query.trim().to_lowercase();
    let mut entries = Vec::new();

    for key in keys {
        let index_path = resolved_root.join(&key).join(INDEX_FILE_NAME);
        let pack_entries = match read_entry_file(&index_path) {
            Ok(entries) => entries,
            Err(error) => {
                log::error!(
                    target: "IconPackCatalogService",
                    "Failed to read icon pack index for {}: {}",
                    key,
                    error,
                );
                return Err(error.into_anyhow());
            }
        };

        for entry in pack_entries {
            let entry = entry_file_to_bridge(entry).map_err(CatalogError::into_anyhow)?;
            if !normalized_query.is_empty()
                && !entry.name.to_lowercase().contains(&normalized_query)
                && !entry.key.to_lowercase().contains(&normalized_query)
                && !entry
                    .relative_path
                    .to_lowercase()
                    .contains(&normalized_query)
            {
                continue;
            }
            entries.push(entry);
        }
    }

    entries.sort_by(|left, right| left.key.cmp(&right.key));
    if entries.is_empty() || offset >= entries.len() as i32 {
        return Ok(Vec::new());
    }

    let safe_offset = offset.max(0) as usize;
    let safe_limit = if limit <= 0 {
        entries.len().saturating_sub(safe_offset)
    } else {
        limit as usize
    };
    let end = (safe_offset + safe_limit).min(entries.len());
    Ok(entries[safe_offset..end].to_vec())
}

/// Read the SVG contents for a catalog icon key.
pub(super) async fn read_svg_by_key(
    root_path: String,
    icon_key: String,
) -> anyhow::Result<Option<String>> {
    let resolved_root = resolve_root_path(&root_path)?;
    let key_parts = icon_key.split('/').collect::<Vec<_>>();
    if key_parts.len() < 2 {
        return Ok(None);
    }

    let pack_key = key_parts[0];
    let index_path = resolved_root.join(pack_key).join(INDEX_FILE_NAME);
    let entries = read_entry_file(&index_path).map_err(CatalogError::into_anyhow)?;

    let Some(entry) = entries.into_iter().find(|entry| entry.key == icon_key) else {
        return Ok(None);
    };

    read_svg_text(&resolved_root, pack_key, &entry.svg_path).map_err(CatalogError::into_anyhow)
}
