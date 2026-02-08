import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/app_paths.dart';
import 'package:hoplixi/core/theme/constants.dart';
import 'package:hoplixi/features/password_manager/create_store/models/create_store_state.dart';
import 'package:hoplixi/features/password_manager/create_store/providers/create_store_form_provider.dart';

/// Шаг 4: Подтверждение и создание
class Step4Confirmation extends ConsumerWidget {
  const Step4Confirmation({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(createStoreFormProvider);

    return SingleChildScrollView(
      padding: screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Text(
            'Проверьте данные',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Убедитесь, что все данные введены правильно перед созданием хранилища',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),

          // Карточка с информацией
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
              ),
            ),
            child: Column(
              children: [
                // Имя
                _InfoRow(
                  icon: Icons.storage,
                  label: 'Имя хранилища',
                  value: state.name,
                ),
                if (state.description.isNotEmpty) ...[
                  const Divider(height: 24),
                  _InfoRow(
                    icon: Icons.description,
                    label: 'Описание',
                    value: state.description,
                    maxLines: 3,
                  ),
                ],
                const Divider(height: 24),

                // Путь
                _InfoRow(
                  icon: Icons.folder,
                  label: 'Расположение',
                  value: state.pathType == PathType.standard
                      ? 'Стандартное'
                      : 'Пользовательское',
                ),
                if (state.pathType == PathType.standard)
                  FutureBuilder<String>(
                    future: AppPaths.appStoragePath,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(left: 40, top: 8),
                        child: Text(
                          snapshot.data!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                fontFamily: 'monospace',
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    },
                  )
                else if (state.customPath != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 40, top: 8),
                    child: Text(
                      state.customPath!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontFamily: 'monospace',
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                const Divider(height: 24),

                // Пароль
                const _InfoRow(
                  icon: Icons.lock,
                  label: 'Мастер пароль',
                  value: '••••••••',
                  trailing: Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Важная информация
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primaryContainer.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Важно помнить:',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _InfoBullet(
                  text: 'Мастер пароль используется для шифрования всех данных',
                  context: context,
                ),
                _InfoBullet(
                  text: 'Без пароля доступ к хранилищу будет невозможен',
                  context: context,
                ),
                _InfoBullet(
                  text: 'Восстановление пароля не предусмотрено',
                  context: context,
                ),
                _InfoBullet(
                  text: 'Храните пароль в надежном месте',
                  context: context,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Строка с информацией
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final int? maxLines;
  final Widget? trailing;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.maxLines,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                maxLines: maxLines,
                overflow: maxLines != null ? TextOverflow.ellipsis : null,
              ),
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 8), trailing!],
      ],
    );
  }
}

/// Пункт списка с буллитом
class _InfoBullet extends StatelessWidget {
  final String text;
  final BuildContext context;

  const _InfoBullet({required this.text, required this.context});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
