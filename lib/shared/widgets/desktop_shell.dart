import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/global_key.dart';
import 'package:hoplixi/shared/widgets/status_bar.dart';

import 'titlebar.dart';

class DesktopShell extends StatelessWidget {
  final Widget child;

  const DesktopShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            Consumer(
              builder: (context, ref, _) {
                final titlebarState = ref.watch(titlebarStateProvider);
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  height:
                      titlebarState.hidden ||
                          titlebarState.backgroundTransparent
                      ? 0
                      : 40,
                );
              },
            ),
            Expanded(child: child),

            Consumer(
              builder: (context, ref, _) {
                final statusBarState = ref.watch(statusBarStateProvider);
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  height: statusBarState.hidden ? 0 : 28,
                  child: const StatusBar(),
                );
              },
            ),
          ],
        ),
        // const Positioned(top: 0, left: 0, right: 0, child: TitleBar()),
      ],
    );
  }
}

class RootOverlayObserver extends NavigatorObserver {
  static final RootOverlayObserver instance = RootOverlayObserver._();
  VoidCallback? onRoutesChanged;
  RootOverlayObserver._();

  @override
  void didPush(Route route, Route? previousRoute) {
    onRoutesChanged?.call();
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    onRoutesChanged?.call();
    super.didPop(route, previousRoute);
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    onRoutesChanged?.call();
    super.didRemove(route, previousRoute);
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    onRoutesChanged?.call();
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
}

class RootBarsOverlay extends StatefulWidget {
  final Widget child;
  const RootBarsOverlay({super.key, required this.child});

  @override
  State<RootBarsOverlay> createState() => _RootBarsOverlayState();
}

class _RootBarsOverlayState extends State<RootBarsOverlay> {
  OverlayEntry? _entry;
  bool _inserted = false;
  bool _retryScheduled = false;

  @override
  void initState() {
    super.initState();

    // Ставим callback, чтобы при изменении навигации поднимать entry наверх
    // RootOverlayObserver.instance.onRoutesChanged = _bringEntryToTop;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _insertIntoRootOverlay();
    });
  }

  OverlayEntry _createEntry() {
    return OverlayEntry(
      builder: (context) {
        return const IgnorePointer(
          ignoring: false,

          child: Stack(
            children: [
              // TitleBar сверху
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: RepaintBoundary(child: TitleBar()),
              ),

              // StatusBar снизу
            ],
          ),
        );
      },
    );
  }

  void _insertIntoRootOverlay() {
    if (_inserted || !mounted) return;

    final overlay = navigatorKey.currentState?.overlay;
    if (overlay == null) {
      if (_retryScheduled) return;
      _retryScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _retryScheduled = false;
        _insertIntoRootOverlay();
      });
      return;
    }

    _entry ??= _createEntry();
    overlay.insert(_entry!);
    _inserted = true;
  }

  // Удаляем и заново вставляем entry — это гарантированно переместит его в конец стека (сверху).
  void _bringEntryToTop() {
    if (!_inserted || !mounted) return;
    _entry?.remove();
    _inserted = false;
    // вставим на следующем фрейме чтобы избежать проблем во время навигации
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _insertIntoRootOverlay(),
    );
  }

  @override
  void dispose() {
    RootOverlayObserver.instance.onRoutesChanged = null;
    if (_inserted) {
      _entry?.remove();
      _inserted = false;
    }
    _entry = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
