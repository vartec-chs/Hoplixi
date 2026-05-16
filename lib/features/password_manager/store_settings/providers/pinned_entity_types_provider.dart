import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/password_manager/dashboard/dashboard.dart';
import 'package:hoplixi/main_db/core/config/store_settings_keys.dart';
import 'package:hoplixi/main_db/providers/other/dao_providers.dart';

/// Возвращает список закреплённых типов сущностей для отображения в
/// [EntityTypeCompactDropdown]. Если настройка не задана — возвращает все типы.
final pinnedEntityTypesProvider = FutureProvider<List<EntityType>>((ref) async {
  final dao = await ref.watch(storeSettingsDaoProvider.future);

  final raw = await dao.getSetting(StoreSettingsKeys.pinnedEntityTypes);
  if (raw == null || raw.isEmpty) {
    return EntityType.values;
  }

  try {
    final ids = (jsonDecode(raw) as List).cast<String>();
    if (ids.isEmpty) return EntityType.values;

    final types = ids
        .map((id) => EntityType.fromId(id))
        .whereType<EntityType>()
        .toList();

    return types.isEmpty ? EntityType.values : types;
  } catch (_) {
    return EntityType.values;
  }
});
