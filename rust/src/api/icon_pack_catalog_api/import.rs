use std::fs;
use std::path::{Path, PathBuf};
use std::sync::Arc;
use std::time::{Duration, Instant};

use archive::{ArchiveExtractor, ArchiveFormat};
use chrono::Utc;

use crate::frb_generated::StreamSink;

use super::constants::{
    ICONS_FOLDER_NAME, INDEX_FILE_NAME, MANIFEST_FILE_NAME, STAGING_FOLDER_NAME,
};
use super::errors::{CatalogError, IconPackCatalogErrorCode, pack_error};
use super::storage::{
    build_summary_from_fields, delete_directory_if_exists, write_entry_file, write_manifest_file,
};
use super::types::{
    FrbIconPackEntry, FrbIconPackImportEvent, FrbIconPackImportProgress, FrbIconPackSummary,
    ImportCandidate, ImportCandidateSource, ManifestFile, ResolvedPackName,
};
use super::utils::{
    format_millis_to_rfc3339, make_output_file_path, normalize_icon_path_without_extension_impl,
    prepare_pack_name, resolve_root_path,
};

const PROGRESS_EMIT_EVERY_FILES: usize = 25;
const PROGRESS_EMIT_INTERVAL: Duration = Duration::from_millis(120);

struct ImportProgressEmitter {
    last_emit: Option<Instant>,
}

impl ImportProgressEmitter {
    fn new() -> Self {
        Self { last_emit: None }
    }

    fn emit_file_progress(
        &mut self,
        sink: &StreamSink<FrbIconPackImportEvent>,
        current: usize,
        total: i32,
        current_file: String,
    ) {
        let now = Instant::now();
        let elapsed_enough = match self.last_emit {
            Some(last_emit) => now.duration_since(last_emit) >= PROGRESS_EMIT_INTERVAL,
            None => true,
        };
        let should_emit =
            current == 1 || current % PROGRESS_EMIT_EVERY_FILES == 0 || elapsed_enough;

        if !should_emit {
            return;
        }

        self.last_emit = Some(now);
        emit_progress(sink, current as i32, total, current_file);
    }
}

fn emit_progress(
    sink: &StreamSink<FrbIconPackImportEvent>,
    current: i32,
    total: i32,
    current_file: String,
) {
    let _ = sink.add(FrbIconPackImportEvent::Progress(
        FrbIconPackImportProgress {
            current,
            total,
            current_file,
        },
    ));
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
        let mut progress = ImportProgressEmitter::new();

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

            progress.emit_file_progress(&sink, index + 1, total, relative_path);
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

        emit_progress(&sink, total, total, "Завершение импорта".to_owned());

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

/// Import a ZIP or 7Z archive and emit progress events while unpacking SVG files.
pub(super) async fn import_pack(
    root_path: String,
    archive_path: String,
    display_name: String,
    sink: StreamSink<FrbIconPackImportEvent>,
) {
    let sink = Arc::new(sink);
    let import_sink = Arc::clone(&sink);
    let result =
        tokio::task::spawn_blocking(move || -> Result<FrbIconPackSummary, CatalogError> {
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
                import_sink,
            )
        })
        .await
        .unwrap_or_else(|error| {
            Err(pack_error(
                IconPackCatalogErrorCode::ImportFailed,
                format!("Фоновая задача импорта пака завершилась ошибкой: {error}"),
            ))
        });

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
pub(super) async fn import_directory(
    root_path: String,
    directory_path: String,
    display_name: String,
    sink: StreamSink<FrbIconPackImportEvent>,
) {
    let sink = Arc::new(sink);
    let import_sink = Arc::clone(&sink);
    let result =
        tokio::task::spawn_blocking(move || -> Result<FrbIconPackSummary, CatalogError> {
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
                import_sink,
            )
        })
        .await
        .unwrap_or_else(|error| {
            Err(pack_error(
                IconPackCatalogErrorCode::ImportFailed,
                format!("Фоновая задача импорта папки завершилась ошибкой: {error}"),
            ))
        });

    match result {
        Ok(summary) => {
            let _ = sink.add(FrbIconPackImportEvent::Done(summary));
        }
        Err(error) => {
            let _ = sink.add(FrbIconPackImportEvent::Error(error.into_bridge_error()));
        }
    }
}
