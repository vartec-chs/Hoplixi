use std::path::PathBuf;

use serde::{Deserialize, Serialize};

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

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub(super) struct ManifestFile {
    pub(super) pack_key: String,
    pub(super) display_name: String,
    pub(super) source_archive_name: String,
    pub(super) imported_at: String,
    pub(super) icon_count: i32,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub(super) struct EntryFile {
    pub(super) key: String,
    pub(super) pack_key: String,
    pub(super) pack_name: String,
    pub(super) icon_key: String,
    pub(super) name: String,
    pub(super) relative_path: String,
    pub(super) svg_path: String,
    pub(super) imported_at: String,
}

#[derive(Debug, Clone)]
pub(super) enum ImportCandidateSource {
    Archive(Vec<u8>),
    Directory(PathBuf),
}

#[derive(Debug, Clone)]
pub(super) struct ImportCandidate {
    pub(super) relative_path: String,
    pub(super) source: ImportCandidateSource,
}

#[derive(Debug, Clone)]
pub(super) struct ResolvedPackName {
    pub(super) display_name: String,
    pub(super) pack_key: String,
}
