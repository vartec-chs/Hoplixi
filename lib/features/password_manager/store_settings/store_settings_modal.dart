import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/password_manager/store_settings/widgets/store_settings_form.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

/// Показать модальное окно настроек хранилища
///
/// Возвращает `true` если настройки были сохранены, `false` если отменены
Future<bool?> showStoreSettingsModal(
  BuildContext context,
  WidgetRef ref,
) async {
  return await WoltModalSheet.show<bool>(
    context: context,
    barrierDismissible: true,
    useSafeArea: true,
    useRootNavigator: true,
    pageListBuilder: (modalContext) {
      return [
        WoltModalSheetPage(
          surfaceTintColor: Colors.transparent,
          hasTopBarLayer: true,
          topBarTitle: Text(
            'Настройки хранилища',
            style: Theme.of(
              modalContext,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          isTopBarLayerAlwaysVisible: true,
          leadingNavBarWidget: Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(modalContext).pop(false),
              tooltip: 'Закрыть',
            ),
          ),
          child: const StoreSettingsForm(),
        ),
      ];
    },
  );
}
