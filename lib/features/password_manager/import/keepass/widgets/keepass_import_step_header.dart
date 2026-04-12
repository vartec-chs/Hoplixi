import 'package:flutter/material.dart';
import 'package:hoplixi/features/password_manager/import/keepass/providers/keepass_import_provider.dart';

class KeepassImportStepHeader extends StatelessWidget {
  final KeepassImportState state;
  final KeepassImportNotifier notifier;
  final List<String> stepTitles;

  const KeepassImportStepHeader({
    super.key,
    required this.state,
    required this.notifier,
    this.stepTitles = const ['Источник', 'Опции', 'Preview и импорт'],
  });

  @override
  Widget build(BuildContext context) {
    final progress = (state.stepIndex + 1) / KeepassImportStep.values.length;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: List.generate(KeepassImportStep.values.length, (index) {
              final step = KeepassImportStep.values[index];
              final isActive = state.stepIndex == index;
              final isCompleted = state.stepIndex > index;
              final canTap = state.canGoToStep(step);

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: canTap ? () => notifier.goToStep(step) : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? Theme.of(context).colorScheme.primaryContainer
                                  .withValues(alpha: 0.6)
                            : Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isActive
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(
                                  context,
                                ).colorScheme.outline.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isCompleted
                                ? Icons.check_circle
                                : isActive
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              stepTitles[index],
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(minHeight: 6, value: progress),
          ),
        ],
      ),
    );
  }
}
