import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/app_paths.dart';
import 'package:hoplixi/core/theme/constants.dart';
import 'package:hoplixi/features/password_manager/create_store/models/create_store_state.dart';
import 'package:hoplixi/features/password_manager/create_store/providers/create_store_form_provider.dart';
import 'package:hoplixi/shared/ui/button.dart';

/// Шаг 2: Выбор пути для хранилища
class Step2SelectPath extends ConsumerWidget {
  const Step2SelectPath({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(createStoreFormProvider);
    final notifier = ref.read(createStoreFormProvider.notifier);

    return SingleChildScrollView(
      padding: screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Text(
            'Выбор расположения',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Укажите, где будет храниться база данных',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),

          // Вариант 1: Стандартный путь
          _PathOption(
            title: 'Стандартное расположение',
            subtitle: 'Хранилище будет создано в директории приложения',
            icon: Icons.folder_special,
            isSelected: state.pathType == PathType.standard,
            onTap: () => notifier.setPathType(PathType.standard),
            trailing: FutureBuilder<String>(
              future: AppPaths.appStoragePath,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    snapshot.data!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontFamily: 'monospace',
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Вариант 2: Кастомный путь
          _PathOption(
            title: 'Выбрать папку',
            subtitle: 'Укажите свою директорию для хранилища',
            icon: Icons.folder_open,
            isSelected: state.pathType == PathType.custom,
            onTap: () => notifier.setPathType(PathType.custom),
            trailing: state.pathType == PathType.custom
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      SmoothButton(
                        onPressed: () => _pickDirectory(context, notifier),
                        icon: const Icon(Icons.folder_open),
                        label: 'Выбрать папку',
                        type: SmoothButtonType.outlined,
                        size: SmoothButtonSize.medium,
                      ),
                      if (state.customPath != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Theme.of(context).colorScheme.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  state.customPath!,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(fontFamily: 'monospace'),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (state.pathError != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          state.pathError!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.error,
                              ),
                        ),
                      ],
                    ],
                  )
                : null,
          ),
          const SizedBox(height: 24),

          // Подсказка
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Рекомендации:',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '• Используйте стандартное расположение для удобства\n'
                        '• При выборе своей папки убедитесь в наличии прав записи\n'
                        '• Избегайте сетевых дисков для лучшей производительности',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDirectory(
    BuildContext context,
    CreateStoreFormNotifier notifier,
  ) async {
    final result = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Выберите папку для хранилища',
    );

    if (result != null) {
      notifier.setCustomPath(result);
    }
  }
}

/// Виджет опции выбора пути
class _PathOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final Widget? trailing;

  const _PathOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 28,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Radio<bool>(
                  value: true,
                  groupValue: isSelected,
                  onChanged: (_) => onTap(),
                ),
              ],
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}
