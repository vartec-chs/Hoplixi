import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/password_manager/store_settings/widgets/change_password_section.dart';
import 'package:hoplixi/features/password_manager/store_settings/widgets/store_settings_form.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

/// Показать модальное окно настроек хранилища
///
/// Возвращает `true` если настройки были сохранены, `false` если отменены
Future<bool?> showStoreSettingsModal(
  BuildContext context,
  WidgetRef ref,
) async {
  final pageIndexNotifier = ValueNotifier<int>(0);

  return await WoltModalSheet.show<bool>(
    context: context,
    barrierDismissible: true,
    useSafeArea: true,
    useRootNavigator: true,
    pageIndexNotifier: pageIndexNotifier,
    pageListBuilder: (modalContext) {
      return [
        // Страница 1: Основные настройки
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
          // trailingNavBarWidget: Padding(
          //   padding: const EdgeInsets.only(right: 8.0),
          //   child: IconButton(
          //     icon: const Icon(Icons.lock_outline),
          //     onPressed: () {
          //       pageIndexNotifier.value = 1;
          //     },
          //     tooltip: 'Сменить пароль',
          //   ),
          // ),
          // TODO: Починить смену пароля
          child: const StoreSettingsForm(),
        ),

        // Страница 2: Смена пароля
        WoltModalSheetPage(
          surfaceTintColor: Colors.transparent,
          hasTopBarLayer: true,
          topBarTitle: Text(
            'Смена пароля',
            style: Theme.of(
              modalContext,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          isTopBarLayerAlwaysVisible: true,
          leadingNavBarWidget: Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                pageIndexNotifier.value = 0;
              },
              tooltip: 'Назад',
            ),
          ),
          child: const Padding(
            padding: EdgeInsets.all(16.0),
            child: ChangePasswordSection(),
          ),
        ),
      ];
    },
  );
}
