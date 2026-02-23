import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/app_preferences/app_preference_keys.dart';
import 'package:hoplixi/core/constants/main_constants.dart';
import 'package:hoplixi/core/theme/index.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/settings/providers/settings_provider.dart';
import 'package:hoplixi/main_store/provider/main_store_provider.dart';
import 'package:hoplixi/shared/widgets/close_database_button.dart';
import 'package:hoplixi/shared/widgets/language_switcher.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:window_manager/window_manager.dart';

class TitleBar extends ConsumerStatefulWidget {
  final String? labelOverride;
  final bool showDatabaseButton;
  final bool showLanguageSwitcher;
  final bool showThemeSwitcher;
  final bool lockStoreOnClose;
  final Future<void> Function()? onClose;

  const TitleBar({
    super.key,
    this.labelOverride,
    this.showDatabaseButton = true,
    this.showLanguageSwitcher = true,
    this.showThemeSwitcher = true,
    this.lockStoreOnClose = true,
    this.onClose,
  });

  @override
  ConsumerState<TitleBar> createState() => _TitleBarState();
}

class _TitleBarState extends ConsumerState<TitleBar> {
  final BoxConstraints constraints = const BoxConstraints(
    maxHeight: 40,
    maxWidth: 40,
  );

  BackupScope _parseBackupScope(String? raw) {
    switch (raw) {
      case 'databaseOnly':
        return BackupScope.databaseOnly;
      case 'encryptedFilesOnly':
        return BackupScope.encryptedFilesOnly;
      case 'full':
      default:
        return BackupScope.full;
    }
  }

  Future<void> _createBackupNow() async {
    final settings = ref.read(settingsProvider);
    final backupPath = settings[AppKeys.backupPath.key] as String?;
    final scopeRaw = settings[AppKeys.backupScope.key] as String?;
    final backupMaxPerStore =
        settings[AppKeys.backupMaxPerStore.key] as int? ?? 10;
    final scope = _parseBackupScope(scopeRaw);

    final result = await ref
        .read(mainStoreProvider.notifier)
        .createBackup(
          scope: scope,
          outputDirPath: backupPath,
          periodic: false,
          maxBackupsPerStore: backupMaxPerStore,
        );

    if (!mounted) return;

    if (result == null) {
      Toaster.error(
        title: 'Бэкап не создан',
        description: 'Проверьте, что хранилище открыто',
      );
      return;
    }

    Toaster.success(title: 'Бэкап создан', description: result.backupPath);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titlebarState = ref.watch(titlebarStateProvider);
    final isStoreOpen = ref
        .watch(mainStoreProvider)
        .maybeWhen(data: (state) => state.isOpen, orElse: () => false);
    return DragToMoveArea(
      child: AnimatedContainer(
        height: 40,
        duration: const Duration(milliseconds: 300),

        decoration: BoxDecoration(
          color: titlebarState.backgroundTransparent
              ? Colors.transparent
              : theme.colorScheme.surface,
          border: Border(
            bottom: BorderSide(
              color: titlebarState.backgroundTransparent
                  ? Colors.transparent
                  : theme.dividerColor,
              width: 1,
            ),
          ),
          // borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            titlebarState.hidden
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Row(
                      spacing: 4,
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Image(
                            image: AssetImage('assets/logo/logo.png'),
                          ),
                        ),
                        Text(
                          widget.labelOverride ?? titlebarState.label,
                          style: TextStyle(
                            color: titlebarState.backgroundTransparent
                                ? Colors.white
                                : theme.colorScheme.onSurface,
                            fontSize: 14,
                            // fontWeight: FontWeight.bold,
                            fontStyle: FontStyle.normal,
                            letterSpacing: 0.0,
                            decoration: TextDecoration.none,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          textDirection: TextDirection.ltr,
                        ),
                      ],
                    ),
                  ),
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,

                spacing: 4,

                children: [
                  if (isStoreOpen)
                    IconButton(
                      padding: const EdgeInsets.all(6),
                      icon: const Icon(Icons.backup, size: 20),
                      tooltip: 'Создать бэкап',
                      constraints: constraints,
                      onPressed: _createBackupNow,
                    ),
                  if (widget.showDatabaseButton)
                    const CloseDatabaseButton(
                      type: CloseDatabaseButtonType.icon,
                    ),
                  if (widget.showDatabaseButton && widget.showThemeSwitcher)
                    const SizedBox(width: 4),
                  if (widget.showLanguageSwitcher)
                    const LanguageSwitcher(
                      size: 20,
                      style: LanguageSwitcherStyle.compact,
                      showCompactCode: true,
                    ),
                  if (widget.showThemeSwitcher)
                    const ThemeSwitcher(
                      size: 26,
                      style: ThemeSwitcherStyle.animated,
                    ),

                  IconButton(
                    padding: const EdgeInsets.all(6),
                    icon: const Icon(LucideIcons.minus, size: 20),
                    tooltip: 'Свернуть',
                    constraints: constraints,
                    onPressed: () => windowManager.minimize(),
                  ),
                  IconButton(
                    padding: const EdgeInsets.all(6),
                    tooltip: 'Развернуть',
                    constraints: constraints,
                    icon: const Icon(LucideIcons.maximize, size: 20),
                    onPressed: () => windowManager.maximize(),
                  ),
                  IconButton(
                    padding: const EdgeInsets.all(6),
                    tooltip: 'Закрыть',
                    hoverColor: Colors.red,
                    constraints: constraints,
                    icon: const Icon(
                      LucideIcons.x,
                      size: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    onPressed: () async {
                      if (widget.onClose != null) {
                        await widget.onClose!.call();
                        return;
                      }
                      if (widget.lockStoreOnClose) {
                        await ref.read(mainStoreProvider.notifier).lockStore();
                      }
                      await windowManager.hide();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

@immutable
class TitlebarState {
  final String label;
  final Color? color;
  final Widget? icon;
  final bool loading;
  final bool hidden;
  final bool backgroundTransparent;

  const TitlebarState({
    required this.label,
    this.loading = false,
    this.hidden = false,
    this.backgroundTransparent = false,
    this.color,
    this.icon,
  });

  TitlebarState copyWith({
    String? label,
    Color? color,
    Widget? icon,
    bool? loading,
    bool? backgroundTransparent,
    bool? hidden,
  }) {
    return TitlebarState(
      label: label ?? this.label,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      loading: loading ?? this.loading,
      hidden: hidden ?? this.hidden,
      backgroundTransparent:
          backgroundTransparent ?? this.backgroundTransparent,
    );
  }
}

class TitlebarStateNotifier extends Notifier<TitlebarState> {
  @override
  TitlebarState build() {
    return const TitlebarState(label: MainConstants.appName);
  }

  void updateLabel(String newLabel) {
    state = state.copyWith(label: newLabel);
  }

  void setLoading(bool loading) {
    state = state.copyWith(loading: loading);
  }

  void setHidden(bool hidden) {
    state = state.copyWith(hidden: hidden);
  }

  void updateColor(Color? color) {
    state = state.copyWith(color: color);
  }

  void updateIcon(Widget? icon) {
    state = state.copyWith(icon: icon);
  }

  void setBackgroundTransparent(bool transparent) {
    state = state.copyWith(backgroundTransparent: transparent);
  }
}

final titlebarStateProvider =
    NotifierProvider<TitlebarStateNotifier, TitlebarState>(
      TitlebarStateNotifier.new,
    );
