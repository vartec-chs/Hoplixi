import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/features/setup/providers/setup_provider.dart';
import 'package:hoplixi/features/setup/widgets/biometric_page.dart';
import 'package:hoplixi/features/setup/widgets/navigation_bar.dart';
import 'package:hoplixi/features/setup/widgets/page_indicator.dart';
import 'package:hoplixi/features/setup/widgets/permissions_page.dart';
import 'package:hoplixi/features/setup/widgets/theme_selection_page.dart';
import 'package:hoplixi/features/setup/widgets/welcome_page.dart';
import 'package:hoplixi/routing/paths.dart';
import 'package:universal_platform/universal_platform.dart';

/// Экран первоначальной настройки приложения
class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen>
    with TickerProviderStateMixin {
  late final PageController _pageController;
  late final AnimationController _backgroundController;
  late Animation<Color?> _backgroundColorAnimation;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    _backgroundController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  void _updateBackgroundAnimation(BuildContext context, int page) {
    final colorScheme = Theme.of(context).colorScheme;

    final colors = [
      colorScheme.surface,
      colorScheme.surfaceContainerLow,
      colorScheme.surfaceContainerLowest,
      colorScheme.surfaceContainerHigh,
    ];

    final fromColor = colors[_getCurrentPage().clamp(0, colors.length - 1)];
    final toColor = colors[page.clamp(0, colors.length - 1)];

    _backgroundColorAnimation = ColorTween(begin: fromColor, end: toColor)
        .animate(
          CurvedAnimation(
            parent: _backgroundController,
            curve: Curves.easeInOut,
          ),
        );

    _backgroundController.forward(from: 0);
  }

  int _getCurrentPage() {
    if (_pageController.hasClients) {
      return _pageController.page?.round() ?? 0;
    }
    return 0;
  }

  void _goToPage(int page) {
    _updateBackgroundAnimation(context, page);
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
    ref.read(setupProvider.notifier).goToPage(page);
  }

  void _nextPage() {
    final setupState = ref.read(setupProvider);
    if (setupState.canGoNext) {
      _goToPage(setupState.currentPage + 1);
    }
  }

  void _previousPage() {
    final setupState = ref.read(setupProvider);
    if (setupState.canGoBack) {
      _goToPage(setupState.currentPage - 1);
    }
  }

  Future<void> _completeSetup() async {
    await ref.read(setupProvider.notifier).completeSetup();
    if (mounted) {
      context.go(AppRoutesPaths.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final setupState = ref.watch(setupProvider);
    final colorScheme = Theme.of(context).colorScheme;

    // Определяем страницы в зависимости от платформы
    final pages = <Widget>[
      const WelcomePage(),
      const ThemeSelectionPage(),
      const BiometricPage(),

      if (!UniversalPlatform.isDesktop) const PermissionsPage(),
    ];

    return Scaffold(
      body: AnimatedBuilder(
        animation: _backgroundController,
        builder: (context, child) {
          Color? backgroundColor;
          if (_backgroundController.isAnimating &&
              _backgroundColorAnimation.value != null) {
            backgroundColor = _backgroundColorAnimation.value;
          } else {
            backgroundColor = colorScheme.surface;
          }

          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            color: backgroundColor,
            child: child,
          );
        },
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Область страниц
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: pages.length,
                  onPageChanged: (page) {
                    ref.read(setupProvider.notifier).goToPage(page);
                  },
                  itemBuilder: (context, index) {
                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: pages[index],
                    );
                  },
                ),
              ),

              // Навигационная панель
              SetupNavigationBar(
                canGoBack: setupState.canGoBack,
                isLastPage: setupState.isLastPage,
                isLoading: setupState.isLoading,
                onBack: _previousPage,
                onNext: _nextPage,
                onComplete: _completeSetup,
                indicator: SetupPageIndicator(
                  controller: _pageController,
                  count: setupState.totalPages,
                  onDotClicked: (index) => _goToPage(index),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
