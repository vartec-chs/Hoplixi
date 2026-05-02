/// Options for exporting a KeePass database into a normalized structure that is
/// convenient to import into the app storage layer.
#[derive(Debug, Clone)]
pub struct FrbKeepassExportOptions {
    /// Path to the KeePass database (`.kdbx` / `.kdb`).
    pub input_path: String,
    /// Optional database password. Keep empty if the database uses only a keyfile.
    pub password: Option<String>,
    /// Optional path to the KeePass keyfile.
    pub keyfile_path: Option<String>,
    /// Include entry history snapshots.
    pub include_history: bool,
    /// Include attachment bytes in the export.
    pub include_attachments: bool,
}

/// Fully normalized KeePass export that preserves most information needed for
/// later import into the application storage.
#[derive(Debug, Clone)]
pub struct FrbKeepassDatabaseExport {
    pub source_path: String,
    pub config: FrbKeepassConfig,
    pub meta: FrbKeepassMeta,
    pub root_group_uuid: String,
    pub groups: Vec<FrbKeepassGroup>,
    pub entries: Vec<FrbKeepassEntry>,
    pub deleted_objects: Vec<FrbKeepassDeletedObject>,
}

#[derive(Debug, Clone)]
pub struct FrbKeepassConfig {
    pub database_version: String,
    pub outer_cipher: String,
    pub inner_cipher: String,
    pub compression: String,
    pub kdf_name: String,
    pub kdf_description: String,
}

#[derive(Debug, Clone)]
pub struct FrbKeepassMeta {
    pub generator: Option<String>,
    pub database_name: Option<String>,
    pub database_name_changed: Option<String>,
    pub database_description: Option<String>,
    pub database_description_changed: Option<String>,
    pub default_username: Option<String>,
    pub default_username_changed: Option<String>,
    pub maintenance_history_days: Option<u32>,
    pub color: Option<String>,
    pub master_key_changed: Option<String>,
    pub master_key_change_rec: Option<i32>,
    pub master_key_change_force: Option<i32>,
    pub memory_protection: Option<FrbKeepassMemoryProtection>,
    pub recyclebin_enabled: Option<bool>,
    pub recyclebin_uuid: Option<String>,
    pub recyclebin_changed: Option<String>,
    pub entry_templates_group: Option<String>,
    pub entry_templates_group_changed: Option<String>,
    pub last_selected_group: Option<String>,
    pub last_top_visible_group: Option<String>,
    pub history_max_items: Option<i32>,
    pub history_max_size: Option<i32>,
    pub settings_changed: Option<String>,
    pub custom_data: Vec<FrbKeepassCustomDataItem>,
}

#[derive(Debug, Clone)]
pub struct FrbKeepassMemoryProtection {
    pub protect_title: bool,
    pub protect_username: bool,
    pub protect_password: bool,
    pub protect_url: bool,
    pub protect_notes: bool,
}

#[derive(Debug, Clone)]
pub struct FrbKeepassDeletedObject {
    pub uuid: String,
    pub deletion_time: Option<String>,
}

#[derive(Debug, Clone)]
pub struct FrbKeepassGroup {
    pub uuid: String,
    pub parent_uuid: Option<String>,
    pub is_root: bool,
    /// Path relative to the synthetic KeePass root group.
    pub path: String,
    pub name: String,
    pub notes: Option<String>,
    pub icon_id: Option<u32>,
    pub custom_icon_uuid: Option<String>,
    pub times: FrbKeepassTimes,
    pub custom_data: Vec<FrbKeepassCustomDataItem>,
    pub is_expanded: bool,
    pub default_autotype_sequence: Option<String>,
    pub enable_autotype: Option<bool>,
    pub enable_searching: Option<bool>,
    pub last_top_visible_entry: Option<String>,
}

#[derive(Debug, Clone)]
pub struct FrbKeepassEntry {
    pub uuid: String,
    pub group_uuid: String,
    /// Group path relative to the synthetic KeePass root group.
    pub group_path: String,
    pub title: Option<String>,
    pub username: Option<String>,
    pub password: Option<String>,
    pub url: Option<String>,
    pub notes: Option<String>,
    pub tags: Vec<String>,
    pub fields: Vec<FrbKeepassField>,
    pub times: FrbKeepassTimes,
    pub custom_data: Vec<FrbKeepassCustomDataItem>,
    pub icon_id: Option<u32>,
    pub custom_icon_uuid: Option<String>,
    pub custom_icon_data: Option<Vec<u8>>,
    pub foreground_color: Option<String>,
    pub background_color: Option<String>,
    pub override_url: Option<String>,
    pub quality_check: Option<bool>,
    pub attachments: Vec<FrbKeepassAttachment>,
    pub autotype: Option<FrbKeepassAutoType>,
    pub otp: Option<FrbKeepassOtp>,
    pub history: Vec<FrbKeepassHistoryEntry>,
}

#[derive(Debug, Clone)]
pub struct FrbKeepassHistoryEntry {
    pub uuid: String,
    pub title: Option<String>,
    pub username: Option<String>,
    pub password: Option<String>,
    pub url: Option<String>,
    pub notes: Option<String>,
    pub tags: Vec<String>,
    pub fields: Vec<FrbKeepassField>,
    pub times: FrbKeepassTimes,
    pub custom_data: Vec<FrbKeepassCustomDataItem>,
    pub icon_id: Option<u32>,
    pub custom_icon_uuid: Option<String>,
    pub custom_icon_data: Option<Vec<u8>>,
    pub foreground_color: Option<String>,
    pub background_color: Option<String>,
    pub override_url: Option<String>,
    pub quality_check: Option<bool>,
    pub attachments: Vec<FrbKeepassAttachment>,
    pub autotype: Option<FrbKeepassAutoType>,
    pub otp: Option<FrbKeepassOtp>,
}

#[derive(Debug, Clone)]
pub struct FrbKeepassField {
    pub key: String,
    pub value: String,
    pub protected: bool,
}

#[derive(Debug, Clone)]
pub struct FrbKeepassAttachment {
    pub key: String,
    pub size: u64,
    pub protected: bool,
    pub data: Vec<u8>,
}

#[derive(Debug, Clone)]
pub struct FrbKeepassCustomDataItem {
    pub key: String,
    pub value_kind: String,
    pub string_value: Option<String>,
    pub binary_value: Option<Vec<u8>>,
    pub last_modification_time: Option<String>,
}

#[derive(Debug, Clone)]
pub struct FrbKeepassTimes {
    pub creation: Option<String>,
    pub last_modification: Option<String>,
    pub last_access: Option<String>,
    pub expiry: Option<String>,
    pub location_changed: Option<String>,
    pub expires: Option<bool>,
    pub usage_count: Option<u32>,
}

#[derive(Debug, Clone)]
pub struct FrbKeepassAutoType {
    pub enabled: bool,
    pub default_sequence: Option<String>,
    pub data_transfer_obfuscation: Option<bool>,
    pub associations: Vec<FrbKeepassAutoTypeAssociation>,
}

#[derive(Debug, Clone)]
pub struct FrbKeepassAutoTypeAssociation {
    pub window: String,
    pub sequence: String,
}

#[derive(Debug, Clone)]
pub struct FrbKeepassOtp {
    pub raw_value: String,
    pub label: Option<String>,
    pub issuer: Option<String>,
    pub secret: Option<String>,
    pub period: Option<u64>,
    pub digits: Option<u32>,
    pub algorithm: Option<String>,
    pub parse_error: Option<String>,
}
