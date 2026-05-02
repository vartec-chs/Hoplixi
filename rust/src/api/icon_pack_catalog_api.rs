use std::fs;
use std::path::{Path, PathBuf};
use std::sync::Arc;

use anyhow::anyhow;
use archive::{ArchiveExtractor, ArchiveFormat};
use chrono::{DateTime, SecondsFormat, Utc};
use serde::{Deserialize, Serialize};

use crate::frb_generated::StreamSink;

const MANIFEST_FILE_NAME: &str = "manifest.json";
const INDEX_FILE_NAME: &str = "index.jsonl";
const ICONS_FOLDER_NAME: &str = "icons";
const STAGING_FOLDER_NAME: &str = ".staging";

const ERROR_PREFIX: &str = "ICON_PACK_ERROR";

#[derive(Debug, Clone)]
pub struct FrbIconPackSummary {
    pub pack_key: String,
    pub display_name: String,
    pub source_archive_name: String,
    pub imported_at_millis: i64,
    pub icon_count: i32,
}

#[derive(Debug, Clone)]
pub struct FrbIconPackEntry {
    pub key: String,
    pub pack_key: String,
    pub pack_name: String,
    pub icon_key: String,
    pub name: String,
    pub relative_path: String,
    pub svg_path: String,
    pub imported_at_millis: i64,
}

#[derive(Debug, Clone)]
pub struct FrbIconPackImportProgress {
    pub current: i32,
    pub total: i32,
    pub current_file: String,
}

#[derive(Debug, Clone)]
pub struct FrbIconPackError {
    pub code: String,
    pub message: String,
}

#[derive(Debug, Clone)]
pub enum FrbIconPackImportEvent {
    Progress(FrbIconPackImportProgress),
    Done(FrbIconPackSummary),
    Error(FrbIconPackError),
}

#[derive(Debug, Clone)]
struct CatalogError {
    code: IconPackCatalogErrorCode,
    message: String,
}

impl CatalogError {
    fn new(code: IconPackCatalogErrorCode, message: impl Into<String>) -> Self {
        Self {
            code,
            message: message.into(),
        }
    }

    fn into_anyhow(self) -> anyhow::Error {
        anyhow!(format!(
            "{ERROR_PREFIX}[{}]: {}",
            self.code.as_str(),
            self.message
        ))
    }

    fn into_bridge_error(self) -> FrbIconPackError {
        FrbIconPackError {
            code: self.code.as_str().to_owned(),
            message: self.message,
        }
    }
}

impl std::fmt::Display for CatalogError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}", self.message)
    }
}

impl std::error::Error for CatalogError {}

#[derive(Debug, Clone, Copy)]
enum IconPackCatalogErrorCode {
    DuplicatePack,
    ImportFailed,
    InvalidArchive,
    InvalidDirectory,
    InvalidPackName,
    NoSvgFiles,
    PackNotFound,
}

impl IconPackCatalogErrorCode {
    fn as_str(self) -> &'static str {
        match self {
            IconPackCatalogErrorCode::DuplicatePack => "duplicate_pack",
            IconPackCatalogErrorCode::ImportFailed => "import_failed",
            IconPackCatalogErrorCode::InvalidArchive => "invalid_archive",
            IconPackCatalogErrorCode::InvalidDirectory => "invalid_directory",
            IconPackCatalogErrorCode::InvalidPackName => "invalid_pack_name",
            IconPackCatalogErrorCode::NoSvgFiles => "no_svg_files",
            IconPackCatalogErrorCode::PackNotFound => "pack_not_found",
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
struct ManifestFile {
    pack_key: String,
    display_name: String,
    source_archive_name: String,
    imported_at: String,
    icon_count: i32,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
struct EntryFile {
    key: String,
    pack_key: String,
    pack_name: String,
    icon_key: String,
    name: String,
    relative_path: String,
    svg_path: String,
    imported_at: String,
}

#[derive(Debug, Clone)]
enum ImportCandidateSource {
    Archive(Vec<u8>),
    Directory(PathBuf),
}

#[derive(Debug, Clone)]
struct ImportCandidate {
    relative_path: String,
    source: ImportCandidateSource,
}

#[derive(Debug, Clone)]
struct ResolvedPackName {
    display_name: String,
    pack_key: String,
}

fn pack_error(code: IconPackCatalogErrorCode, message: impl Into<String>) -> CatalogError {
    CatalogError::new(code, message)
}

fn normalize_pack_key_impl(value: &str) -> String {
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

fn normalize_icon_path_without_extension_impl(value: &str) -> String {
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

fn parse_rfc3339_to_millis(value: &str) -> Result<i64, CatalogError> {
    DateTime::parse_from_rfc3339(value)
        .map(|timestamp| timestamp.with_timezone(&Utc).timestamp_millis())
        .map_err(|error| {
            pack_error(
                IconPackCatalogErrorCode::ImportFailed,
                format!("Не удалось разобрать дату импортирования: {error}"),
            )
        })
}

fn format_millis_to_rfc3339(millis: i64) -> String {
    match DateTime::<Utc>::from_timestamp_millis(millis) {
        Some(timestamp) => timestamp.to_rfc3339_opts(SecondsFormat::Millis, true),
        None => Utc::now().to_rfc3339_opts(SecondsFormat::Millis, true),
    }
}

fn resolve_root_path(root_path: &str) -> Result<PathBuf, CatalogError> {
    let trimmed = root_path.trim();
    if trimmed.is_empty() {
        return Err(pack_error(
            IconPackCatalogErrorCode::InvalidDirectory,
            "Путь к каталогу пака иконок не задан.",
        ));
    }

    Ok(PathBuf::from(trimmed))
}

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

fn read_entry_file(index_path: &Path) -> Result<Vec<EntryFile>, CatalogError> {
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

fn read_svg_text(
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

fn build_summary_from_fields(
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

fn ensure_unique_icon_key(
    base_key: &str,
    used_keys: &mut std::collections::HashMap<String, i32>,
) -> String {
    let current_index = used_keys
        .entry(base_key.to_owned())
        .and_modify(|value| *value += 1)
        .or_insert(1);

    if *current_index == 1 {
        base_key.to_owned()
    } else {
        format!("{base_key}_{current_index}")
    }
}

fn should_ignore_archive_path(path: &str) -> bool {
    path.split('/').any(|segment| {
        let trimmed = segment.trim();
        trimmed.is_empty()
            || trimmed == "__MACOSX"
            || trimmed == ".DS_Store"
            || trimmed.starts_with('.')
    })
}

fn normalize_archive_path(path: &str) -> Option<String> {
    let raw = path.replace('\\', "/").trim().to_owned();
    if raw.is_empty() || raw.starts_with('/') {
        return None;
    }

    let mut segments = Vec::new();
    for segment in raw.split('/') {
        let trimmed = segment.trim();
        if trimmed.is_empty() || trimmed == "." {
            continue;
        }

        if trimmed == ".." {
            if segments.pop().is_none() {
                return None;
            }
            continue;
        }

        segments.push(trimmed.to_owned());
    }

    if segments.is_empty() {
        return None;
    }

    Some(segments.join("/"))
}

fn detect_shared_root(paths: &[String]) -> Option<String> {
    let first = paths.first()?;
    let root = first.split('/').next()?.to_owned();

    let has_shared_root = paths.iter().all(|path| {
        let mut segments = path.split('/');
        matches!(segments.next(), Some(segment) if segment == root) && segments.next().is_some()
    });

    if has_shared_root { Some(root) } else { None }
}

fn strip_shared_root(path: &str, shared_root: Option<&str>) -> String {
    let Some(shared_root) = shared_root else {
        return path.to_owned();
    };

    let prefix = format!("{shared_root}/");
    if let Some(stripped) = path.strip_prefix(&prefix) {
        stripped.to_owned()
    } else {
        path.to_owned()
    }
}

fn archive_format_from_path(path: &str) -> Result<ArchiveFormat, CatalogError> {
    let extension = Path::new(path)
        .extension()
        .and_then(|value| value.to_str())
        .unwrap_or_default()
        .to_lowercase();

    match extension.as_str() {
        "zip" => Ok(ArchiveFormat::Zip),
        "7z" => Ok(ArchiveFormat::SevenZ),
        _ => Err(pack_error(
            IconPackCatalogErrorCode::InvalidArchive,
            "Поддерживаются только ZIP- и 7Z-архивы.",
        )),
    }
}

fn make_output_file_path(staging_pack_dir: &Path, svg_relative_path: &str) -> PathBuf {
    let mut output = staging_pack_dir.to_path_buf();
    for segment in svg_relative_path.split('/') {
        output.push(segment);
    }
    output
}

fn prepare_pack_name(display_name: &str) -> Result<ResolvedPackName, CatalogError> {
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

fn write_entry_file(
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

fn write_manifest_file(path: &Path, manifest: &ManifestFile) -> Result<(), CatalogError> {
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

fn delete_directory_if_exists(path: &Path) {
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

fn import_candidates_internal(
    root_path: &Path,
    pack: &ResolvedPackName,
    source_label: &str,
    source_debug_path: &str,
    candidates: Vec<ImportCandidate>,
    sink: Arc<StreamSink<FrbIconPackImportEvent>>,
) -> Result<FrbIconPackSummary, CatalogError> {
    if candidates.is_empty() {
        return Err(pack_error(
            IconPackCatalogErrorCode::NoSvgFiles,
            "В источнике не найдено ни одной SVG-иконки.",
        ));
    }

    let imported_at_millis = Utc::now().timestamp_millis();
    let imported_at = format_millis_to_rfc3339(imported_at_millis);
    let staging_root = root_path.join(STAGING_FOLDER_NAME);
    let staging_dir = staging_root.join(format!("{}_{}", pack.pack_key, imported_at_millis));
    let staging_pack_dir = staging_dir.join(&pack.pack_key);

    fs::create_dir_all(&staging_pack_dir).map_err(|error| {
        pack_error(
            IconPackCatalogErrorCode::ImportFailed,
            format!("Не удалось создать staging-каталог: {error}"),
        )
    })?;

    let import_result = (|| -> Result<FrbIconPackSummary, CatalogError> {
        let mut used_keys = std::collections::HashMap::new();
        let mut entries = Vec::new();
        let total = candidates.len() as i32 + 1;

        for (index, candidate) in candidates.into_iter().enumerate() {
            let ImportCandidate {
                relative_path,
                source,
            } = candidate;

            let base_icon_key = normalize_icon_path_without_extension_impl(
                &Path::new(&relative_path)
                    .with_extension("")
                    .to_string_lossy(),
            );
            let icon_key = ensure_unique_icon_key(&base_icon_key, &mut used_keys);
            let canonical_key = format!("{}/{}", pack.pack_key, icon_key);
            let svg_relative_path = format!("{ICONS_FOLDER_NAME}/{}.svg", icon_key);
            let output_file = make_output_file_path(&staging_pack_dir, &svg_relative_path);

            if let Some(parent) = output_file.parent() {
                fs::create_dir_all(parent).map_err(|error| {
                    pack_error(
                        IconPackCatalogErrorCode::ImportFailed,
                        format!("Не удалось создать папку иконки: {error}"),
                    )
                })?;
            }

            match source {
                ImportCandidateSource::Archive(bytes) => {
                    fs::write(&output_file, bytes).map_err(|error| {
                        pack_error(
                            IconPackCatalogErrorCode::ImportFailed,
                            format!("Не удалось записать SVG из архива: {error}"),
                        )
                    })?;
                }
                ImportCandidateSource::Directory(source_file) => {
                    fs::copy(&source_file, &output_file).map_err(|error| {
                        pack_error(
                            IconPackCatalogErrorCode::ImportFailed,
                            format!("Не удалось скопировать SVG из папки: {error}"),
                        )
                    })?;
                }
            }

            entries.push(FrbIconPackEntry {
                key: canonical_key,
                pack_key: pack.pack_key.clone(),
                pack_name: pack.display_name.clone(),
                icon_key: icon_key.clone(),
                name: Path::new(&relative_path)
                    .file_stem()
                    .and_then(|value| value.to_str())
                    .unwrap_or("icon")
                    .to_owned(),
                relative_path: relative_path.clone(),
                svg_path: svg_relative_path,
                imported_at_millis,
            });

            let _ = sink.add(FrbIconPackImportEvent::Progress(
                FrbIconPackImportProgress {
                    current: (index + 1) as i32,
                    total,
                    current_file: relative_path,
                },
            ));
        }

        let manifest = ManifestFile {
            pack_key: pack.pack_key.clone(),
            display_name: pack.display_name.clone(),
            source_archive_name: source_label.to_owned(),
            imported_at: imported_at.clone(),
            icon_count: entries.len() as i32,
        };

        write_manifest_file(&staging_pack_dir.join(MANIFEST_FILE_NAME), &manifest)?;
        write_entry_file(
            &staging_pack_dir.join(INDEX_FILE_NAME),
            &entries,
            &imported_at,
        )?;

        let target_dir = root_path.join(&pack.pack_key);
        if target_dir.exists() {
            return Err(pack_error(
                IconPackCatalogErrorCode::DuplicatePack,
                format!(
                    "Пак с ключом \"{}\" уже существует. Выберите другое имя.",
                    pack.pack_key
                ),
            ));
        }

        fs::rename(&staging_pack_dir, &target_dir).map_err(|error| {
            pack_error(
                IconPackCatalogErrorCode::ImportFailed,
                format!("Не удалось завершить импорт пака: {error}"),
            )
        })?;

        let _ = sink.add(FrbIconPackImportEvent::Progress(
            FrbIconPackImportProgress {
                current: total,
                total,
                current_file: "Завершение импорта".to_owned(),
            },
        ));

        let summary = build_summary_from_fields(
            pack.pack_key.clone(),
            pack.display_name.clone(),
            source_label.to_owned(),
            imported_at_millis,
            entries.len() as i32,
        );

        log::info!(
            target: "IconPackCatalogService",
            "Imported icon pack {} from {}",
            pack.pack_key,
            source_debug_path,
        );

        Ok(summary)
    })();

    delete_directory_if_exists(&staging_dir);

    import_result
}

fn build_archive_candidates(
    archive_path: &str,
    extractor: &ArchiveExtractor,
) -> Result<Vec<ImportCandidate>, CatalogError> {
    let format = archive_format_from_path(archive_path)?;
    let data = fs::read(archive_path).map_err(|error| {
        pack_error(
            IconPackCatalogErrorCode::InvalidArchive,
            format!("Не удалось прочитать архив: {error}"),
        )
    })?;

    let extracted_files = extractor.extract(&data, format).map_err(|error| {
        pack_error(
            IconPackCatalogErrorCode::InvalidArchive,
            format!("Не удалось распаковать архив: {error}"),
        )
    })?;

    let visible_paths = extracted_files
        .iter()
        .filter(|entry| !entry.is_directory)
        .filter_map(|entry| normalize_archive_path(&entry.path))
        .filter(|path| !should_ignore_archive_path(path))
        .collect::<Vec<_>>();

    let shared_root = detect_shared_root(&visible_paths);
    let mut candidates = Vec::new();

    for entry in extracted_files {
        if entry.is_directory {
            continue;
        }

        let Some(normalized_path) = normalize_archive_path(&entry.path) else {
            continue;
        };

        if should_ignore_archive_path(&normalized_path) {
            continue;
        }

        let relative_path = strip_shared_root(&normalized_path, shared_root.as_deref());
        if Path::new(&relative_path)
            .extension()
            .and_then(|value| value.to_str())
            .map(|value| value.eq_ignore_ascii_case("svg"))
            != Some(true)
        {
            continue;
        }

        candidates.push(ImportCandidate {
            relative_path,
            source: ImportCandidateSource::Archive(entry.data),
        });
    }

    Ok(candidates)
}

fn build_directory_candidates(directory_path: &str) -> Result<Vec<ImportCandidate>, CatalogError> {
    let directory = PathBuf::from(directory_path);
    if !directory.exists() {
        return Err(pack_error(
            IconPackCatalogErrorCode::InvalidDirectory,
            format!("Папка не найдена: {directory_path}"),
        ));
    }

    let mut raw_paths = Vec::new();
    for entry in fs::read_dir(&directory).map_err(|error| {
        pack_error(
            IconPackCatalogErrorCode::InvalidDirectory,
            format!("Не удалось прочитать папку: {error}"),
        )
    })? {
        let entry = entry.map_err(|error| {
            pack_error(
                IconPackCatalogErrorCode::InvalidDirectory,
                format!("Не удалось прочитать запись папки: {error}"),
            )
        })?;

        let path = entry.path();
        let metadata = entry.metadata().map_err(|error| {
            pack_error(
                IconPackCatalogErrorCode::InvalidDirectory,
                format!("Не удалось прочитать свойства файла: {error}"),
            )
        })?;

        if metadata.is_dir() {
            raw_paths.extend(collect_directory_paths(&path, &directory)?);
        } else if metadata.is_file() {
            let relative = path.strip_prefix(&directory).unwrap_or(&path);
            if let Some(normalized_path) = normalize_archive_path(&relative.to_string_lossy()) {
                if !should_ignore_archive_path(&normalized_path) {
                    raw_paths.push(normalized_path);
                }
            }
        }
    }

    let shared_root = detect_shared_root(&raw_paths);
    let mut candidates = Vec::new();

    for normalized_path in raw_paths {
        let relative_path = strip_shared_root(&normalized_path, shared_root.as_deref());
        if Path::new(&relative_path)
            .extension()
            .and_then(|value| value.to_str())
            .map(|value| value.eq_ignore_ascii_case("svg"))
            != Some(true)
        {
            continue;
        }

        let source_file = directory.join(Path::new(&normalized_path));
        candidates.push(ImportCandidate {
            relative_path,
            source: ImportCandidateSource::Directory(source_file),
        });
    }

    Ok(candidates)
}

fn collect_directory_paths(path: &Path, root: &Path) -> Result<Vec<String>, CatalogError> {
    let mut paths = Vec::new();
    for entry in fs::read_dir(path).map_err(|error| {
        pack_error(
            IconPackCatalogErrorCode::InvalidDirectory,
            format!("Не удалось рекурсивно прочитать папку: {error}"),
        )
    })? {
        let entry = entry.map_err(|error| {
            pack_error(
                IconPackCatalogErrorCode::InvalidDirectory,
                format!("Не удалось прочитать вложенную запись: {error}"),
            )
        })?;

        let current_path = entry.path();
        let metadata = entry.metadata().map_err(|error| {
            pack_error(
                IconPackCatalogErrorCode::InvalidDirectory,
                format!("Не удалось прочитать свойства вложенного файла: {error}"),
            )
        })?;

        if metadata.is_dir() {
            paths.extend(collect_directory_paths(&current_path, root)?);
            continue;
        }

        if metadata.is_file() {
            let relative = current_path.strip_prefix(root).unwrap_or(&current_path);
            if let Some(normalized_path) = normalize_archive_path(&relative.to_string_lossy()) {
                if !should_ignore_archive_path(&normalized_path) {
                    paths.push(normalized_path);
                }
            }
        }
    }

    Ok(paths)
}

/// Normalize a user-provided pack name into a stable catalog key.
#[flutter_rust_bridge::frb(sync)]
pub fn normalize_pack_key(value: String) -> String {
    normalize_pack_key_impl(&value)
}

/// Normalize an icon-relative path before generating the catalog key.
#[flutter_rust_bridge::frb(sync)]
pub fn normalize_icon_path_without_extension(value: String) -> String {
    normalize_icon_path_without_extension_impl(&value)
}

/// List all imported icon packs.
pub async fn list_packs(root_path: String) -> anyhow::Result<Vec<FrbIconPackSummary>> {
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
pub async fn delete_pack(root_path: String, pack_key: String) -> anyhow::Result<()> {
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
pub async fn list_icons(
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
pub async fn read_svg_by_key(
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

/// Import a ZIP or 7Z archive and emit progress events while unpacking SVG files.
pub async fn import_pack(
    root_path: String,
    archive_path: String,
    display_name: String,
    sink: StreamSink<FrbIconPackImportEvent>,
) {
    let sink = Arc::new(sink);
    let result = (|| -> Result<FrbIconPackSummary, CatalogError> {
        let resolved_root = resolve_root_path(&root_path)?;
        let pack = prepare_pack_name(&display_name)?;
        let extractor = ArchiveExtractor::new();
        let candidates = build_archive_candidates(&archive_path, &extractor)?;

        import_candidates_internal(
            &resolved_root,
            &pack,
            Path::new(&archive_path)
                .file_name()
                .and_then(|value| value.to_str())
                .unwrap_or(&archive_path),
            &archive_path,
            candidates,
            sink.clone(),
        )
    })();

    match result {
        Ok(summary) => {
            let _ = sink.add(FrbIconPackImportEvent::Done(summary));
        }
        Err(error) => {
            let _ = sink.add(FrbIconPackImportEvent::Error(error.into_bridge_error()));
        }
    }
}

/// Import a directory containing SVG files and emit progress events while unpacking.
pub async fn import_directory(
    root_path: String,
    directory_path: String,
    display_name: String,
    sink: StreamSink<FrbIconPackImportEvent>,
) {
    let sink = Arc::new(sink);
    let result = (|| -> Result<FrbIconPackSummary, CatalogError> {
        let resolved_root = resolve_root_path(&root_path)?;
        let pack = prepare_pack_name(&display_name)?;
        let candidates = build_directory_candidates(&directory_path)?;

        import_candidates_internal(
            &resolved_root,
            &pack,
            Path::new(&directory_path)
                .file_name()
                .and_then(|value| value.to_str())
                .unwrap_or(&directory_path),
            &directory_path,
            candidates,
            sink.clone(),
        )
    })();

    match result {
        Ok(summary) => {
            let _ = sink.add(FrbIconPackImportEvent::Done(summary));
        }
        Err(error) => {
            let _ = sink.add(FrbIconPackImportEvent::Error(error.into_bridge_error()));
        }
    }
}
