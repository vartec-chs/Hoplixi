import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/main_db/config/store_settings_keys.dart';
import 'package:hoplixi/main_db/providers/other/dao_providers.dart';

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
  final settingsDao = await ref.read(storeSettingsDaoProvider.future);
  final incrementUsageOnCopy = await settingsDao.getSetting(
    StoreSettingsKeys.incrementUsageOnCopy,
  );

  final shouldIncrement = incrementUsageOnCopy == null
      ? true
      : incrementUsageOnCopy == 'true';
  if (!shouldIncrement) {
    return;
  }

  final vaultItemDao = await ref.read(vaultItemDaoProvider.future);
  await vaultItemDao.incrementUsage(itemId);
}
