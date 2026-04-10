import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/password_manager/pickers/file_picker/models/file_picker_models.dart';
import 'package:hoplixi/features/password_manager/pickers/file_picker/providers/file_picker_providers.dart';
import 'package:hoplixi/features/password_manager/pickers/file_picker/widgets/file_list_tile.dart';
import 'package:hoplixi/db_core/models/dto/file_dto.dart';
import 'package:hoplixi/shared/ui/button.dart';
import 'package:hoplixi/shared/ui/text_field.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

/// Показать модальное окно множественного выбора файлов.
///
/// [excludeFileId] — ID файла, который не отображается в списке.
/// [initialSelectedIds] — заранее выбранные ID файлов.
///
/// Возвращает [FilePickerMultiResult] или `null`.
Future<FilePickerMultiResult?> showFilePickerMultiModal(
  BuildContext context,
  WidgetRef ref, {
  String? excludeFileId,
  List<String>? initialSelectedIds,
}) async {
  ref.read(filePickerFilterProvider.notifier).reset();
  ref.invalidate(filePickerDataProvider);
  await ref.read(filePickerDataProvider.notifier).loadInitial(excludeFileId);

  if (!context.mounted) return null;

  return await WoltModalSheet.show<FilePickerMultiResult>(
    useRootNavigator: true,
    context: context,
    pageListBuilder: (context) => [
      _buildPage(context, ref, initialSelectedIds: initialSelectedIds),
    ],
  );
}

WoltModalSheetPage _buildPage(
  BuildContext context,
  WidgetRef ref, {
  List<String>? initialSelectedIds,
}) {
  return WoltModalSheetPage(
    hasSabGradient: false,
    topBarTitle: Text(
      'Выбрать файлы',
      style: Theme.of(context).textTheme.titleLarge,
    ),
    isTopBarLayerAlwaysVisible: true,
    trailingNavBarWidget: IconButton(
      icon: const Icon(Icons.close),
      onPressed: () => Navigator.of(context).pop(),
    ),
    child: _FilePickerMultiContent(initialSelectedIds: initialSelectedIds),
  );
}

class _FilePickerMultiContent extends ConsumerStatefulWidget {
  final List<String>? initialSelectedIds;

  const _FilePickerMultiContent({this.initialSelectedIds});

  @override
  ConsumerState<_FilePickerMultiContent> createState() =>
      _FilePickerMultiContentState();
}

class _FilePickerMultiContentState
    extends ConsumerState<_FilePickerMultiContent> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Set<String> _selectedIds = {};
  final Map<String, String> _selectedNames = {};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    if (widget.initialSelectedIds != null) {
      _selectedIds.addAll(widget.initialSelectedIds!);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(filePickerDataProvider.notifier).loadMore();
    }
  }

  void _onSearchChanged(String value) {
    ref.read(filePickerFilterProvider.notifier).updateQuery(value);
    final currentData = ref.read(filePickerDataProvider);
    ref
        .read(filePickerDataProvider.notifier)
        .loadInitial(currentData.excludeFileId);
  }

  void _toggleSelection(FileCardDto file) {
    setState(() {
      if (_selectedIds.contains(file.id)) {
        _selectedIds.remove(file.id);
        _selectedNames.remove(file.id);
      } else {
        _selectedIds.add(file.id);
        _selectedNames[file.id] = file.name;
      }
    });
  }

  void _onConfirm() {
    final results = _selectedIds
        .map((id) => FilePickerResult(id: id, name: _selectedNames[id] ?? ''))
        .toList();
    Navigator.of(context).pop(FilePickerMultiResult(files: results));
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(filePickerDataProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchController,
            decoration: primaryInputDecoration(
              context,
              labelText: 'Поиск',
              hintText: 'Введите название файла',
              prefixIcon: const Icon(Icons.search),
            ),
            onChanged: _onSearchChanged,
          ),
        ),
        if (_selectedIds.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: colorScheme.primaryContainer,
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  size: 20,
                  color: colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 8),
                Text(
                  'Выбрано: ${_selectedIds.length}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(12),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            child: data.files.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('Файлы не найдены'),
                    ),
                  )
                : ListView.separated(
                    controller: _scrollController,
                    shrinkWrap: true,
                    itemCount: data.files.length + (data.isLoadingMore ? 1 : 0),
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      if (index == data.files.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final file = data.files[index] as FileCardDto;
                      final isSelected = _selectedIds.contains(file.id);
                      return FileListTile(
                        file: file,
                        onTap: () => _toggleSelection(file),
                        trailing: Checkbox(
                          value: isSelected,
                          onChanged: (_) => _toggleSelection(file),
                        ),
                      );
                    },
                  ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: SmoothButton(
                  label: 'Отмена',
                  onPressed: () => Navigator.of(context).pop(),
                  type: SmoothButtonType.outlined,
                  variant: SmoothButtonVariant.normal,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SmoothButton(
                  label: 'Выбрать (${_selectedIds.length})',
                  onPressed: _selectedIds.isEmpty ? null : _onConfirm,
                  type: SmoothButtonType.filled,
                  variant: SmoothButtonVariant.normal,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
