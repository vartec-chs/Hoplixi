use anyhow::anyhow;

use super::constants::ERROR_PREFIX;
use super::types::FrbIconPackError;

#[derive(Debug, Clone)]
pub(super) struct CatalogError {
    pub(super) code: IconPackCatalogErrorCode,
    pub(super) message: String,
}

impl CatalogError {
    pub(super) fn new(code: IconPackCatalogErrorCode, message: impl Into<String>) -> Self {
        Self {
            code,
            message: message.into(),
        }
    }

    pub(super) fn into_anyhow(self) -> anyhow::Error {
        anyhow!(format!(
            "{ERROR_PREFIX}[{}]: {}",
            self.code.as_str(),
            self.message
        ))
    }

    pub(super) fn into_bridge_error(self) -> FrbIconPackError {
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
pub(super) enum IconPackCatalogErrorCode {
    DuplicatePack,
    ImportFailed,
    InvalidArchive,
    InvalidDirectory,
    InvalidPackName,
    NoSvgFiles,
    PackNotFound,
}

impl IconPackCatalogErrorCode {
    pub(super) fn as_str(self) -> &'static str {
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

pub(super) fn pack_error(
    code: IconPackCatalogErrorCode,
    message: impl Into<String>,
) -> CatalogError {
    CatalogError::new(code, message)
}
