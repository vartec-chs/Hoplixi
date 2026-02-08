import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/constants/main_constants.dart';
import 'package:hoplixi/core/theme/index.dart';
import 'package:hoplixi/main_store/provider/main_store_provider.dart';
import 'package:hoplixi/shared/widgets/close_database_button.dart';
// import 'package:hoplixi/app/constants/main_constants.dart';
// import 'package:hoplixi/app/theme/index.dart';
// import 'package:hoplixi/hoplixi_store/providers/hoplixi_store_providers.dart';
// import 'package:hoplixi/hoplixi_store/providers/providers.dart';
// import 'package:hoplixi/core/providers/app_lifecycle_provider.dart';
import 'package:window_manager/window_manager.dart';

class TitleBar extends ConsumerStatefulWidget {
  const TitleBar({super.key});

  @override
  ConsumerState<TitleBar> createState() => _TitleBarState();
}

class _TitleBarState extends ConsumerState<TitleBar> {
  final BoxConstraints constraints = const BoxConstraints(
    maxHeight: 40,
    maxWidth: 40,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // final isDatabaseOpen = ref.watch(isDatabaseOpenProvider);
    // final closeDbTimer = ref.watch(appInactivityTimeoutProvider);
    final titlebarState = ref.watch(titlebarStateProvider);
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
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Image(
                            image: AssetImage('assets/logo/logo.png'),
                          ),
                        ),
                        Text(
                          titlebarState.label,
                          style: TextStyle(
                            color: titlebarState.backgroundTransparent
                                ? Colors.white
                                : theme.colorScheme.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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
                  const CloseDatabaseButton(type: CloseDatabaseButtonType.icon),
                  const ThemeSwitcher(size: 26, style: ThemeSwitcherStyle.animated),
                  IconButton(
                    padding: const EdgeInsets.all(6),
                    icon: const Icon(Icons.minimize, size: 20),
                    tooltip: 'Свернуть',
                    constraints: constraints,
                    onPressed: () => windowManager.minimize(),
                  ),
                  IconButton(
                    padding: const EdgeInsets.all(6),
                    tooltip: 'Развернуть',
                    constraints: constraints,
                    icon: const Icon(Icons.crop_square, size: 20),
                    onPressed: () => windowManager.maximize(),
                  ),
                  IconButton(
                    padding: const EdgeInsets.all(6),
                    tooltip: 'Закрыть',
                    hoverColor: Colors.red,
                    constraints: constraints,
                    icon: const Icon(
                      Icons.close,
                      size: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    onPressed: () async {
                      await ref.read(mainStoreProvider.notifier).lockStore();
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
