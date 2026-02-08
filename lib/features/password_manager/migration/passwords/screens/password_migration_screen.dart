import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/data_refresh_trigger_provider.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/form_close_button.dart';
import 'package:hoplixi/features/password_manager/migration/passwords/providers/password_migration_provider.dart';
import 'package:hoplixi/main_store/models/dto/password_dto.dart';
import 'package:hoplixi/shared/ui/button.dart';
import 'package:hoplixi/shared/ui/notification_card.dart';
import 'package:hoplixi/shared/ui/text_field.dart';
import 'package:open_file/open_file.dart';

class PasswordMigrationScreen extends ConsumerStatefulWidget {
  const PasswordMigrationScreen({super.key});

  @override
  ConsumerState<PasswordMigrationScreen> createState() =>
      _PasswordMigrationScreenState();
}

class _PasswordMigrationScreenState
    extends ConsumerState<PasswordMigrationScreen> {
  final _countController = TextEditingController(text: '10');

  @override
  void dispose() {
    _countController.dispose();

    super.dispose();
  }

  Future<void> _generateTemplate() async {
    final count = int.tryParse(_countController.text);
    if (count == null || count <= 0) {
      ref
          .read(passwordMigrationProvider.notifier)
          .setError('Please enter a valid number greater than 0');
      return;
    }

    final outputFile = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Template JSON',
      fileName: 'passwords_template.json',
      allowedExtensions: ['json'],
      type: FileType.custom,
    );

    if (outputFile == null) return;

    final notifier = ref.read(passwordMigrationProvider.notifier);
    await notifier.generateTemplate(count, outputFile);
  }

  Future<void> _openGeneratedFile() async {
    final state = ref.read(passwordMigrationProvider).value;
    if (state?.generatedFilePath == null) return;
    final result = await OpenFile.open(state!.generatedFilePath);
    if (result.type != ResultType.done) {
      ref
          .read(passwordMigrationProvider.notifier)
          .setError('Could not open file: ${result.message}');
    }
  }

  Future<void> _selectFile() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Select Passwords JSON',
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null || result.files.single.path == null) return;

    final path = result.files.single.path!;
    final notifier = ref.read(passwordMigrationProvider.notifier);
    await notifier.selectFile(path);
  }

  Future<void> _importPasswords() async {
    // Сбрасываем ошибку перед новой попыткой импорта
    ref.read(passwordMigrationProvider.notifier).clearError();

    final state = ref.read(passwordMigrationProvider).value;
    if (state?.importFilePath == null) return;

    final notifier = ref.read(passwordMigrationProvider.notifier);
    await notifier.parseImportFile(state!.importFilePath!);

    final updatedState = ref.read(passwordMigrationProvider).value;
    if (updatedState?.error != null) {
      // Error will be shown via NotificationCard
    } else if (updatedState?.parsedPasswords != null) {
      await _showPreviewDialog(
        updatedState!.parsedPasswords!,
        state.importFilePath!,
        context,
      );
    }
  }

  Future<void> _showPreviewDialog(
    List<CreatePasswordDto> passwords,
    String filePath,
    BuildContext context,
  ) async {
    if (passwords.isEmpty) {
      Toaster.info(
        title: 'Info',
        description:
            'No valid passwords found in file. Each password must have a name, password, and at least a login or email.',
      );
      return;
    }

    final windowWidth = MediaQuery.of(context).size.width;
    final isWideScreen = windowWidth > 600;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        insetPadding: isWideScreen ? null : const EdgeInsets.all(12.0),
        title: Text('Preview Import (${passwords.length} valid items)'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: passwords.length,
            itemBuilder: (context, index) {
              final item = passwords[index];
              return ListTile(
                title: Text(item.name),
                subtitle: Text(item.login ?? item.email ?? 'No login/email'),
                trailing: const Icon(Icons.lock_outline, size: 16),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _confirmImport(passwords, filePath);
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmImport(
    List<CreatePasswordDto> passwords,
    String filePath,
  ) async {
    final notifier = ref.read(passwordMigrationProvider.notifier);
    await notifier.savePasswords(passwords, filePath);

    final state = ref.read(passwordMigrationProvider).value;
    if (state?.error != null) {
      // Триггерим обновление списка

      // Error will be shown via NotificationCard
    } else {
      ref
          .read(dataRefreshTriggerProvider.notifier)
          .triggerEntityAdd(EntityType.password);
      ref
          .read(passwordMigrationProvider.notifier)
          .setError('Passwords imported successfully');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(passwordMigrationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Миграция Паролей'),
        leading: const FormCloseButton(),
      ),

      body: state.maybeWhen(
        loading: () => const Center(child: CircularProgressIndicator()),
        orElse: () => SingleChildScrollView(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AnimatedSwitcher(
                transitionBuilder: (child, animation) =>
                    SizeTransition(sizeFactor: animation, child: child),
                duration: const Duration(milliseconds: 200),
                child: state.value?.error != null
                    ? Column(
                        key: const ValueKey('error_visible'),
                        children: [
                          NotificationCard(
                            type: state.value!.error!.contains('successfully')
                                ? NotificationType.success
                                : NotificationType.error,
                            text: state.value!.error!,
                            onDismiss: () {
                              ref
                                  .read(passwordMigrationProvider.notifier)
                                  .clearError();
                            },
                          ),
                          const SizedBox(height: 12),
                        ],
                      )
                    : const SizedBox.shrink(
                        key: ValueKey('error_hidden'),
                      ),
              ),
              _buildGenerateSection(),
              const SizedBox(height: 12),
              _buildImportSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGenerateSection() {
    final state = ref.watch(passwordMigrationProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Генерация Шаблона',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Создайте JSON-файл с пустыми шаблонами паролей для заполнения.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _countController,
              decoration: primaryInputDecoration(
                context,
                labelText: 'Количество шаблонов',
                hintText: '10',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: SmoothButton(
                label: 'Сгенерировать JSON',
                onPressed: _generateTemplate,
                type: SmoothButtonType.filled,
              ),
            ),
            if (state.value?.generatedFilePath != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: SmoothButton(
                  label: 'Открыть сгенерированный файл',
                  onPressed: _openGeneratedFile,
                  type: SmoothButtonType.outlined,
                  icon: const Icon(Icons.open_in_new, size: 18),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImportSection() {
    final state = ref.watch(passwordMigrationProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Импорт Паролей',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text('Импортируйте пароли из заполненного JSON-шаблона.'),
            const SizedBox(height: 16),
            if (state.value?.importFilePath != null) ...[
              Text(
                state.value!.importFilePath == state.value!.generatedFilePath
                    ? 'Сгенерированный шаблон готов к импорту: ${state.value!.importFilePath}'
                    : 'Выбранный файл: ${state.value!.importFilePath}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: SmoothButton(
                  label: 'Импортировать',
                  onPressed: _importPasswords,
                  type: SmoothButtonType.filled,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: SmoothButton(
                  label: 'Выбрать другой файл',
                  onPressed: _selectFile,
                  type: SmoothButtonType.outlined,
                ),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: SmoothButton(
                  label: 'Выбрать JSON файл',
                  onPressed: _selectFile,
                  type: SmoothButtonType.filled,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
