import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/password_manager/pickers/file_picker/models/file_picker_models.dart';
import 'package:hoplixi/features/password_manager/pickers/file_picker/providers/file_picker_providers.dart';
import 'package:hoplixi/features/password_manager/pickers/file_picker/widgets/file_list_tile.dart';
import 'package:hoplixi/main_store/models/dto/file_dto.dart';
import 'package:hoplixi/shared/ui/text_field.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

/// Показать модальное окно одиночного выбора файла.
///
/// Возвращает [FilePickerResult] с id и именем выбранного файла,
/// или `null` если пользователь закрыл окно без выбора.
Future<FilePickerResult?> showFilePickerModal(
  BuildContext context,
  WidgetRef ref, {
  String? excludeFileId,
}) async {
  ref.read(filePickerFilterProvider.notifier).reset();
  ref.invalidate(filePickerDataProvider);
  await ref.read(filePickerDataProvider.notifier).loadInitial(excludeFileId);

  if (!context.mounted) return null;

  return await WoltModalSheet.show<FilePickerResult>(
    useRootNavigator: true,
    context: context,
    pageListBuilder: (context) => [_buildPage(context, ref)],
  );
}

WoltModalSheetPage _buildPage(BuildContext context, WidgetRef ref) {
  return WoltModalSheetPage(
    hasSabGradient: false,
    topBarTitle: Text(
      'Выбрать файл',
      style: Theme.of(context).textTheme.titleLarge,
    ),
    isTopBarLayerAlwaysVisible: true,
    trailingNavBarWidget: IconButton(
      icon: const Icon(Icons.close),
      onPressed: () => Navigator.of(context).pop(),
    ),
    child: const _FilePickerContent(),
  );
}

class _FilePickerContent extends ConsumerStatefulWidget {
  const _FilePickerContent();

  @override
  ConsumerState<_FilePickerContent> createState() => _FilePickerContentState();
}

class _FilePickerContentState extends ConsumerState<_FilePickerContent> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
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

  void _onFileSelected(FileCardDto file) {
    Navigator.of(context).pop(FilePickerResult(id: file.id, name: file.name));
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(filePickerDataProvider);

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
                      return FileListTile(
                        file: file,
                        onTap: () => _onFileSelected(file),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}
