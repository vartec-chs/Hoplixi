import 'package:flutter/material.dart';
import 'package:hoplixi/features/password_manager/import/keepass/providers/keepass_import_provider.dart';
import 'package:hoplixi/shared/ui/button.dart';
import 'package:hoplixi/shared/ui/text_field.dart';

class KeepassImportStepContent extends StatelessWidget {
  final KeepassImportState state;
  final KeepassImportNotifier notifier;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final VoidCallback onTogglePasswordVisibility;

  const KeepassImportStepContent({
    super.key,
    required this.state,
    required this.notifier,
    required this.passwordController,
    required this.obscurePassword,
    required this.onTogglePasswordVisibility,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KeepassImportStatusCard(state: state),
        if (state.message != null ||
            state.isLoadingPreview ||
            state.isImporting ||
            state.lastImportSummary != null)
          const SizedBox(height: 12),
        switch (state.currentStep) {
          KeepassImportStep.source => KeepassImportSourceCard(
            state: state,
            notifier: notifier,
            passwordController: passwordController,
            obscurePassword: obscurePassword,
            onTogglePasswordVisibility: onTogglePasswordVisibility,
          ),
          KeepassImportStep.options => KeepassImportOptionsCard(
            state: state,
            notifier: notifier,
          ),
          KeepassImportStep.preview => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              KeepassImportActionsCard(state: state, notifier: notifier),
              const SizedBox(height: 12),
              if (state.lastImportSummary != null)
                KeepassImportLastImportCard(state: state),
              if (state.lastImportSummary != null) const SizedBox(height: 12),
              KeepassImportPreviewCard(state: state),
            ],
          ),
        },
      ],
    );
  }
}

class KeepassImportStatusCard extends StatelessWidget {
  final KeepassImportState state;

  const KeepassImportStatusCard({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.message == null &&
        !state.isLoadingPreview &&
        !state.isImporting &&
        state.lastImportSummary == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final color = state.isSuccess
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.errorContainer;
    final foreground = state.isSuccess
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onErrorContainer;

    return Card(
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (state.isLoadingPreview || state.isImporting)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: LinearProgressIndicator(),
              ),
            if (state.message != null)
              Text(
                state.message!,
                style: theme.textTheme.bodyMedium?.copyWith(color: foreground),
              ),
          ],
        ),
      ),
    );
  }
}

class KeepassImportSourceCard extends StatelessWidget {
  final KeepassImportState state;
  final KeepassImportNotifier notifier;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final VoidCallback onTogglePasswordVisibility;

  const KeepassImportSourceCard({
    super.key,
    required this.state,
    required this.notifier,
    required this.passwordController,
    required this.obscurePassword,
    required this.onTogglePasswordVisibility,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Источник', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            _PathSelector(
              label: 'KeePass база',
              hint: 'Выберите .kdbx или .kdb',
              path: state.databasePath,
              icon: Icons.folder_open,
              buttonLabel: 'Выбрать базу',
              onPick: notifier.pickDatabase,
            ),
            const SizedBox(height: 12),
            _PathSelector(
              label: 'Keyfile',
              hint: 'Необязательно',
              path: state.keyfilePath,
              icon: Icons.key,
              buttonLabel: 'Выбрать keyfile',
              onPick: notifier.pickKeyfile,
              onClear: state.keyfilePath == null ? null : notifier.clearKeyfile,
            ),
            const SizedBox(height: 12),
            PrimaryTextField(
              label: 'Пароль базы',
              controller: passwordController,
              obscureText: obscurePassword,
              onChanged: notifier.setPassword,
              suffixIcon: IconButton(
                onPressed: onTogglePasswordVisibility,
                icon: Icon(
                  obscurePassword ? Icons.visibility : Icons.visibility_off,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class KeepassImportOptionsCard extends StatelessWidget {
  final KeepassImportState state;
  final KeepassImportNotifier notifier;

  const KeepassImportOptionsCard({
    super.key,
    required this.state,
    required this.notifier,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Опции', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Выгружать историю записей'),
              subtitle: const Text(
                'История попадёт в preview и в заметки/мета-данные',
              ),
              value: state.includeHistory,
              onChanged: notifier.setIncludeHistory,
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Выгружать вложения'),
              subtitle: const Text(
                'Для больших вложений сохраняется summary, а base64 только для компактных файлов',
              ),
              value: state.includeAttachments,
              onChanged: notifier.setIncludeAttachments,
            ),
            const Divider(height: 24),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Импортировать OTP'),
              subtitle: const Text(
                'Создаёт OTP и связывает их с паролями, если это возможно',
              ),
              value: state.importOtps,
              onChanged: notifier.setImportOtps,
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Импортировать заметки'),
              subtitle: const Text(
                'KeePass notes, history и служебные блоки будут сохранены в Note',
              ),
              value: state.importNotes,
              onChanged: notifier.setImportNotes,
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Импортировать кастомные поля'),
              subtitle: const Text(
                'Сохранит нестандартные поля, custom data, OTP raw/meta и summary вложений',
              ),
              value: state.importCustomFields,
              onChanged: notifier.setImportCustomFields,
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Создавать категории'),
              subtitle: const Text(
                'Если выключено, новые категории из KeePass не будут создаваться',
              ),
              value: state.createCategories,
              onChanged: notifier.setCreateCategories,
            ),
          ],
        ),
      ),
    );
  }
}

class KeepassImportActionsCard extends StatelessWidget {
  final KeepassImportState state;
  final KeepassImportNotifier notifier;

  const KeepassImportActionsCard({
    super.key,
    required this.state,
    required this.notifier,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SmoothButton(
              label: 'Прочитать базу',
              icon: const Icon(Icons.visibility),
              loading: state.isLoadingPreview,
              onPressed: state.canLoadPreview ? notifier.loadPreview : null,
              type: .tonal,
            ),
            SmoothButton(
              label: 'Импортировать в хранилище',
              icon: const Icon(Icons.download_done),
              variant: SmoothButtonVariant.normal,
              loading: state.isImporting,
              onPressed: state.canImport ? notifier.importPreview : null,
            ),
          ],
        ),
      ),
    );
  }
}

class KeepassImportPreviewCard extends StatelessWidget {
  final KeepassImportState state;

  const KeepassImportPreviewCard({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final preview = state.preview;
    if (preview == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Preview', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                'После чтения базы здесь появится сводка по группам, записям и импортируемым данным.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    final otpEntries = preview.entries
        .where((entry) => entry.otp?.secret?.trim().isNotEmpty ?? false)
        .length;
    final otpErrors = preview.entries
        .where((entry) => entry.otp?.parseError?.trim().isNotEmpty ?? false)
        .length;
    final notesEntries = preview.entries
        .where((entry) => entry.notes?.trim().isNotEmpty ?? false)
        .length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Preview', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Text(
              preview.meta.databaseName?.trim().isNotEmpty ?? false
                  ? preview.meta.databaseName!
                  : preview.sourcePath,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              '${preview.config.databaseVersion} • ${preview.config.kdfName} • ${preview.config.compression}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _PreviewStat(
                  label: 'Группы',
                  value: '${preview.groups.length}',
                ),
                _PreviewStat(
                  label: 'Записи',
                  value: '${preview.entries.length}',
                ),
                _PreviewStat(label: 'OTP ready', value: '$otpEntries'),
                _PreviewStat(label: 'OTP parse errors', value: '$otpErrors'),
                _PreviewStat(label: 'Notes', value: '$notesEntries'),
                _PreviewStat(
                  label: 'Deleted objects',
                  value: '${preview.deletedObjects.length}',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Первые записи',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...preview.entries
                .take(8)
                .map(
                  (entry) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      entry.otp?.secret != null
                          ? Icons.security
                          : Icons.lock_outline,
                    ),
                    title: Text(
                      entry.title?.trim().isNotEmpty ?? false
                          ? entry.title!
                          : entry.username?.trim().isNotEmpty ?? false
                          ? entry.username!
                          : entry.uuid.substring(0, 8),
                    ),
                    subtitle: Text(
                      entry.groupPath.trim().isEmpty
                          ? 'Корень'
                          : entry.groupPath,
                    ),
                    trailing: entry.tags.isEmpty
                        ? null
                        : Text(
                            entry.tags.join(', '),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                  ),
                ),
            if (preview.entries.length > 8)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'И ещё ${preview.entries.length - 8} записей.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class KeepassImportLastImportCard extends StatelessWidget {
  final KeepassImportState state;

  const KeepassImportLastImportCard({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final summary = state.lastImportSummary!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Последний импорт'),
            const SizedBox(height: 8),
            Text(summary.toMessage()),
          ],
        ),
      ),
    );
  }
}

class _PathSelector extends StatelessWidget {
  final String label;
  final String hint;
  final String? path;
  final IconData icon;
  final String buttonLabel;
  final Future<void> Function() onPick;
  final VoidCallback? onClear;

  const _PathSelector({
    required this.label,
    required this.hint,
    required this.path,
    required this.icon,
    required this.buttonLabel,
    required this.onPick,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 8),
              Text(label, style: Theme.of(context).textTheme.titleSmall),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            path?.trim().isNotEmpty ?? false ? path! : hint,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SmoothButton(
                label: buttonLabel,
                type: SmoothButtonType.tonal,
                onPressed: onPick,
              ),
              if (onClear != null)
                SmoothButton(
                  label: 'Очистить',
                  type: SmoothButtonType.outlined,
                  onPressed: onClear,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PreviewStat extends StatelessWidget {
  final String label;
  final String value;

  const _PreviewStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
    );
  }
}
