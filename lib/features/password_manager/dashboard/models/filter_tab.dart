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
      case EntityType.note:
      case EntityType.otp:
      case EntityType.bankCard:
      case EntityType.file:
      case EntityType.document:
      case EntityType.contact:
      case EntityType.apiKey:
      case EntityType.sshKey:
      case EntityType.certificate:
      case EntityType.cryptoWallet:
      case EntityType.wifi:
      case EntityType.identity:
      case EntityType.licenseKey:
      case EntityType.recoveryCodes:
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
