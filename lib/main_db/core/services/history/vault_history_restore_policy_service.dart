import 'vault_history_normalized_loader.dart';
import '../../tables/vault_items/vault_items.dart';

class VaultHistoryRestorePolicyService {
  bool isRestorable(NormalizedHistorySnapshot snapshot) {
    switch (snapshot.snapshot.type) {
      case VaultItemType.recoveryCodes:
        return false; // recovery codes typically not restorable from snapshot
      default:
        return true;
    }
  }

  List<String> restoreWarnings(NormalizedHistorySnapshot snapshot) {
    final warnings = <String>[];
    
    if (snapshot.snapshot.type == VaultItemType.file) {
      warnings.add('Restore will only restore metadata. Content must exist in storage.');
    }
    
    if (snapshot.snapshot.isDeleted) {
      warnings.add('Item is currently in bin. Restoring will move it back to active.');
    }

    return warnings;
  }
}
