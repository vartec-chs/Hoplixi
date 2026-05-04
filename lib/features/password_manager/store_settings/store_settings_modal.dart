import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/widgets/cloud_sync_settings_page.dart';
import 'package:hoplixi/features/password_manager/store_settings/providers/store_settings_modal_provider.dart';
import 'package:hoplixi/features/password_manager/store_settings/widgets/change_password_section.dart';
import 'package:hoplixi/features/password_manager/store_settings/widgets/device_key_security_section.dart';
import 'package:hoplixi/features/password_manager/store_settings/widgets/key_file_security_section.dart';
import 'package:hoplixi/features/password_manager/store_settings/widgets/pinned_entity_types_selector.dart';
import 'package:hoplixi/features/password_manager/store_settings/widgets/store_settings_form.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

/// Показать модальное окно настроек хранилища
///
/// Возвращает `true` если настройки были сохранены, `false` если отменены
Future<bool?> showStoreSettingsModal(
  BuildContext context, {
  int initialPageIndex = 0,
}) async {
  final container = ProviderScope.containerOf(context, listen: false);
  container.read(pendingStoreSettingsModalPageProvider.notifier).clear();
  final pageIndexNotifier = ValueNotifier<int>(initialPageIndex);
  final returnToDeviceKeyPage = ValueNotifier<bool>(false);
  container.read(isStoreSettingsModalOpenProvider.notifier).setOpen(true);

  try {
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
            topBarTitle: Builder(
              builder: (context) {
                return Text(
                  'Настройки хранилища',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                );
              },
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
            trailingNavBarWidget: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.cloud_sync_outlined),
                  onPressed: () {
                    pageIndexNotifier.value = 3;
                  },
                  tooltip: 'Cloud Sync',
                ),

                IconButton(
                  icon: const Icon(Icons.push_pin_outlined),
                  onPressed: () {
                    pageIndexNotifier.value = 2;
                  },
                  tooltip: 'Типы записей',
                ),
                IconButton(
                  icon: const Icon(Icons.lock_outline),
                  onPressed: () {
                    pageIndexNotifier.value = 1;
                  },
                  tooltip: 'Сменить пароль',
                ),
                const SizedBox(width: 8),
              ],
            ),

            child: const StoreSettingsForm(),
          ),

          // Страница 2: Смена пароля
          WoltModalSheetPage(
            surfaceTintColor: Colors.transparent,
            hasTopBarLayer: true,
            topBarTitle: Builder(
              builder: (context) {
                return Text(
                  'Смена пароля',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                );
              },
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
            trailingNavBarWidget: Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Row(
                spacing: 8,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.key_outlined),
                    onPressed: () {
                      pageIndexNotifier.value = 4;
                    },
                    tooltip: 'JSON key file',
                  ),
                  IconButton(
                    icon: const Icon(Icons.phonelink_lock_outlined),
                    onPressed: () {
                      pageIndexNotifier.value = 5;
                    },
                    tooltip: 'Ключ устройства',
                  ),
                ],
              ),
            ),
            child: const Padding(
              padding: EdgeInsets.all(12.0),
              child: ChangePasswordSection(),
            ),
          ),

          // Страница 3: Типы записей в навигации
          WoltModalSheetPage(
            surfaceTintColor: Colors.transparent,
            hasTopBarLayer: true,
            topBarTitle: Builder(
              builder: (context) {
                return Text(
                  'Типы записей в навигации',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                );
              },
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
              padding: EdgeInsets.all(12.0),
              child: PinnedEntityTypesSelector(),
            ),
          ),

          // Страница 4: Cloud Sync
          WoltModalSheetPage(
            surfaceTintColor: Colors.transparent,
            hasTopBarLayer: true,
            topBarTitle: Builder(
              builder: (context) {
                return Text(
                  'Cloud Sync',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                );
              },
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
            child: const CloudSyncSettingsPage(
              reopenStoreSettingsAfterAuth: true,
            ),
          ),

          WoltModalSheetPage(
            surfaceTintColor: Colors.transparent,
            hasTopBarLayer: true,
            topBarTitle: Builder(
              builder: (context) {
                return Text(
                  'JSON key file',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                );
              },
            ),
            leadingNavBarWidget: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  if (returnToDeviceKeyPage.value) {
                    pageIndexNotifier.value = 5;
                    returnToDeviceKeyPage.value = false;
                  } else {
                    pageIndexNotifier.value = 1;
                  }
                },
                tooltip: 'Назад',
              ),
            ),
            trailingNavBarWidget: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                icon: const Icon(Icons.phonelink_lock_outlined),
                onPressed: () {
                  pageIndexNotifier.value = 5;
                },
                tooltip: 'Ключ устройства',
              ),
            ),
            child: const KeyFileSecuritySection(),
          ),

          WoltModalSheetPage(
            surfaceTintColor: Colors.transparent,
            hasTopBarLayer: true,
            topBarTitle: Builder(
              builder: (context) {
                return Text(
                  'Ключ устройства',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                );
              },
            ),
            leadingNavBarWidget: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  pageIndexNotifier.value = 1;
                },
                tooltip: 'Назад',
              ),
            ),
            trailingNavBarWidget: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                icon: const Icon(Icons.key_outlined),
                onPressed: () {
                  pageIndexNotifier.value = 4;
                  returnToDeviceKeyPage.value = true;
                },
                tooltip: 'JSON key file',
              ),
            ),
            child: const DeviceKeySecuritySection(),
          ),
        ];
      },
    );
  } finally {
    container.read(isStoreSettingsModalOpenProvider.notifier).setOpen(false);
    pageIndexNotifier.dispose();
  }
}
