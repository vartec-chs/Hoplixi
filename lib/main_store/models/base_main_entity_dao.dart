abstract class BaseMainEntityDao {
  Future<bool> softDelete(String id);
  Future<bool> restoreFromDeleted(String id);
  Future<bool> permanentDelete(String id);
  Future<bool> toggleFavorite(String id, bool isFavorite);
  Future<bool> togglePin(String id, bool isPinned);
  Future<bool> toggleArchive(String id, bool isArchived);
  Future<bool> incrementUsage(String id);
}
