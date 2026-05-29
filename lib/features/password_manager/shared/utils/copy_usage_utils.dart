import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/vault_db/core/config/store_settings_keys.dart';
import 'package:hoplixi/vault_db/providers/repository_providers.dart';

Future<bool> copyCardValue({
  required WidgetRef ref,
  required String itemId,
  required String? text,
}) async {
  if (text == null || text.isEmpty) {
    return false;
  }

  await Clipboard.setData(ClipboardData(text: text));

  try {
    await incrementCardUsageIfEnabled(ref: ref, itemId: itemId);
  } catch (error, stackTrace) {
    logError(
      'Failed to increment usage after copy: $error',
      tag: 'CardCopyUtils',
      stackTrace: stackTrace,
    );
  }

  return true;
}

Future<void> incrementCardUsageIfEnabled({
  required WidgetRef ref,
  required String itemId,
}) async {
  final repo = await ref.watch(vaultRepositories.future);
  final storeSettingsRepo = repo.storeSettings;
  final incrementUsageOnCopy = await storeSettingsRepo.getOrDefault(
    StoreSettingsKey.incrementUsageOnCopy,
  );

  if (incrementUsageOnCopy.isError()) {
    return;
  }

  await repo.vaultItem.incrementUsedCount(itemId);
}
