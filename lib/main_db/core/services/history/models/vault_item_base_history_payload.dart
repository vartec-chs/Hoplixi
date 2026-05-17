import '../../../tables/vault_items/vault_events_history.dart';
import '../../../tables/vault_items/vault_items.dart';
import 'history_field_snapshot.dart';

class VaultItemBaseHistoryPayload {
  const VaultItemBaseHistoryPayload({
    required this.historyId,
    required this.itemId,
    required this.type,
    required this.action,
    required this.name,
    this.description,
    this.categoryId,
    this.categoryHistoryId,
    this.iconRefId,
    required this.usedCount,
    required this.isFavorite,
    required this.isArchived,
    required this.isPinned,
    required this.isDeleted,
    required this.createdAt,
    required this.modifiedAt,
    this.lastUsedAt,
    this.archivedAt,
    this.deletedAt,
    this.recentScore,
    required this.historyCreatedAt,
  });

  final String historyId;
  final String itemId;
  final VaultItemType type;
  final VaultEventHistoryAction action;
  final String name;
  final String? description;
  final String? categoryId;
  final String? categoryHistoryId;
  final String? iconRefId;
  final int usedCount;
  final bool isFavorite;
  final bool isArchived;
  final bool isPinned;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime modifiedAt;
  final DateTime? lastUsedAt;
  final DateTime? archivedAt;
  final DateTime? deletedAt;
  final double? recentScore;
  final DateTime historyCreatedAt;

  List<HistoryFieldSnapshot<Object?>> diffFields() {
    return [
      HistoryFieldSnapshot<String>(key: 'name', label: 'Name', value: name),
      HistoryFieldSnapshot<String>(
        key: 'description',
        label: 'Description',
        value: description,
      ),
      HistoryFieldSnapshot<String>(
        key: 'categoryId',
        label: 'Category',
        value: categoryId,
      ),
      HistoryFieldSnapshot<String>(
        key: 'iconRefId',
        label: 'Icon',
        value: iconRefId,
      ),
      HistoryFieldSnapshot<int>(
        key: 'usedCount',
        label: 'Used count',
        value: usedCount,
      ),
      HistoryFieldSnapshot<bool>(
        key: 'isFavorite',
        label: 'Favorite',
        value: isFavorite,
      ),
      HistoryFieldSnapshot<bool>(
        key: 'isArchived',
        label: 'Archived',
        value: isArchived,
      ),
      HistoryFieldSnapshot<bool>(
        key: 'isPinned',
        label: 'Pinned',
        value: isPinned,
      ),
      HistoryFieldSnapshot<bool>(
        key: 'isDeleted',
        label: 'Deleted',
        value: isDeleted,
      ),
      HistoryFieldSnapshot<DateTime>(
        key: 'modifiedAt',
        label: 'Modified at',
        value: modifiedAt,
      ),
      HistoryFieldSnapshot<DateTime>(
        key: 'lastUsedAt',
        label: 'Last used at',
        value: lastUsedAt,
      ),
    ];
  }
}
