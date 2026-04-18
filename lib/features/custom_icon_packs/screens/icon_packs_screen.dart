import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/custom_icon_packs/models/icon_pack_summary.dart';
import 'package:hoplixi/features/custom_icon_packs/models/icon_packs_state.dart';
import 'package:hoplixi/features/custom_icon_packs/providers/icon_packs_provider.dart';
import 'package:hoplixi/features/custom_icon_packs/services/icon_pack_catalog_service.dart';
import 'package:hoplixi/shared/ui/button.dart';
import 'package:hoplixi/shared/ui/text_field.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

class IconPacksScreen extends ConsumerStatefulWidget {
  const IconPacksScreen({super.key});

  @override
  ConsumerState<IconPacksScreen> createState() => _IconPacksScreenState();
}

class _IconPacksScreenState extends ConsumerState<IconPacksScreen> {
  final DateFormat _dateFormat = DateFormat('dd.MM.yyyy HH:mm');

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(iconPacksNotifierProvider);
    final notifier = ref.read(iconPacksNotifierProvider.notifier);

    ref.listen(iconPacksNotifierProvider, (previous, next) {
      if (next.successMessage != null &&
          next.successMessage != previous?.successMessage) {
        Toaster.success(
          title: 'Импорт завершён',
          description: next.successMessage,
        );
      }

      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        Toaster.error(title: 'Ошибка', description: next.errorMessage);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Паки иконок'),
        actions: [
          IconButton(
            tooltip: 'Обновить',
            onPressed: state.isLoadingPacks ? null : notifier.loadPacks,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: notifier.loadPacks,
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            _buildImportCard(context, state, notifier),
            const SizedBox(height: 16),
            _buildPacksSection(context, state),
          ],
        ),
      ),
    );
  }

  Widget _buildImportCard(
    BuildContext context,
    IconPacksState state,
    IconPacksNotifier notifier,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Импорт SVG-пака',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Выберите ZIP-архив или обычную папку, подтвердите название пака и сохраните его в служебный каталог приложения.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: TextEditingController(
                text: state.selectedSourcePath ?? '',
              ),
              decoration: primaryInputDecoration(
                context,
                labelText: 'Источник',
                hintText: 'Выберите ZIP-архив или папку',
                prefixIcon: Icon(
                  state.sourceType == IconPackImportSourceType.archive
                      ? Icons.archive_outlined
                      : Icons.folder_open_outlined,
                ),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (state.selectedSourcePath != null)
                      IconButton(
                        tooltip: 'Очистить',
                        onPressed:
                            state.isImporting ||
                                state.selectedSourcePath == null
                            ? null
                            : notifier.clearImportDraft,
                        icon: const Icon(Icons.close),
                      ),
                    IconButton(
                      tooltip: 'Выбрать источник',
                      onPressed: state.isImporting
                          ? null
                          : () => _pickSourceAndName(context, notifier),
                      icon: const Icon(Icons.add_box_outlined),
                    ),
                  ],
                ),
              ),
              readOnly: true,
              enabled: !state.isImporting,
            ),
            const SizedBox(height: 12),
            if (state.displayName != null && state.packKey != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.displayName!,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      state.sourceType == IconPackImportSourceType.archive
                          ? 'Источник: архив'
                          : 'Источник: папка',
                    ),
                    Text('Ключ: ${state.packKey}'),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: SmoothButton(
                label: 'Импортировать',
                loading: state.isImporting,
                onPressed: state.canImport ? notifier.importSelectedPack : null,
              ),
            ),
            if (state.isImporting) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(value: state.progress),
              const SizedBox(height: 8),
              Text('${(state.progress * 100).toStringAsFixed(0)}%'),
              if (state.currentFile != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Текущий файл: ${state.currentFile}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPacksSection(BuildContext context, IconPacksState state) {
    if (state.isLoadingPacks && state.packs.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Импортированные паки',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (state.packs.isEmpty)
              Text(
                'Паки иконок пока не импортированы.',
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else
              ...state.packs.map((pack) => _buildPackTile(context, pack)),
          ],
        ),
      ),
    );
  }

  Widget _buildPackTile(BuildContext context, IconPackSummary pack) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    pack.displayName,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                Text('${pack.iconCount} SVG'),
              ],
            ),
            const SizedBox(height: 6),
            Text('Ключ: ${pack.packKey}'),
            Text('Источник: ${pack.sourceArchiveName}'),
            Text(
              'Импортирован: ${_dateFormat.format(pack.importedAt.toLocal())}',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickSourceAndName(
    BuildContext context,
    IconPacksNotifier notifier,
  ) async {
    final sourceType = await _showSourceTypeDialog(context);
    if (sourceType == null || !mounted) {
      return;
    }

    if (sourceType == IconPackImportSourceType.archive) {
      await _pickArchiveAndName(context, notifier);
      return;
    }

    await _pickDirectoryAndName(context, notifier);
  }

  Future<IconPackImportSourceType?> _showSourceTypeDialog(
    BuildContext context,
  ) async {
    return showDialog<IconPackImportSourceType>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Выберите источник'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.archive_outlined),
                  title: const Text('ZIP-архив'),
                  subtitle: const Text('Импорт из файла архива'),
                  onTap: () => Navigator.of(
                    dialogContext,
                  ).pop(IconPackImportSourceType.archive),
                ),
                ListTile(
                  leading: const Icon(Icons.folder_open_outlined),
                  title: const Text('Папка'),
                  subtitle: const Text('Импорт из директории'),
                  onTap: () => Navigator.of(
                    dialogContext,
                  ).pop(IconPackImportSourceType.directory),
                ),
              ],
            ),
          ),
          actions: [
            SmoothButton(
              label: 'Отмена',
              type: SmoothButtonType.text,
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickArchiveAndName(
    BuildContext context,
    IconPacksNotifier notifier,
  ) async {
    final result = await notifier.pickArchiveFile();
    if (result == null || result.files.single.path == null || !mounted) {
      return;
    }

    final archivePath = result.files.single.path!;
    final suggestedName = p.basenameWithoutExtension(archivePath);
    final selectedName = await _showPackNameDialog(
      context,
      initialName: suggestedName,
      sourcePath: archivePath,
      sourceType: IconPackImportSourceType.archive,
      notifier: notifier,
    );

    if (selectedName == null || !mounted) {
      return;
    }

    notifier.setImportDraft(
      sourcePath: archivePath,
      sourceType: IconPackImportSourceType.archive,
      displayName: selectedName,
    );
  }

  Future<void> _pickDirectoryAndName(
    BuildContext context,
    IconPacksNotifier notifier,
  ) async {
    final directoryPath = await notifier.pickSourceDirectory();
    if (directoryPath == null || !mounted) {
      return;
    }

    final suggestedName = p.basename(directoryPath);
    final selectedName = await _showPackNameDialog(
      context,
      initialName: suggestedName,
      sourcePath: directoryPath,
      sourceType: IconPackImportSourceType.directory,
      notifier: notifier,
    );

    if (selectedName == null || !mounted) {
      return;
    }

    notifier.setImportDraft(
      sourcePath: directoryPath,
      sourceType: IconPackImportSourceType.directory,
      displayName: selectedName,
    );
  }

  Future<String?> _showPackNameDialog(
    BuildContext context, {
    required String initialName,
    required String sourcePath,
    required IconPackImportSourceType sourceType,
    required IconPacksNotifier notifier,
  }) async {
    final controller = TextEditingController(text: initialName);
    var errorText = _validatePackName(controller.text, notifier);

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            final packKey = IconPackCatalogService.normalizePackKey(
              controller.text,
            );

            return AlertDialog(
              title: const Text('Название пака'),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${sourceType == IconPackImportSourceType.archive ? 'Архив' : 'Папка'}: ${p.basename(sourcePath)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: controller,
                      autofocus: true,
                      decoration: primaryInputDecoration(
                        context,
                        labelText: 'Название пака',
                        hintText: 'Введите понятное имя',
                        errorText: errorText,
                      ),
                      onChanged: (_) {
                        setState(() {
                          errorText = _validatePackName(
                            controller.text,
                            notifier,
                          );
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    Text('Ключ: ${packKey.isEmpty ? '—' : packKey}'),
                  ],
                ),
              ),
              actions: [
                SmoothButton(
                  label: 'Отмена',
                  type: SmoothButtonType.text,
                  onPressed: () => Navigator.of(dialogContext).pop(),
                ),
                SmoothButton(
                  label: 'Использовать',
                  onPressed: errorText != null
                      ? null
                      : () => Navigator.of(
                          dialogContext,
                        ).pop(controller.text.trim()),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();
    return result;
  }

  String? _validatePackName(String value, IconPacksNotifier notifier) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return 'Введите название пака.';
    }

    final packKey = IconPackCatalogService.normalizePackKey(trimmed);
    if (packKey.isEmpty) {
      return 'Название содержит только недопустимые символы.';
    }

    if (notifier.packKeyExists(packKey)) {
      return 'Пак с таким ключом уже существует.';
    }

    return null;
  }
}
