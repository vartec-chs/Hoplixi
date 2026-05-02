use std::path::{Path, PathBuf};

use chrono::{DateTime, SecondsFormat, Utc};

use super::errors::{CatalogError, IconPackCatalogErrorCode, pack_error};
use super::types::ResolvedPackName;

pub(super) fn normalize_pack_key_impl(value: &str) -> String {
    let mut normalized = value.trim().to_lowercase();
    normalized = normalized
        .chars()
        .map(|character| {
            if character.is_whitespace() {
                '_'
            } else {
                character
            }
        })
        .collect();
    normalized.retain(|character| {
        !matches!(
            character,
            '<' | '>' | ':' | '"' | '/' | '\\' | '|' | '?' | '*'
        )
    });
    normalized
}

pub(super) fn normalize_icon_path_without_extension_impl(value: &str) -> String {
    let normalized_path = value.replace('\\', "/").trim().to_owned();
    let segments = normalized_path
        .split('/')
        .map(|segment| {
            let mut normalized = segment.trim().to_lowercase();
            normalized = normalized
                .chars()
                .map(|character| {
                    if character.is_whitespace() {
                        '_'
                    } else {
                        character
                    }
                })
                .collect();
            normalized.retain(|character| {
                !matches!(
                    character,
                    '<' | '>' | ':' | '"' | '/' | '\\' | '|' | '?' | '*'
                )
            });
            normalized
        })
        .filter(|segment| !segment.is_empty())
        .collect::<Vec<_>>();

    if segments.is_empty() {
        "icon".to_owned()
    } else {
        segments.join("/")
    }
}

pub(super) fn parse_rfc3339_to_millis(value: &str) -> Result<i64, CatalogError> {
    DateTime::parse_from_rfc3339(value)
        .map(|timestamp| timestamp.with_timezone(&Utc).timestamp_millis())
        .map_err(|error| {
            pack_error(
                IconPackCatalogErrorCode::ImportFailed,
                format!("Не удалось разобрать дату импортирования: {error}"),
            )
        })
}

pub(super) fn format_millis_to_rfc3339(millis: i64) -> String {
    match DateTime::<Utc>::from_timestamp_millis(millis) {
        Some(timestamp) => timestamp.to_rfc3339_opts(SecondsFormat::Millis, true),
        None => Utc::now().to_rfc3339_opts(SecondsFormat::Millis, true),
    }
}

pub(super) fn resolve_root_path(root_path: &str) -> Result<PathBuf, CatalogError> {
    let trimmed = root_path.trim();
    if trimmed.is_empty() {
        return Err(pack_error(
            IconPackCatalogErrorCode::InvalidDirectory,
            "Путь к каталогу пака иконок не задан.",
        ));
    }

    Ok(PathBuf::from(trimmed))
}

pub(super) fn prepare_pack_name(display_name: &str) -> Result<ResolvedPackName, CatalogError> {
    let sanitized_display_name = display_name.trim().to_owned();
    if sanitized_display_name.is_empty() {
        return Err(pack_error(
            IconPackCatalogErrorCode::InvalidPackName,
            "Название пака не может быть пустым.",
        ));
    }

    let pack_key = normalize_pack_key_impl(&sanitized_display_name);
    if pack_key.is_empty() {
        return Err(pack_error(
            IconPackCatalogErrorCode::InvalidPackName,
            "Название пака содержит только недопустимые символы.",
        ));
    }

    Ok(ResolvedPackName {
        display_name: sanitized_display_name,
        pack_key,
    })
}

pub(super) fn make_output_file_path(staging_pack_dir: &Path, svg_relative_path: &str) -> PathBuf {
    let mut output = staging_pack_dir.to_path_buf();
    for segment in svg_relative_path.split('/') {
        output.push(segment);
    }
    output
}
