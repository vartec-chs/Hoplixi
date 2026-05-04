import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/core/theme/theme.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/onboarding/application/showcase_controller.dart';
import 'package:hoplixi/features/onboarding/domain/app_guide_id.dart';
import 'package:hoplixi/features/onboarding/domain/guide_start_mode.dart';
import 'package:hoplixi/features/onboarding/presentation/showcase_help_button.dart';
import 'package:hoplixi/features/onboarding/presentation/showcase_registration.dart';
import 'package:hoplixi/features/password_manager/create_store/models/create_store_state.dart';
import 'package:hoplixi/features/password_manager/create_store/providers/create_store_form_provider.dart';
import 'package:hoplixi/features/password_manager/create_store/widgets/step1_name_description.dart';
import 'package:hoplixi/features/password_manager/create_store/widgets/step2_select_path.dart';
import 'package:hoplixi/features/password_manager/create_store/widgets/step3_master_password.dart';
import 'package:hoplixi/features/password_manager/create_store/widgets/step4_confirmation.dart';
import 'package:hoplixi/main_db/core/models/dto/main_store_dto.dart';
import 'package:hoplixi/main_db/providers/main_store_manager_provider.dart';
import 'package:hoplixi/shared/ui/button.dart';
import 'package:hoplixi/shared/widgets/titlebar.dart';
import 'package:showcaseview/showcaseview.dart';

/// Экран создания хранилища по шагам
class CreateStoreScreen extends ConsumerStatefulWidget {
  const CreateStoreScreen({super.key});

  @override
  ConsumerState<CreateStoreScreen> createState() => _CreateStoreScreenState();
}

const _createStoreShowcaseScope = 'create_store_guide';

class _CreateStoreScreenState extends ConsumerState<CreateStoreScreen>
    with SingleTickerProviderStateMixin {
  late final PageController _pageController;
  late final AnimationController _animationController;
  late final CreateStoreGuideKeys _guideKeys;

  @override
  void initState() {
    super.initState();
    _guideKeys = CreateStoreGuideKeys();
    registerAppGuideShowcase(
      scope: _createStoreShowcaseScope,
      enableAutoScroll: true,
      semanticEnable: true,
      autoPlay: false,
      onFinish: _markCreateStoreGuideSeen,
      onDismiss: (_) => _markCreateStoreGuideSeen(),
    );
    _pageController = PageController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _updateTitleBarLabel();
      unawaited(_startCreateStoreGuide(GuideStartMode.auto));
    });
  }

  Future<void> _startCreateStoreGuide(GuideStartMode mode) async {
    final controller = ref.read(showcaseControllerProvider.notifier);
    if (mode == GuideStartMode.auto &&
        !await controller.shouldAutoStart(AppGuideId.createStore)) {
      return;
    }
    if (!mounted) {
      return;
    }

    final keys = _guideKeys.sequence
        .where((key) => key.currentContext != null)
        .toList(growable: false);
    if (keys.isEmpty) {
      return;
    }

    final showcaseView = ShowcaseView.getNamed(_createStoreShowcaseScope);
    if (showcaseView.isShowcaseRunning) {
      return;
    }

    showcaseView.startShowCase(keys, delay: const Duration(milliseconds: 250));
  }

  void _markCreateStoreGuideSeen() {
    if (!mounted) {
      return;
    }
    unawaited(
      ref
          .read(showcaseControllerProvider.notifier)
          .markSeen(AppGuideId.createStore),
    );
  }

  void _updateTitleBarLabel() {
    ref.read(titlebarStateProvider.notifier).setBackgroundTransparent(false);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    ShowcaseView.getNamed(_createStoreShowcaseScope).unregister();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(createStoreFormProvider);
    final formNotifier = ref.read(createStoreFormProvider.notifier);

    // Слушаем изменения шага для анимации
    ref.listen<CreateStoreFormState>(createStoreFormProvider, (previous, next) {
      if (previous?.stepIndex != next.stepIndex) {
        _pageController.animateToPage(
          next.stepIndex,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutCubic,
        );
      }
    });

    final isLastStep = formState.stepIndex == CreateStoreStep.values.length - 1;
    final isFirstStep = formState.stepIndex == 0;

    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;

        // Enter - переход вперед или создание
        if (event.logicalKey == LogicalKeyboardKey.enter) {
          if (formState.canProceed && !formState.isCreating) {
            if (isLastStep) {
              _handleCreate(context, formState);
            } else {
              formNotifier.nextStep();
            }
            return KeyEventResult.handled;
          }
        }

        // Стрелка вправо - переход вперед
        if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
          if (!isLastStep && formState.canProceed && !formState.isCreating) {
            formNotifier.nextStep();
            return KeyEventResult.handled;
          }
        }

        // Стрелка влево или клавиша 'A' - переход назад
        if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
          if (!isFirstStep && !formState.isCreating) {
            formNotifier.previousStep();
            return KeyEventResult.handled;
          }
        }

        return KeyEventResult.ignored;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Создание хранилища'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => _handleClose(context, formNotifier),
          ),
          actions: [
            ShowcaseHelpButton(
              enabled:
                  isFirstStep, // Доступно только на первом шаге, так как там есть ключи для показа
              keys: _guideKeys.sequence,
              scope: _createStoreShowcaseScope,
            ),
          ],
        ),

        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Индикатор прогресса
              _ProgressIndicator(
                showcaseKey: _guideKeys.progress,
                showcaseScope: _createStoreShowcaseScope,
                currentStep: formState.stepIndex,
                totalSteps: 4,
                progress: formState.progress,
              ),

              // Содержимое шагов
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    Step1NameAndDescription(
                      storeNameShowcaseKey: _guideKeys.storeName,
                      showcaseScope: _createStoreShowcaseScope,
                    ),
                    const Step2SelectPath(),
                    const Step3MasterPassword(),
                    const Step4Confirmation(),
                  ],
                ),
              ),

              // Кнопки навигации
              _NavigationButtons(
                formState: formState,
                onPrevious: () => formNotifier.previousStep(),
                onNext: () => formNotifier.nextStep(),
                onCreate: () => _handleCreate(context, formState),
                primaryButtonShowcaseKey: _guideKeys.primaryButton,
                showcaseScope: _createStoreShowcaseScope,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleClose(BuildContext context, CreateStoreFormNotifier notifier) {
    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (context) => AlertDialog(
        title: const Text('Отменить создание?'),
        content: const Text('Все введенные данные будут потеряны. Вы уверены?'),
        actions: [
          SmoothButton(
            onPressed: () => Navigator.of(context).pop(),
            label: 'Продолжить',
            type: SmoothButtonType.text,
          ),
          SmoothButton(
            onPressed: () {
              notifier.reset();
              Navigator.of(context).pop();
              ref
                  .read(titlebarStateProvider.notifier)
                  .setBackgroundTransparent(true);

              context.pop();
            },
            label: 'Отменить',
            type: SmoothButtonType.filled,
          ),
        ],
      ),
    );
  }

  Future<void> _handleCreate(
    BuildContext context,
    CreateStoreFormState formState,
  ) async {
    final formNotifier = ref.read(createStoreFormProvider.notifier);
    final storeNotifier = ref.read(mainStoreProvider.notifier);

    formNotifier.setCreating(true);

    try {
      logInfo('Creating store: ${formState.name}');

      final dto = CreateStoreDto(
        name: formState.name,
        description: formState.description.isEmpty
            ? null
            : formState.description,
        password: formState.password,
        path: formState.finalPath ?? '',
        cipher: formState.cipher,
        useDeviceKey: formState.useDeviceKey,
        useKeyFile: formState.useKeyFile,
        keyFileId: formState.useKeyFile ? formState.keyFileId : null,
        keyFileHint: formState.useKeyFile ? formState.keyFileHint : null,
        keyFileSecret: formState.useKeyFile ? formState.keyFileSecret : null,
      );

      final success = await storeNotifier.createStore(dto);

      if (!mounted) return;

      if (success) {
        // Toaster.success(
        //   title: 'Хранилище создано',
        //   description: 'Хранилище "${formState.name}" успешно создано!',
        // );
        formNotifier.reset();
        ref.read(titlebarStateProvider.notifier).setBackgroundTransparent(true);

        // Редирект на dashboard произойдёт автоматически через router.dart
        // когда состояние БД изменится на isOpen
      } else {
        final storeState = await ref.read(mainStoreProvider.future);
        final errorMessage =
            storeState.error?.message ?? 'Не удалось создать хранилище';

        formNotifier.setCreationError(errorMessage);
        Toaster.error(title: 'Ошибка создания', description: errorMessage);
      }
    } catch (e, stackTrace) {
      logError('Error creating store: $e', stackTrace: stackTrace);

      if (mounted) {
        final errorMessage = 'Ошибка при создании: $e';
        formNotifier.setCreationError(errorMessage);
        Toaster.error(title: 'Ошибка', description: errorMessage);
      }
    } finally {
      formNotifier.setCreating(false);
    }
  }
}

/// Индикатор прогресса
class _ProgressIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final double progress;
  final GlobalKey? showcaseKey;
  final String? showcaseScope;

  const _ProgressIndicator({
    required this.currentStep,
    required this.totalSteps,
    required this.progress,
    this.showcaseKey,
    this.showcaseScope,
  });

  @override
  Widget build(BuildContext context) {
    final child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        // color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Column(
        children: [
          // Шаги
          Row(
            children: List.generate(
              totalSteps,
              (index) => Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: _StepIndicator(
                        number: index + 1,
                        isActive: index == currentStep,
                        isCompleted: index < currentStep,
                        label: _getStepLabel(index),
                      ),
                    ),
                    if (index < totalSteps - 1)
                      Expanded(
                        child: Container(
                          height: 2,
                          color: index < currentStep
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(
                                  context,
                                ).colorScheme.outline.withOpacity(0.3),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Линейный прогресс
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );

    final key = showcaseKey;
    if (key == null) {
      return child;
    }

    return Showcase(
      key: key,
      scope: showcaseScope,
      title: 'Шаги создания',
      description:
          'Индикатор показывает текущий шаг мастера: основные данные, путь, пароль и подтверждение.',
      child: child,
    );
  }

  String _getStepLabel(int index) {
    switch (index) {
      case 0:
        return 'Основное';
      case 1:
        return 'Путь';
      case 2:
        return 'Пароль';
      case 3:
        return 'Готово';
      default:
        return '';
    }
  }
}

/// Индикатор одного шага
class _StepIndicator extends StatelessWidget {
  final int number;
  final bool isActive;
  final bool isCompleted;
  final String label;

  const _StepIndicator({
    required this.number,
    required this.isActive,
    required this.isCompleted,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive || isCompleted
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Center(
            child: isCompleted
                ? Icon(
                    Icons.check,
                    size: 18,
                    color: Theme.of(context).colorScheme.onPrimary,
                  )
                : Text(
                    number.toString(),
                    style: TextStyle(
                      color: isActive
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isActive
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Кнопки навигации
class _NavigationButtons extends StatelessWidget {
  final CreateStoreFormState formState;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onCreate;
  final GlobalKey? primaryButtonShowcaseKey;
  final String? showcaseScope;

  const _NavigationButtons({
    required this.formState,
    required this.onPrevious,
    required this.onNext,
    required this.onCreate,
    this.primaryButtonShowcaseKey,
    this.showcaseScope,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final isFirstStep = formState.stepIndex == 0;
    final isLastStep = formState.stepIndex == CreateStoreStep.values.length - 1;

    return Container(
      padding: EdgeInsets.only(
        left: screenPaddingValue,
        top: screenPaddingValue,
        right: screenPaddingValue,
        bottom: screenPaddingValue + MediaQuery.of(context).viewPadding.bottom,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          // Кнопка "Назад"
          if (!isFirstStep)
            Expanded(
              child: SmoothButton(
                onPressed: formState.isCreating ? null : onPrevious,
                icon: const Icon(Icons.arrow_back),
                label: 'Назад',
                type: SmoothButtonType.outlined,
                isFullWidth: true,
              ),
            ),
          if (!isFirstStep) const SizedBox(width: 16),

          // Кнопка "Далее" / "Создать"
          Expanded(
            flex: isFirstStep
                ? 1
                : isMobile
                ? 1
                : 2,
            child: _wrapPrimaryButton(
              SmoothButton(
                onPressed: formState.canProceed && !formState.isCreating
                    ? (isLastStep ? onCreate : onNext)
                    : null,
                icon: isLastStep
                    ? const Icon(Icons.check)
                    : const Icon(Icons.arrow_forward),
                iconPosition: SmoothButtonIconPosition.end,
                label: formState.isCreating
                    ? 'Создание...'
                    : (isLastStep ? 'Создать' : 'Далее'),
                type: SmoothButtonType.filled,
                loading: formState.isCreating,
                isFullWidth: true,
              ),
              isLastStep: isLastStep,
            ),
          ),
        ],
      ),
    );
  }

  Widget _wrapPrimaryButton(Widget child, {required bool isLastStep}) {
    final key = primaryButtonShowcaseKey;
    if (key == null) {
      return child;
    }

    return Showcase(
      key: key,
      scope: showcaseScope,
      title: isLastStep ? 'Создать хранилище' : 'Перейти дальше',
      description:
          'Эта кнопка ведёт по шагам мастера. На последнем шаге она создаёт хранилище.',
      child: child,
    );
  }
}

class CreateStoreGuideKeys {
  final progress = GlobalKey();
  final storeName = GlobalKey();
  final primaryButton = GlobalKey();

  List<GlobalKey> get sequence => [progress, storeName, primaryButton];
}
