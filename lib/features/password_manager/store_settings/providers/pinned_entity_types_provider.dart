import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/password_manager/dashboard/dashboard.dart';
import 'package:hoplixi/vault_db/core/config/store_settings_keys.dart';
import 'package:hoplixi/vault_db/providers/providers.dart';

/// Возвращает список закреплённых типов сущностей для отображения в
/// [EntityTypeCompactDropdown]. Если настройка не задана — возвращает все типы.
final pinnedEntityTypesProvider = FutureProvider<List<EntityType>>((ref) async {
  final repos = await ref.watch(vaultRepositories.future);
  final storeSettings = repos.storeSettings;

  final result = await storeSettings.getOrDefault(
    StoreSettingsKey.pinnedEntityTypes,
  );

  final ids = result.getOrElse(
    (_) => StoreSettingsKey.pinnedEntityTypes.defaultValue,
  );

  if (ids.isEmpty) {
    return EntityType.values;
  }

  final types = ids
      .map((id) => EntityType.fromId(id))
      .whereType<EntityType>()
      .toList();

  return types.isEmpty ? EntityType.values : types;
});
