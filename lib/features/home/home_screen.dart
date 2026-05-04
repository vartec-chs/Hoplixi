import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/constants/main_constants.dart';
import 'package:hoplixi/core/providers/launch_db_path_provider.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/home/models/action_item.dart';
import 'package:hoplixi/features/onboarding/application/showcase_controller.dart';
import 'package:hoplixi/features/onboarding/domain/app_guide_id.dart';
import 'package:hoplixi/features/onboarding/domain/guide_start_mode.dart';
import 'package:hoplixi/features/onboarding/presentation/showcase_help_button.dart';
import 'package:hoplixi/features/onboarding/presentation/showcase_registration.dart';
import 'package:hoplixi/features/password_generator/password_generator_widget.dart';
import 'package:hoplixi/main_db/core/models/dto/main_store_dto.dart';
import 'package:hoplixi/main_db/providers/db_history_provider.dart';
import 'package:hoplixi/main_db/providers/main_store_manager_provider.dart';
import 'package:hoplixi/main_db/ui/store_open_migration_dialog.dart';
import 'package:hoplixi/routing/paths.dart';
import 'package:hoplixi/shared/ui/button.dart';
import 'package:hoplixi/shared/ui/text_field.dart';
import 'package:hoplixi/shared/widgets/titlebar.dart';
import 'package:hoplixi/shared/widgets/watchers/lifecycle/app_lifecycle_provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path/path.dart' as p;
import 'package:showcaseview/showcaseview.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

import 'providers/recent_database_provider.dart';
import 'widgets/home_actions_content_layer.dart';
import 'widgets/home_header_background.dart';
import 'widgets/home_top_actions.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

const _homeShowcaseScope = 'home_guide';

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  late ScrollController _scrollController;
  late final HomeGuideKeys _guideKeys;
  ProviderSubscription<String?>? _launchPathSubscription;
  bool _isHandlingLaunchPath = false;

  // Анимации для шариков
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _guideKeys = HomeGuideKeys();
    registerAppGuideShowcase(
      scope: _homeShowcaseScope,
      hideFloatingActionWidgetForShowcase: [_guideKeys.settings],
      previousActionHideKeys: [_guideKeys.createStore],
      nextActionHideKeys: [_guideKeys.settings],
      onFinish: _markHomeGuideSeen,
      onDismiss: (_) => _markHomeGuideSeen(),
    );
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    // Инициализация анимаций шариков
    _pulseController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _syncHomeAnimations(ref.read(isAppActiveProvider));

    _launchPathSubscription = ref.listenManual<String?>(launchDbPathProvider, (
      previous,
      next,
    ) {
      if (next == null || next.trim().isEmpty || _isHandlingLaunchPath) {
        return;
      }
      unawaited(_handleLaunchDbPath(next));
    }, fireImmediately: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _updateTitleBarLabel();
      unawaited(_startHomeGuide(GuideStartMode.auto));
    });
  }

  Future<void> _startHomeGuide(GuideStartMode mode) async {
    final controller = ref.read(showcaseControllerProvider.notifier);
    if (mode == GuideStartMode.auto &&
        !await controller.shouldAutoStart(AppGuideId.home)) {
      return;
    }
    if (!mounted) {
      return;
    }

    final keys = _guideKeys.sequence;

    final showcaseView = ShowcaseView.getNamed(_homeShowcaseScope);
    if (showcaseView.isShowcaseRunning) {
      return;
    }

    showcaseView.startShowCase(keys, delay: const Duration(milliseconds: 250));
  }

  void _markHomeGuideSeen() {
    if (!mounted) {
      return;
    }
    unawaited(
      ref.read(showcaseControllerProvider.notifier).markSeen(AppGuideId.home),
    );
  }

  Future<void> _handleLaunchDbPath(String launchPath) async {
    _isHandlingLaunchPath = true;

    try {
      ref.read(launchDbPathProvider.notifier).clearPath();

      final normalizedPath = launchPath.trim();
      final lowerPath = normalizedPath.toLowerCase();

      if (!lowerPath.endsWith(MainConstants.dbExtension)) {
        Toaster.error(
          title: 'Неверный формат файла',
          description:
              'Поддерживаются только файлы ${MainConstants.dbExtension}',
        );
        return;
      }

      final dbFile = File(normalizedPath);
      if (!await dbFile.exists()) {
        Toaster.error(
          title: 'Файл базы не найден',
          description: normalizedPath,
        );
        return;
      }

      final storageDirPath = p.dirname(normalizedPath);
      final historyService = await ref.read(dbHistoryProvider.future);
      final historyEntry = await historyService.getByPath(storageDirPath);

      final savedPassword = historyEntry?.savePassword == true
          ? await historyService.getSavedPasswordByPath(storageDirPath)
          : null;
      if (savedPassword != null && savedPassword.isNotEmpty) {
        final opened = await ref
            .read(mainStoreProvider.notifier)
            .openStore(
              OpenStoreDto(path: normalizedPath, password: savedPassword),
            );
        if (opened) {
          return;
        }

        if (!mounted) {
          return;
        }

        final handled = await promptStoreMigrationAndOpen(
          context: context,
          ref: ref,
          dto: OpenStoreDto(path: normalizedPath, password: savedPassword),
        );
        if (handled) {
          return;
        }
      }

      if (!mounted) {
        return;
      }

      await _showLaunchPasswordDialog(normalizedPath);
    } finally {
      _isHandlingLaunchPath = false;
    }
  }

  Future<void> _showLaunchPasswordDialog(String dbPath) async {
    if (!mounted) {
      return;
    }

    final dbStat = await File(dbPath).stat();
    if (!mounted) {
      return;
    }

    final dbName = p.basenameWithoutExtension(dbPath);
    final passwordController = TextEditingController();
    String? passwordError;
    bool isOpening = false;

    await showDialog<void>(
      context: context,
      useRootNavigator: false,
      barrierDismissible: !isOpening,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> localSubmit() async {
              final password = passwordController.text;
              if (password.isEmpty) {
                setState(() {
                  passwordError = 'Введите пароль';
                });
                return;
              }

              setState(() {
                isOpening = true;
                passwordError = null;
              });

              final opened = await ref
                  .read(mainStoreProvider.notifier)
                  .openStore(OpenStoreDto(path: dbPath, password: password));

              if (!context.mounted) {
                return;
              }

              if (opened) {
                return;
              }

              final handled = await promptStoreMigrationAndOpen(
                context: context,
                ref: ref,
                dto: OpenStoreDto(path: dbPath, password: password),
                onOpened: () async {
                  Navigator.of(context).pop();
                },
              );
              if (!context.mounted || handled) {
                return;
              }

              final storeState = await ref.read(mainStoreProvider.future);
              if (!context.mounted) {
                return;
              }

              setState(() {
                isOpening = false;
                passwordError =
                    storeState.error?.message ?? 'Не удалось открыть хранилище';
              });
            }

            return Dialog(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Открытие хранилища',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        dbName,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Изменён: ${dbStat.modified}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 16),
                      PasswordField(
                        label: 'Пароль',
                        controller: passwordController,
                        autofocus: true,
                      ),
                      if (passwordError != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          passwordError!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.error,
                              ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          SmoothButton(
                            label: 'Отмена',
                            type: SmoothButtonType.text,
                            onPressed: isOpening
                                ? null
                                : () => Navigator.of(context).pop(),
                          ),
                          const SizedBox(width: 8),
                          SmoothButton(
                            label: 'Открыть',
                            type: SmoothButtonType.filled,
                            loading: isOpening,
                            onPressed: isOpening ? null : localSubmit,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    passwordController.dispose();
  }

  void _updateTitleBarLabel() {
    ref.read(titlebarStateProvider.notifier).updateColor(Colors.white);
    ref.read(titlebarStateProvider.notifier).setBackgroundTransparent(true);
  }

  void _onScroll() {
    if (_scrollController.offset >= 160) {
      ref.read(titlebarStateProvider.notifier).setBackgroundTransparent(false);
    } else {
      ref.read(titlebarStateProvider.notifier).setBackgroundTransparent(true);
    }
  }

  void _syncHomeAnimations(bool isAppActive) {
    if (isAppActive) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
      return;
    }

    _pulseController.stop(canceled: false);
  }

  @override
  void dispose() {
    _launchPathSubscription?.close();
    _scrollController.dispose();
    _pulseController.dispose();
    ShowcaseView.getNamed(_homeShowcaseScope).unregister();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recentDbAsync = ref.watch(recentDatabaseProvider);
    final isAppActive = ref.watch(isAppActiveProvider);

    ref.listen<bool>(isAppActiveProvider, (previous, next) {
      if (previous == next) {
        return;
      }
      _syncHomeAnimations(next);
    });

    final topPadding = MediaQuery.of(context).padding.top;
    final headerHeight = 220 + topPadding;
    final hasRecentDatabase = recentDbAsync.maybeWhen(
      data: (entry) => entry != null,
      orElse: () => false,
    );
    final contentTop = hasRecentDatabase
        ? headerHeight - 88
        : headerHeight + 12;

    return Scaffold(
      body: Stack(
        children: [
          HomeHeaderBackground(
            height: headerHeight,
            hasRecentDatabase: hasRecentDatabase,
            isAppActive: isAppActive,
            pulseAnimation: _pulseAnimation,
          ),
          HomeTopActions(
            settingsShowcaseKey: _guideKeys.settings,
            showcaseScope: _homeShowcaseScope,
            helpButton: ShowcaseHelpButton(
              keys: _guideKeys.sequence,
              scope: _homeShowcaseScope,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          HomeActionsContentLayer(
            top: contentTop,
            hasRecentDatabase: hasRecentDatabase,
            items: _buildActionItems(context),
            showcaseScope: _homeShowcaseScope,
          ),
        ],
      ),
    );
  }

  /// Список кнопок действий — легко расширять
  List<ActionItem> _buildActionItems(BuildContext context) {
    return [
      ActionItem(
        icon: LucideIcons.folderOpen,
        label: 'Открыть',
        description: 'Существующее хранилище',
        isPrimary: true,
        onTap: () => context.push(AppRoutesPaths.openStore),
        showcaseKey: _guideKeys.openStore,
        showcaseTitle: 'Открыть хранилище',
        showcaseDescription:
            'Используйте эту карточку, чтобы выбрать и открыть существующее хранилище.',
      ),
      ActionItem(
        icon: LucideIcons.plus,
        label: 'Создать',
        description: 'Новое хранилище',
        onTap: () => context.push(AppRoutesPaths.createStore),
        showcaseKey: _guideKeys.createStore,
        showcaseTitle: 'Создать хранилище',
        showcaseDescription:
            'Начните здесь, если нужно создать новое зашифрованное хранилище.',
      ),
      ActionItem(
        icon: LucideIcons.key,
        label: 'Генератор',
        description: 'Генерация паролей',
        showcaseKey: _guideKeys.generator,
        showcaseTitle: 'Генератор паролей',
        showcaseDescription:
            'Генератор паролей поможет создать надёжные пароли с нужными параметрами. Результат можно скопировать или сразу использовать для создания новой записи.',
        onTap: () async {
          await _openPasswordGeneratorModal();
        },
      ),

      ActionItem(
        icon: LucideIcons.send,
        label: 'LocalSend',
        description:
            'Отправка данных по локальной сети в том числе и хранилища',
        showcaseKey: _guideKeys.localSend,
        showcaseTitle: 'LocalSend',
        showcaseDescription:
            'Используйте отправку по локальной сети, чтобы быстро передавать данные и связанные файлы между устройствами.',
        onTap: () => context.push(AppRoutesPaths.localSendSend),
      ),

      ActionItem(
        icon: LucideIcons.archive,
        label: 'Архивация хранилища',
        description: 'Упаковать хранилище в архив или распаковать из архива',
        onTap: () => context.push(AppRoutesPaths.archiveStore),
      ),

      ActionItem(
        icon: LucideIcons.image,
        label: 'Паки иконок',
        description: 'Импорт и каталог пользовательских SVG-паков',
        onTap: () => context.push(AppRoutesPaths.iconPacks),
      ),

      ActionItem(
        icon: LucideIcons.cloud,
        label: 'Cloud Sync',
        description: 'Центр управления облачной синхронизацией и токенами.',
        showcaseKey: _guideKeys.cloudSync,
        showcaseTitle: 'Cloud Sync',
        showcaseDescription:
            'Это центральное место для управления всеми аспектами облачной синхронизации, включая настройку аккаунта, управление токенами доступа и дополнительным функциям облачных сервисов.',
        onTap: () => context.push(AppRoutesPaths.cloudSync),
      ),
      if (!MainConstants.isProduction) ...[
        ActionItem(
          icon: LucideIcons.box,
          label: 'Component Showcase',
          description: 'Тестовый экран для UI-компонентов',
          onTap: () => context.push(AppRoutesPaths.componentShowcase),
        ),
      ],
    ];
  }

  /// Компактная сетка 2x2 для маленьких экранов

  /// Сетка горизонтальных кнопок 2x2 для больших экранов

  Future<void> _openPasswordGeneratorModal() async {
    await WoltModalSheet.show<void>(
      context: context,
      useSafeArea: true,
      useRootNavigator: true,
      pageListBuilder: (modalContext) => [
        WoltModalSheetPage(
          surfaceTintColor: Colors.transparent,
          hasTopBarLayer: true,
          isTopBarLayerAlwaysVisible: true,
          topBarTitle: Text(
            'Генератор пароля',
            style: Theme.of(
              modalContext,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          leadingNavBarWidget: Padding(
            padding: const EdgeInsets.only(left: 8),
            child: IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Закрыть',
              onPressed: () => Navigator.of(modalContext).pop(),
            ),
          ),
          child: const Padding(
            padding: EdgeInsets.all(8),
            child: PasswordGeneratorWidget(
              showRefreshButton: true,
              showSubmitButton: false,

              submitLabel: 'Использовать пароль',
              // onPasswordSubmitted: (password) {
              //   Navigator.of(modalContext).pop(password);
              // },
            ),
          ),
        ),
      ],
    );
  }
}

class HomeGuideKeys {
  final createStore = GlobalKey();
  final openStore = GlobalKey();
  final generator = GlobalKey();
  final localSend = GlobalKey();
  final cloudSync = GlobalKey();
  final settings = GlobalKey();

  List<GlobalKey> get sequence => [
    createStore,
    openStore,
    generator,
    localSend,
    cloudSync,
    settings,
  ];
}
