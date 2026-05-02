use std::fs::File;
use std::path::PathBuf;

use anyhow::{Context, bail};
use chrono::NaiveDateTime;
use keepass::config::{
    CompressionConfig, DatabaseVersion, InnerCipherConfig, KdfConfig, OuterCipherConfig,
};
use keepass::db::{
    self, AttachmentRef, AutoType, AutoTypeAssociation, CustomDataItem, CustomDataValue, EntryRef,
    GroupRef, Icon, Times, Value, fields,
};
use keepass::{Database, DatabaseKey};

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
    tokio::task::spawn_blocking(move || export_keepass_database_blocking(opts))
        .await
        .context("export_keepass_database task join failed")?
}

fn export_keepass_database_blocking(
    opts: FrbKeepassExportOptions,
) -> anyhow::Result<FrbKeepassDatabaseExport> {
    let input_path = PathBuf::from(&opts.input_path);
    let mut source = File::open(&input_path)
        .with_context(|| format!("failed to open KeePass database: {}", input_path.display()))?;

    let key = build_database_key(&opts)?;
    let db = Database::open(&mut source, key).context("failed to open KeePass database")?;

    let mut groups = Vec::new();
    let mut entries = Vec::new();
    flatten_group(
        db.root(),
        None,
        String::new(),
        true,
        &opts,
        &mut groups,
        &mut entries,
    );

    let deleted_objects = db
        .deleted_objects
        .iter()
        .map(|(uuid, deletion_time)| FrbKeepassDeletedObject {
            uuid: uuid.to_string(),
            deletion_time: format_time(*deletion_time),
        })
        .collect();

    Ok(FrbKeepassDatabaseExport {
        source_path: opts.input_path,
        config: export_config(&db.config),
        meta: export_meta(&db.meta),
        root_group_uuid: db.root().id().to_string(),
        groups,
        entries,
        deleted_objects,
    })
}

fn build_database_key(opts: &FrbKeepassExportOptions) -> anyhow::Result<DatabaseKey> {
    let mut key = DatabaseKey::new();
    let mut has_component = false;

    if let Some(password) = opts.password.as_deref() {
        if !password.is_empty() {
            key = key.with_password(password);
            has_component = true;
        }
    }

    if let Some(keyfile_path) = opts.keyfile_path.as_deref() {
        let mut keyfile = File::open(keyfile_path)
            .with_context(|| format!("failed to open KeePass keyfile: {keyfile_path}"))?;
        key = key
            .with_keyfile(&mut keyfile)
            .with_context(|| format!("failed to read KeePass keyfile: {keyfile_path}"))?;
        has_component = true;
    }

    if !has_component {
        bail!("KeePass export requires a password and/or a keyfile");
    }

    Ok(key)
}

fn flatten_group(
    group: GroupRef<'_>,
    parent_uuid: Option<String>,
    path: String,
    is_root: bool,
    opts: &FrbKeepassExportOptions,
    groups_out: &mut Vec<FrbKeepassGroup>,
    entries_out: &mut Vec<FrbKeepassEntry>,
) {
    let group_uuid = group.id().to_string();
    let (icon_id, custom_icon_uuid) = export_icon(
        group.icon(),
        group
            .custom_icon()
            .as_ref()
            .map(|icon| icon.id().to_string()),
    );

    groups_out.push(FrbKeepassGroup {
        uuid: group_uuid.clone(),
        parent_uuid,
        is_root,
        path: path.clone(),
        name: group.name.clone(),
        notes: group.notes.clone(),
        icon_id,
        custom_icon_uuid,
        times: export_times(&group.times),
        custom_data: export_custom_data_map(&group.custom_data),
        is_expanded: group.is_expanded,
        default_autotype_sequence: group.default_autotype_sequence.clone(),
        enable_autotype: group.enable_autotype,
        enable_searching: group.enable_searching,
        last_top_visible_entry: None,
    });

    for entry in group.entries() {
        entries_out.push(export_entry(entry, &group_uuid, &path, opts));
    }

    for child in group.groups() {
        let child_path = if path.is_empty() {
            child.name.clone()
        } else {
            format!("{path}/{}", child.name)
        };

        flatten_group(
            child,
            Some(group_uuid.clone()),
            child_path,
            false,
            opts,
            groups_out,
            entries_out,
        );
    }
}

fn export_icon(
    icon: Option<&Icon>,
    custom_icon_uuid: Option<String>,
) -> (Option<u32>, Option<String>) {
    match icon {
        Some(Icon::BuiltIn(id)) => (u32::try_from(*id).ok(), None),
        Some(Icon::Custom(_)) => (None, custom_icon_uuid),
        None => (None, None),
    }
}

fn export_entry(
    entry: EntryRef<'_>,
    group_uuid: &str,
    group_path: &str,
    opts: &FrbKeepassExportOptions,
) -> FrbKeepassEntry {
    let history = if opts.include_history {
        entry
            .history
            .as_ref()
            .map(|history| {
                (0..history.get_entries().len())
                    .filter_map(|index| entry.historical(index))
                    .map(|snapshot| export_history_entry(snapshot, opts))
                    .collect()
            })
            .unwrap_or_default()
    } else {
        Vec::new()
    };

    let (icon_id, custom_icon_uuid, custom_icon_data) = export_entry_icon(&entry);

    FrbKeepassEntry {
        uuid: entry.id().to_string(),
        group_uuid: group_uuid.to_string(),
        group_path: group_path.to_string(),
        title: entry.get(fields::TITLE).map(ToOwned::to_owned),
        username: entry.get(fields::USERNAME).map(ToOwned::to_owned),
        password: entry.get(fields::PASSWORD).map(ToOwned::to_owned),
        url: entry.get(fields::URL).map(ToOwned::to_owned),
        notes: entry.get(fields::NOTES).map(ToOwned::to_owned),
        tags: entry.tags.clone(),
        fields: export_fields(&entry.fields),
        times: export_times(&entry.times),
        custom_data: export_custom_data_map(&entry.custom_data),
        icon_id,
        custom_icon_uuid,
        custom_icon_data,
        foreground_color: entry.foreground_color.as_ref().map(ToString::to_string),
        background_color: entry.background_color.as_ref().map(ToString::to_string),
        override_url: entry.override_url.clone(),
        quality_check: entry.quality_check,
        attachments: export_attachments(entry.attachments(), opts.include_attachments),
        autotype: entry.autotype.as_ref().map(export_autotype),
        otp: export_otp(&entry),
        history,
    }
}

fn export_history_entry(
    entry: EntryRef<'_>,
    opts: &FrbKeepassExportOptions,
) -> FrbKeepassHistoryEntry {
    let (icon_id, custom_icon_uuid, custom_icon_data) = export_entry_icon(&entry);

    FrbKeepassHistoryEntry {
        uuid: entry.id().to_string(),
        title: entry.get(fields::TITLE).map(ToOwned::to_owned),
        username: entry.get(fields::USERNAME).map(ToOwned::to_owned),
        password: entry.get(fields::PASSWORD).map(ToOwned::to_owned),
        url: entry.get(fields::URL).map(ToOwned::to_owned),
        notes: entry.get(fields::NOTES).map(ToOwned::to_owned),
        tags: entry.tags.clone(),
        fields: export_fields(&entry.fields),
        times: export_times(&entry.times),
        custom_data: export_custom_data_map(&entry.custom_data),
        icon_id,
        custom_icon_uuid,
        custom_icon_data,
        foreground_color: entry.foreground_color.as_ref().map(ToString::to_string),
        background_color: entry.background_color.as_ref().map(ToString::to_string),
        override_url: entry.override_url.clone(),
        quality_check: entry.quality_check,
        attachments: export_attachments(entry.attachments(), opts.include_attachments),
        autotype: entry.autotype.as_ref().map(export_autotype),
        otp: export_otp(&entry),
    }
}

fn export_entry_icon(entry: &EntryRef<'_>) -> (Option<u32>, Option<String>, Option<Vec<u8>>) {
    let custom_icon = entry.custom_icon();
    let custom_icon_uuid = custom_icon.as_ref().map(|icon| icon.id().to_string());
    let custom_icon_data = custom_icon.as_ref().map(|icon| icon.data.clone());
    let (icon_id, custom_icon_uuid) = export_icon(entry.icon(), custom_icon_uuid);

    (icon_id, custom_icon_uuid, custom_icon_data)
}

fn export_fields(
    fields_map: &std::collections::HashMap<String, Value<String>>,
) -> Vec<FrbKeepassField> {
    let mut fields = fields_map
        .iter()
        .map(|(key, value)| FrbKeepassField {
            key: key.clone(),
            value: value.get().to_owned(),
            protected: value.is_protected(),
        })
        .collect::<Vec<_>>();
    fields.sort_by(|a, b| a.key.cmp(&b.key));
    fields
}

fn export_custom_data_map(
    custom_data: &std::collections::HashMap<String, CustomDataItem>,
) -> Vec<FrbKeepassCustomDataItem> {
    let mut items = custom_data
        .iter()
        .map(|(key, item)| export_custom_data_item(key, item))
        .collect::<Vec<_>>();
    items.sort_by(|a, b| a.key.cmp(&b.key));
    items
}

fn export_custom_data_item(key: &str, item: &CustomDataItem) -> FrbKeepassCustomDataItem {
    let (value_kind, string_value, binary_value) = match item.value.as_ref() {
        Some(CustomDataValue::String(value)) => ("string".to_string(), Some(value.clone()), None),
        Some(CustomDataValue::Binary(value)) => ("binary".to_string(), None, Some(value.clone())),
        None => ("empty".to_string(), None, None),
    };

    FrbKeepassCustomDataItem {
        key: key.to_string(),
        value_kind,
        string_value,
        binary_value,
        last_modification_time: format_time(item.last_modification_time),
    }
}

fn export_attachments<'a>(
    attachments: impl Iterator<Item = AttachmentRef<'a>>,
    include_data: bool,
) -> Vec<FrbKeepassAttachment> {
    let mut items = attachments
        .map(|attachment| {
            let bytes = attachment.data.get();
            FrbKeepassAttachment {
                key: attachment.id().to_string(),
                size: u64::try_from(bytes.len()).unwrap_or(u64::MAX),
                protected: attachment.data.is_protected(),
                data: if include_data {
                    bytes.clone()
                } else {
                    Vec::new()
                },
            }
        })
        .collect::<Vec<_>>();
    items.sort_by(|a, b| a.key.cmp(&b.key));
    items
}

fn export_autotype(autotype: &AutoType) -> FrbKeepassAutoType {
    FrbKeepassAutoType {
        enabled: autotype.enabled,
        default_sequence: autotype.default_sequence.clone(),
        data_transfer_obfuscation: autotype.data_transfer_obfuscation,
        associations: autotype
            .associations
            .iter()
            .map(export_autotype_association)
            .collect(),
    }
}

fn export_autotype_association(association: &AutoTypeAssociation) -> FrbKeepassAutoTypeAssociation {
    FrbKeepassAutoTypeAssociation {
        window: association.window.clone(),
        sequence: association.sequence.clone(),
    }
}

fn export_otp(entry: &EntryRef<'_>) -> Option<FrbKeepassOtp> {
    let raw_value = entry.get_raw_otp_value()?.to_string();

    match entry.get_otp() {
        Ok(otp) => Some(FrbKeepassOtp {
            raw_value,
            label: Some(otp.label.clone()),
            issuer: otp.issuer.clone(),
            secret: Some(otp.get_secret()),
            period: Some(otp.period),
            digits: Some(otp.digits),
            algorithm: Some(format!("{:?}", &otp.algorithm)),
            parse_error: None,
        }),
        Err(error) => Some(FrbKeepassOtp {
            raw_value,
            label: None,
            issuer: None,
            secret: None,
            period: None,
            digits: None,
            algorithm: None,
            parse_error: Some(error.to_string()),
        }),
    }
}

fn export_times(times: &Times) -> FrbKeepassTimes {
    FrbKeepassTimes {
        creation: format_time(times.creation),
        last_modification: format_time(times.last_modification),
        last_access: format_time(times.last_access),
        expiry: format_time(times.expiry),
        location_changed: format_time(times.location_changed),
        expires: times.expires,
        usage_count: times.usage_count.and_then(|v| u32::try_from(v).ok()),
    }
}

fn export_meta(meta: &db::Meta) -> FrbKeepassMeta {
    FrbKeepassMeta {
        generator: meta.generator.clone(),
        database_name: meta.database_name.clone(),
        database_name_changed: format_time(meta.database_name_changed),
        database_description: meta.database_description.clone(),
        database_description_changed: format_time(meta.database_description_changed),
        default_username: meta.default_username.clone(),
        default_username_changed: format_time(meta.default_username_changed),
        maintenance_history_days: meta
            .maintenance_history_days
            .and_then(|v| u32::try_from(v).ok()),
        color: meta.color.as_ref().map(ToString::to_string),
        master_key_changed: format_time(meta.master_key_changed),
        master_key_change_rec: meta
            .master_key_change_rec
            .and_then(|v| i32::try_from(v).ok()),
        master_key_change_force: meta
            .master_key_change_force
            .and_then(|v| i32::try_from(v).ok()),
        memory_protection: meta
            .memory_protection
            .as_ref()
            .map(|mp| FrbKeepassMemoryProtection {
                protect_title: mp.protect_title,
                protect_username: mp.protect_username,
                protect_password: mp.protect_password,
                protect_url: mp.protect_url,
                protect_notes: mp.protect_notes,
            }),
        recyclebin_enabled: meta.recyclebin_enabled,
        recyclebin_uuid: meta.recyclebin_uuid.map(|uuid| uuid.to_string()),
        recyclebin_changed: format_time(meta.recyclebin_changed),
        entry_templates_group: meta.entry_templates_group.map(|uuid| uuid.to_string()),
        entry_templates_group_changed: format_time(meta.entry_templates_group_changed),
        last_selected_group: meta.last_selected_group.map(|uuid| uuid.to_string()),
        last_top_visible_group: meta.last_top_visible_group.map(|uuid| uuid.to_string()),
        history_max_items: meta.history_max_items.and_then(|v| i32::try_from(v).ok()),
        history_max_size: meta.history_max_size.and_then(|v| i32::try_from(v).ok()),
        settings_changed: format_time(meta.settings_changed),
        custom_data: export_custom_data_map(&meta.custom_data),
    }
}

fn export_config(config: &keepass::config::DatabaseConfig) -> FrbKeepassConfig {
    let (kdf_name, kdf_description) = match &config.kdf_config {
        KdfConfig::Aes { rounds } => ("AES-KDF".to_string(), format!("rounds={rounds}")),
        KdfConfig::Argon2 {
            iterations,
            memory,
            parallelism,
            version,
        } => (
            "Argon2".to_string(),
            format!(
                "variant=d iterations={iterations} memory={memory} parallelism={parallelism} version={:?}",
                version
            ),
        ),
        KdfConfig::Argon2id {
            iterations,
            memory,
            parallelism,
            version,
        } => (
            "Argon2id".to_string(),
            format!(
                "iterations={iterations} memory={memory} parallelism={parallelism} version={:?}",
                version
            ),
        ),
        _ => ("Unknown".to_string(), format!("{:?}", &config.kdf_config)),
    };

    FrbKeepassConfig {
        database_version: export_database_version(&config.version),
        outer_cipher: export_outer_cipher(&config.outer_cipher_config),
        inner_cipher: export_inner_cipher(&config.inner_cipher_config),
        compression: export_compression(&config.compression_config),
        kdf_name,
        kdf_description,
    }
}

fn export_database_version(version: &DatabaseVersion) -> String {
    match version {
        DatabaseVersion::KDB(minor) => format!("KDB.{minor}"),
        DatabaseVersion::KDB2(minor) => format!("KDBX2.{minor}"),
        DatabaseVersion::KDB3(minor) => format!("KDBX3.{minor}"),
        DatabaseVersion::KDB4(minor) => format!("KDBX4.{minor}"),
    }
}

fn export_outer_cipher(cipher: &OuterCipherConfig) -> String {
    match cipher {
        OuterCipherConfig::AES256 => "AES256".to_string(),
        OuterCipherConfig::Twofish => "Twofish".to_string(),
        OuterCipherConfig::ChaCha20 => "ChaCha20".to_string(),
        _ => format!("{cipher:?}"),
    }
}

fn export_inner_cipher(cipher: &InnerCipherConfig) -> String {
    match cipher {
        InnerCipherConfig::Plain => "Plain".to_string(),
        InnerCipherConfig::Salsa20 => "Salsa20".to_string(),
        InnerCipherConfig::ChaCha20 => "ChaCha20".to_string(),
        _ => format!("{cipher:?}"),
    }
}

fn export_compression(config: &CompressionConfig) -> String {
    match config {
        CompressionConfig::None => "None".to_string(),
        CompressionConfig::GZip => "GZip".to_string(),
        _ => format!("{config:?}"),
    }
}

fn format_time(value: Option<NaiveDateTime>) -> Option<String> {
    value.map(|dt: NaiveDateTime| dt.format("%Y-%m-%dT%H:%M:%S").to_string())
}

#[cfg(test)]
mod tests {
    use super::{FrbKeepassExportOptions, export_entry, flatten_group};
    use keepass::{Database, db::fields};

    #[test]
    fn export_entry_preserves_protected_field_flags() {
        let mut db = Database::new();
        let entry_id = db
            .root_mut()
            .add_entry()
            .edit(|entry| {
                entry.set_unprotected(fields::TITLE, "Example");
                entry.set_protected(fields::PASSWORD, "secret");
            })
            .id();

        let exported = export_entry(
            db.entry(entry_id).expect("entry"),
            "group-uuid",
            "General",
            &FrbKeepassExportOptions::simple("db.kdbx".to_string(), "pass".to_string()),
        );

        let title = exported
            .fields
            .iter()
            .find(|field| field.key == fields::TITLE)
            .expect("title field");
        let password = exported
            .fields
            .iter()
            .find(|field| field.key == fields::PASSWORD)
            .expect("password field");

        assert!(!title.protected);
        assert!(password.protected);
        assert_eq!(password.value, "secret");
    }

    #[test]
    fn flatten_group_builds_relative_paths() {
        let mut db = Database::new();
        let general_id = db
            .root_mut()
            .add_group()
            .edit(|group| group.name = "General".to_string())
            .id();

        db.group_mut(general_id)
            .expect("general group")
            .add_group()
            .edit(|group| group.name = "Work".to_string());

        db.group_mut(general_id)
            .expect("general group")
            .add_entry()
            .edit(|entry| {
                entry.set_unprotected(fields::TITLE, "Entry");
            });

        let mut groups = Vec::new();
        let mut entries = Vec::new();
        flatten_group(
            db.root(),
            None,
            String::new(),
            true,
            &FrbKeepassExportOptions::simple("db.kdbx".to_string(), "pass".to_string()),
            &mut groups,
            &mut entries,
        );

        assert!(
            groups
                .iter()
                .any(|group| group.is_root && group.path.is_empty())
        );
        assert!(
            groups
                .iter()
                .any(|group| group.name == "General" && group.path == "General")
        );
        assert!(
            groups
                .iter()
                .any(|group| group.name == "Work" && group.path == "General/Work")
        );
        assert!(entries.iter().any(|entry| entry.group_path == "General"));
    }
}
