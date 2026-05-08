import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/app_prefs/settings_prefs.dart';
import 'package:hoplixi/core/localization/locale_provider.dart';
import 'package:hoplixi/core/providers/launch_db_path_provider.dart';
import 'package:hoplixi/core/theme/theme.dart';
import 'package:hoplixi/core/theme/theme_window_sync_service.dart';
import 'package:hoplixi/features/cloud_sync/auth/widgets/show_cloud_sync_auth_sheet.dart';
import 'package:hoplixi/features/cloud_sync/common/models/cloud_sync_provider.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/providers/current_store_sync_provider.dart';
import 'package:hoplixi/features/password_manager/store_settings/providers/store_settings_modal_provider.dart';
import 'package:hoplixi/global_key.dart';
import 'package:hoplixi/main_db/providers/decrypted_files_guard_provider.dart';
import 'package:hoplixi/main_db/providers/main_store_manager_provider.dart';
import 'package:hoplixi/routing/paths.dart';
import 'package:hoplixi/routing/router.dart';
import 'package:hoplixi/setup/di_init.dart';
import 'package:hoplixi/shared/ui/button.dart';
import 'package:typed_prefs/typed_prefs.dart';

import 'app_bootstrap.dart';

class AppRuntimeWrapper extends ConsumerStatefulWidget {
  const AppRuntimeWrapper({super.key, this.filePath});

  final String? filePath;

  @override
  ConsumerState<AppRuntimeWrapper> createState() => _AppRuntimeWrapperState();
}

class _AppRuntimeWrapperState extends ConsumerState<AppRuntimeWrapper> {
  ProviderSubscription<AsyncValue<ThemeMode>>? _themeSyncSubscription;
  ProviderSubscription<CurrentStoreSyncManualReauthIssue?>?
  _manualReauthIssueSubscription;
  late final Future<ThemeMode> _initialThemeModeFuture;
  bool _isShowingManualReauthDialog = false;
  String? _handledManualReauthIssueKey;

  @override
  void initState() {
    super.initState();

    _initialThemeModeFuture = () async {
      final storage = getIt.get<PreferencesService>().settingsPrefs;
      final savedMode = await storage.getThemeMode();
      return savedMode;
    }();

    Future<void>(() {
      ref.read(localeProvider.future);
      ref.read(launchDbPathProvider.notifier).setPath(widget.filePath);
      ref.read(decryptedFilesGuardProvider);
    });

    unawaited(
      ThemeWindowSyncService.instance.bindMainNotifier(
        ref.read(themeProvider.notifier),
      ),
    );

    _themeSyncSubscription = ref.listenManual<AsyncValue<ThemeMode>>(
      themeProvider,
      (previous, next) {
        final mode = next.value;
        if (mode == null) return;
        if (ThemeWindowSyncService.instance.consumeSuppressedOutboundFlag(
          mode,
        )) {
          return;
        }
        unawaited(ThemeWindowSyncService.instance.broadcastFromMain(mode));
      },
      fireImmediately: false,
    );

    _manualReauthIssueSubscription = ref
        .listenManual<CurrentStoreSyncManualReauthIssue?>(
          currentStoreSyncManualReauthIssueProvider,
          (previous, next) {
            final issueKey = next?.dedupeKey;
            if (issueKey == null) {
              _handledManualReauthIssueKey = null;
              return;
            }

            if (_isShowingManualReauthDialog ||
                _handledManualReauthIssueKey == issueKey) {
              return;
            }

            _handledManualReauthIssueKey = issueKey;
            _isShowingManualReauthDialog = true;

            WidgetsBinding.instance.addPostFrameCallback((_) async {
              try {
                await _showManualReauthDialog(next!);
              } finally {
                _isShowingManualReauthDialog = false;
              }
            });
          },
          fireImmediately: true,
        );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      FlutterNativeSplash.remove();
    });
  }

  @override
  void dispose() {
    _themeSyncSubscription?.close();
    _manualReauthIssueSubscription?.close();
    super.dispose();
  }

  Future<void> _showManualReauthDialog(
    CurrentStoreSyncManualReauthIssue issue,
  ) async {
    final dialogContext =
        navigatorKey.currentState?.overlay?.context ??
        navigatorKey.currentContext;
    if (dialogContext == null || !mounted) {
      ref.read(currentStoreSyncManualReauthIssueProvider.notifier).clear();
      return;
    }

    final providerName = issue.provider.metadata.displayName;
    final tokenLabel = issue.tokenLabel ?? providerName;
    final providerDetails = 'Тип провайдера: $providerName.';
    final title = switch (issue.kind) {
      CurrentStoreSyncIssueKind.manualReauthRequired =>
        'Требуется повторная авторизация Cloud Sync',
      CurrentStoreSyncIssueKind.missingToken =>
        'Токен Cloud Sync больше не найден',
    };
    final body = switch (issue.kind) {
      CurrentStoreSyncIssueKind.manualReauthRequired => [
        'Токен cloud sync для провайдера $providerName больше не подходит для доступа к облаку.',
        issue.description ??
            'Приложение не смогло автоматически обновить авторизацию.',
        providerDetails,
        'Текущий токен: $tokenLabel.',
        'Идентификатор токена: ${issue.tokenId}.',
        'Чтобы продолжить синхронизацию, заново выполните авторизацию вручную. После этого при необходимости переподключите новый токен к текущему хранилищу.',
      ],
      CurrentStoreSyncIssueKind.missingToken => [
        'Для провайдера $providerName была найдена сохранённая привязка cloud sync, но связанный OAuth-токен на устройстве больше не найден.',
        issue.description ??
            'Вероятно, токен был удалён, не импортирован или потерян после миграции данных.',
        providerDetails,
        'Идентификатор отсутствующего токена: ${issue.tokenId}.',
        'Чтобы продолжить работу с cloud sync, выполните авторизацию заново. После этого при необходимости снова подключите токен к текущему хранилищу.',
      ],
    };
    final action = await showDialog<_ManualReauthDialogAction>(
      context: dialogContext,
      useRootNavigator: true,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SingleChildScrollView(
              child: SelectableText(body.join('\n\n')),
            ),
          ),
          actions: [
            SmoothButton(
              onPressed: () => Navigator.of(
                context,
                rootNavigator: true,
              ).pop(_ManualReauthDialogAction.later),
              label: 'Позже',
              type: .text,
            ),
            SmoothButton(
              onPressed: () => Navigator.of(
                context,
                rootNavigator: true,
              ).pop(_ManualReauthDialogAction.openAuth),
              label: 'Авторизовать вручную',
            ),
          ],
        );
      },
    );

    ref.read(currentStoreSyncManualReauthIssueProvider.notifier).clear();

    if (!mounted || action != _ManualReauthDialogAction.openAuth) {
      return;
    }

    final previousRoute =
        ref.read(routerProvider).state.matchedLocation.isNotEmpty
        ? ref.read(routerProvider).state.matchedLocation
        : AppRoutesPaths.home;

    if (previousRoute.startsWith(AppRoutesPaths.dashboard)) {
      ref.read(pendingStoreSettingsModalPageProvider.notifier).setPage(2);
    } else {
      ref.read(pendingStoreSettingsModalPageProvider.notifier).clear();
    }

    if (ref.read(isStoreSettingsModalOpenProvider)) {
      navigatorKey.currentState?.pop();
      await Future<void>.delayed(Duration.zero);
    }

    await showCloudSyncAuthSheet(
      context: dialogContext,
      container: ProviderScope.containerOf(dialogContext, listen: false),
      previousRoute: previousRoute,
      initialProvider: issue.provider,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isStoreOpeningOverlayVisible = ref.watch(
      mainStoreProvider.select(
        (asyncState) => asyncState.value?.isOpening ?? false,
      ),
    );

    return AppBootstrap(
      initialThemeModeFuture: _initialThemeModeFuture,
      router: ref.watch(routerProvider),
      isStoreOpeningOverlayVisible: isStoreOpeningOverlayVisible,
    );
  }
}

enum _ManualReauthDialogAction { later, openAuth }
