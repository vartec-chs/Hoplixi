import 'dart:convert';

import 'package:hoplixi/vault_db/core/scheme/tables/system/store/store_settings.dart';

abstract interface class StoreSettingCodec<T> {
  String encode(T value);
  T decode(String raw);
}

final class IntStoreSettingCodec implements StoreSettingCodec<int> {
  const IntStoreSettingCodec();

  @override
  String encode(int value) => value.toString();

  @override
  int decode(String raw) => int.parse(raw);
}

final class BoolStoreSettingCodec implements StoreSettingCodec<bool> {
  const BoolStoreSettingCodec();

  @override
  String encode(bool value) => value ? '1' : '0';

  @override
  bool decode(String raw) {
    return raw == '1' || raw.toLowerCase() == 'true';
  }
}

final class StringStoreSettingCodec implements StoreSettingCodec<String> {
  const StringStoreSettingCodec();

  @override
  String encode(String value) => value;

  @override
  String decode(String raw) => raw;
}

final class StringListStoreSettingCodec
    implements StoreSettingCodec<List<String>> {
  const StringListStoreSettingCodec();

  @override
  String encode(List<String> value) {
    return value.map((e) => e.trim()).where((e) => e.isNotEmpty).join(',');
  }

  @override
  List<String> decode(String raw) {
    if (raw.trim().isEmpty) return const [];

    return raw
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }
}

sealed class StoreSettingsKey<T> {
  const StoreSettingsKey({
    required this.storageKey,
    required this.defaultValue,
    required this.valueType,
    required this.codec,
  });

  final String storageKey;
  final T defaultValue;
  final StoreSettingValueType valueType;
  final StoreSettingCodec<T> codec;

  static const historyLimit = IntStoreSettingsKey(
    storageKey: 'history_limit',
    defaultValue: 100,
  );

  static const historyMaxAgeDays = IntStoreSettingsKey(
    storageKey: 'history_max_age_days',
    defaultValue: 30,
  );

  static const historyEnabled = BoolStoreSettingsKey(
    storageKey: 'history_enabled',
    defaultValue: true,
  );

  static const historyCleanupIntervalDays = IntStoreSettingsKey(
    storageKey: 'history_cleanup_interval_days',
    defaultValue: 7,
  );

  static const historyLastCleanupTimestamp = IntStoreSettingsKey(
    storageKey: 'history_last_cleanup_timestamp',
    defaultValue: 0,
  );

  static const incrementUsageOnCopy = BoolStoreSettingsKey(
    storageKey: 'increment_usage_on_copy',
    defaultValue: true,
  );

  static const pinnedEntityTypes = StringListStoreSettingsKey(
    storageKey: 'pinned_entity_types',
    defaultValue: [],
  );

  static const List<StoreSettingsKey<dynamic>> values = [
    historyLimit,
    historyMaxAgeDays,
    historyEnabled,
    historyCleanupIntervalDays,
    historyLastCleanupTimestamp,
    incrementUsageOnCopy,
    pinnedEntityTypes,
  ];

  static StoreSettingsKey<dynamic>? fromStorageKey(String value) {
    for (final key in values) {
      if (key.storageKey == value) return key;
    }
    return null;
  }
}

final class IntStoreSettingsKey extends StoreSettingsKey<int> {
  const IntStoreSettingsKey({
    required super.storageKey,
    required super.defaultValue,
  }) : super(
         valueType: StoreSettingValueType.int,
         codec: const IntStoreSettingCodec(),
       );
}

final class BoolStoreSettingsKey extends StoreSettingsKey<bool> {
  const BoolStoreSettingsKey({
    required super.storageKey,
    required super.defaultValue,
  }) : super(
         valueType: StoreSettingValueType.bool,
         codec: const BoolStoreSettingCodec(),
       );
}

final class StringStoreSettingsKey extends StoreSettingsKey<String> {
  const StringStoreSettingsKey({
    required super.storageKey,
    required super.defaultValue,
  }) : super(
         valueType: StoreSettingValueType.string,
         codec: const StringStoreSettingCodec(),
       );
}

final class StringListStoreSettingsKey extends StoreSettingsKey<List<String>> {
  const StringListStoreSettingsKey({
    required super.storageKey,
    required super.defaultValue,
  }) : super(
         valueType: StoreSettingValueType.list,
         codec: const StringListStoreSettingCodec(),
       );
}

final class DoubleStoreSettingCodec implements StoreSettingCodec<double> {
  const DoubleStoreSettingCodec();

  @override
  String encode(double value) => value.toString();

  @override
  double decode(String raw) => double.parse(raw);
}

final class DoubleStoreSettingsKey extends StoreSettingsKey<double> {
  const DoubleStoreSettingsKey({
    required super.storageKey,
    required super.defaultValue,
  }) : super(
         valueType: StoreSettingValueType.double,
         codec: const DoubleStoreSettingCodec(),
       );
}

final class JsonStoreSettingCodec<T> implements StoreSettingCodec<T> {
  const JsonStoreSettingCodec({required this.fromJson, required this.toJson});

  final T Function(Object? json) fromJson;
  final Object? Function(T value) toJson;

  @override
  String encode(T value) {
    return jsonEncode(toJson(value));
  }

  @override
  T decode(String raw) {
    return fromJson(jsonDecode(raw));
  }
}

final class JsonStoreSettingsKey<T> extends StoreSettingsKey<T> {
  const JsonStoreSettingsKey({
    required super.storageKey,
    required super.defaultValue,
    required JsonStoreSettingCodec<T> codec,
  }) : super(valueType: StoreSettingValueType.json, codec: codec);
}
