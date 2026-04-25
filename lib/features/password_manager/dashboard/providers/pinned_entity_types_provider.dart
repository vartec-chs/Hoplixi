import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/main_db/old/models/store_settings_keys.dart';
import 'package:hoplixi/main_db/old/provider/dao_providers.dart';

/// Возвращает список закреплённых типов сущностей для отображения в
/// [EntityTypeCompactDropdown]. Если настройка не задана — возвращает все типы.
final pinnedEntityTypesProvider = FutureProvider<List<EntityType>>((ref) async {
  final dao = await ref.watch(storeSettingsDaoProvider.future);

  final raw = await dao.getSetting(StoreSettingsKeys.pinnedEntityTypes);
  if (raw == null || raw.isEmpty) {
    return EntityType.allTypes;
  }

  try {
    final ids = (jsonDecode(raw) as List).cast<String>();
    if (ids.isEmpty) return EntityType.allTypes;

    final types = ids
        .map((id) => EntityType.fromId(id))
        .whereType<EntityType>()
        .toList();

    return types.isEmpty ? EntityType.allTypes : types;
  } catch (_) {
    return EntityType.allTypes;
  }
});
