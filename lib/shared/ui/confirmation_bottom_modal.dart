import 'package:flutter/material.dart';
import 'package:hoplixi/shared/ui/button.dart';
import 'package:hoplixi/shared/widgets/status_bar/status_bar.dart';
import 'package:universal_platform/universal_platform.dart';

/// Нижняя модалка подтверждения с одинаковыми отступами от экрана.
///
/// Внешние отступы: 12px слева, справа и снизу.
/// Подходит для подтверждения действий и поддерживает произвольный `body`
/// (например, `Slider`).
class ConfirmationBottomModal extends StatelessWidget {
  final String? title;
  final String? description;
  final Widget? body;
  final String? confirmButtonLabel;
  final String? declineButtonLabel;
  final VoidCallback? onConfirmPressed;
  final VoidCallback? onDeclinePressed;
  final SmoothButtonVariant confirmButtonVariant;

  const ConfirmationBottomModal({
    super.key,
    this.title,
    this.description,
    this.body,
    this.confirmButtonLabel = 'Подтвердить',
    this.declineButtonLabel = 'Отклонить',
    this.onConfirmPressed,
    this.onDeclinePressed,
    this.confirmButtonVariant = SmoothButtonVariant.normal,
  });

  /// Показывает модалку подтверждения в нижней части экрана.
  static Future<bool?> show({
    required BuildContext context,
    String? title,
    String? description,
    Widget? body,
    String? confirmButtonLabel = 'Подтвердить',
    String? declineButtonLabel = 'Отклонить',
    VoidCallback? onConfirmPressed,
    VoidCallback? onDeclinePressed,
    SmoothButtonVariant confirmButtonVariant = SmoothButtonVariant.normal,
    bool barrierDismissible = true,
    bool useRootNavigator = true,
    Color barrierColor = const Color(0x80000000),
  }) {
    final desktopBottomInset = UniversalPlatform.isDesktop
        ? statusBarHeight
        : 0.0;
    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: 'Закрыть модалку подтверждения',
      barrierColor: barrierColor,
      useRootNavigator: useRootNavigator,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (dialogContext, _, _) {
        final keyboardBottomInset = MediaQuery.of(
          dialogContext,
        ).viewInsets.bottom;

        return SafeArea(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                12,
                12,
                12,
                12 + keyboardBottomInset + desktopBottomInset,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),

                child: ConfirmationBottomModal(
                  title: title,
                  description: description,
                  body: body,
                  confirmButtonLabel: confirmButtonLabel,
                  declineButtonLabel: declineButtonLabel,
                  onConfirmPressed: onConfirmPressed,
                  onDeclinePressed: onDeclinePressed,
                  confirmButtonVariant: confirmButtonVariant,
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

        return FadeTransition(
          opacity: curvedAnimation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.12),
              end: Offset.zero,
            ).animate(curvedAnimation),
            child: child,
          ),
        );
      },
    );
  }

  bool get _hasActions {
    return confirmButtonLabel != null || declineButtonLabel != null;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: colorScheme.surfaceContainerHigh,
      elevation: 10,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (title != null) ...[
                Text(title!, style: textTheme.titleMedium),
              ],
              if (description != null) ...[
                if (title != null) const SizedBox(height: 8),
                Text(description!, style: textTheme.bodyMedium),
              ],
              if (body != null) ...[
                if (title != null || description != null)
                  const SizedBox(height: 12),
                body!,
              ],
              if (_hasActions) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (declineButtonLabel != null)
                      Expanded(
                        child: SmoothButton(
                          label: declineButtonLabel!,
                          type: SmoothButtonType.outlined,
                          onPressed: () {
                            onDeclinePressed?.call();
                            Navigator.of(context).pop(false);
                          },
                        ),
                      ),
                    if (declineButtonLabel != null &&
                        confirmButtonLabel != null)
                      const SizedBox(width: 12),
                    if (confirmButtonLabel != null)
                      Expanded(
                        child: SmoothButton(
                          label: confirmButtonLabel!,
                          variant: confirmButtonVariant,
                          onPressed: () {
                            onConfirmPressed?.call();
                            Navigator.of(context).pop(true);
                          },
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
