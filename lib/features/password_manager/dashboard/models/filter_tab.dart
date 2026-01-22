import 'package:flutter/material.dart';

import 'entity_type.dart';

enum FilterTab {
  all('Все', Icons.list, 'all'),
  favorites('Избранные', Icons.star, 'favorites'),
  frequent('Часто используемые', Icons.access_time, 'frequent'),
  archived('Архив', Icons.archive, 'archived'),
  delete('Удаленные', Icons.delete, 'delete');

  final String label;
  final IconData icon;
  final String id;

  const FilterTab(this.label, this.icon, this.id);

  /// Получить доступные вкладки для типа сущности
  static List<FilterTab> getAvailableTabsForEntity(EntityType entityType) {
    switch (entityType) {
      case EntityType.password:
        return [
          FilterTab.all,
          FilterTab.favorites,
          FilterTab.frequent,
          FilterTab.archived,
          FilterTab.delete,
        ];
      case EntityType.note:
        return [
          FilterTab.all,
          FilterTab.favorites,
          FilterTab.frequent,
          FilterTab.archived,
          FilterTab.delete,
        ];
      case EntityType.otp:
        return [
          FilterTab.all,
          FilterTab.favorites,
          FilterTab.frequent,
          FilterTab.archived,
          FilterTab.delete,
        ];
      case EntityType.bankCard:
        return [
          FilterTab.all,
          FilterTab.favorites,
          FilterTab.frequent,
          FilterTab.archived,
          FilterTab.delete,
        ];
      case EntityType.file:
        return [
          FilterTab.all,
          FilterTab.favorites,
          FilterTab.frequent,
          FilterTab.archived,
          FilterTab.delete,
        ];
      case EntityType.document:
        return [
          FilterTab.all,
          FilterTab.favorites,
          FilterTab.frequent,
          FilterTab.archived,
          FilterTab.delete,
        ];
    }
  }
}
