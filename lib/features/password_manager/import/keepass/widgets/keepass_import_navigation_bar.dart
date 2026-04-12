import 'package:flutter/material.dart';
import 'package:hoplixi/features/password_manager/import/keepass/providers/keepass_import_provider.dart';
import 'package:hoplixi/shared/ui/button.dart';

class KeepassImportNavigationBar extends StatelessWidget {
  final KeepassImportState state;
  final KeepassImportNotifier notifier;

  const KeepassImportNavigationBar({
    super.key,
    required this.state,
    required this.notifier,
  });

  @override
  Widget build(BuildContext context) {
    final isBusy = state.isLoadingPreview || state.isImporting;
    final canGoNext = state.canGoToNextStep && !isBusy;
    final blockedReason = _blockedReason(state, isBusy, canGoNext);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (!state.isFirstStep)
                SmoothButton(
                  label: 'Назад',
                  type: SmoothButtonType.outlined,
                  icon: const Icon(Icons.arrow_back),
                  onPressed: notifier.previousStep,
                ),
              if (!state.isFirstStep) const SizedBox(width: 8),
              if (!state.isLastStep)
                SmoothButton(
                  label: 'Далее',
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: canGoNext ? notifier.nextStep : null,
                ),
              if (state.isLastStep)
                Expanded(
                  child: Text(
                    'Проверьте preview и запустите импорт.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
            ],
          ),
          if (blockedReason != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                blockedReason,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String? _blockedReason(
    KeepassImportState state,
    bool isBusy,
    bool canGoNext,
  ) {
    if (state.isLastStep || canGoNext) {
      return null;
    }

    if (isBusy) {
      return 'Дождитесь завершения текущей операции.';
    }

    if (state.currentStep == KeepassImportStep.source) {
      return 'Выберите файл KeePass базы, чтобы перейти дальше.';
    }

    return null;
  }
}
