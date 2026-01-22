import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/category_manager/features/category_picker/category_picker.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/form_close_button.dart';
import 'package:hoplixi/features/password_manager/tags_manager/features/tags_picker/tags_picker.dart';
import 'package:hoplixi/main_store/models/enums/entity_types.dart';
import 'package:hoplixi/shared/ui/text_field.dart';

import '../models/document_form_state.dart';
import '../providers/document_form_provider.dart';

/// Экран формы создания/редактирования документа
class DocumentFormScreen extends ConsumerStatefulWidget {
  const DocumentFormScreen({super.key, this.documentId});

  /// ID документа для редактирования (null = режим создания)
  final String? documentId;

  @override
  ConsumerState<DocumentFormScreen> createState() => _DocumentFormScreenState();
}

class _DocumentFormScreenState extends ConsumerState<DocumentFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();

    _titleController = TextEditingController();
    _descriptionController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(documentFormProvider.notifier);
      if (widget.documentId != null) {
        notifier.initForEdit(widget.documentId!);
      } else {
        notifier.initForCreate();
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _handleSave() async {
    final notifier = ref.read(documentFormProvider.notifier);
    final success = await notifier.save();

    if (!mounted) return;

    if (success) {
      Toaster.success(
        title: widget.documentId != null
            ? 'Документ обновлен'
            : 'Документ создан',
        description: 'Изменения успешно сохранены',
      );
      context.pop(true);
    } else {
      Toaster.error(
        title: 'Ошибка сохранения',
        description: 'Не удалось сохранить документ',
      );
    }
  }

  void _handleAddPages() async {
    await ref.read(documentFormProvider.notifier).pickPages();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(documentFormProvider);

    // Синхронизация контроллеров с состоянием при загрузке данных
    if (state.isEditMode && !state.isLoading) {
      if (_titleController.text != state.title) {
        _titleController.text = state.title;
      }
      if (_descriptionController.text != state.description) {
        _descriptionController.text = state.description;
      }
    }

    // Синхронизация названия после добавления страниц
    if (!state.isEditMode && state.pages.isNotEmpty) {
      if (_titleController.text != state.title) {
        _titleController.text = state.title;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.documentId != null
              ? 'Редактировать документ'
              : 'Создать документ',
        ),
        actions: [
          if (state.isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(icon: const Icon(Icons.save), onPressed: _handleSave),
        ],
        leading: const FormCloseButton(),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.all(12),
                      children: [
                        // Секция страниц документа
                        _buildPagesSection(theme, state),
                        const SizedBox(height: 16),

                        // Прогресс загрузки
                        if (state.isSaving && state.uploadProgress > 0)
                          _buildUploadProgress(theme, state),

                        // Название *
                        TextField(
                          controller: _titleController,
                          decoration: primaryInputDecoration(
                            context,
                            labelText: 'Название *',
                            hintText: 'Введите название документа',
                            errorText: state.titleError,
                          ),
                          onChanged: (value) {
                            ref
                                .read(documentFormProvider.notifier)
                                .setTitle(value);
                          },
                        ),
                        const SizedBox(height: 16),

                        // Тип документа
                        _buildDocumentTypeDropdown(theme, state),
                        const SizedBox(height: 16),

                        // Категория
                        CategoryPickerField(
                          selectedCategoryId: state.categoryId,
                          selectedCategoryName: state.categoryName,
                          label: 'Категория',
                          hintText: 'Выберите категорию',
                          filterByType: [
                            CategoryType.document,
                            CategoryType.mixed,
                          ],
                          onCategorySelected: (categoryId, categoryName) {
                            ref
                                .read(documentFormProvider.notifier)
                                .setCategory(categoryId, categoryName);
                          },
                        ),
                        const SizedBox(height: 16),

                        // Теги
                        TagPickerField(
                          selectedTagIds: state.tagIds,
                          selectedTagNames: state.tagNames,
                          label: 'Теги',
                          hintText: 'Выберите теги',
                          filterByType: [TagType.document, TagType.mixed],
                          onTagsSelected: (tagIds, tagNames) {
                            ref
                                .read(documentFormProvider.notifier)
                                .setTags(tagIds, tagNames);
                          },
                        ),
                        const SizedBox(height: 16),

                        // Описание
                        TextField(
                          controller: _descriptionController,
                          decoration: primaryInputDecoration(
                            context,
                            labelText: 'Описание',
                            hintText: 'Краткое описание документа',
                          ),
                          maxLines: 3,
                          onChanged: (value) {
                            ref
                                .read(documentFormProvider.notifier)
                                .setDescription(value);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  /// Секция страниц документа
  Widget _buildPagesSection(ThemeData theme, DocumentFormState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Страницы документа *',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            if (state.pages.isNotEmpty)
              Text(
                '${state.pageCount} стр. • ${state.formattedTotalSize}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (state.pages.isEmpty)
          _buildAddPagesButton(theme, state)
        else
          _buildPagesList(theme, state),
        if (state.pagesError != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              state.pagesError!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
      ],
    );
  }

  /// Кнопка добавления страниц
  Widget _buildAddPagesButton(ThemeData theme, DocumentFormState state) {
    return InkWell(
      onTap: _handleAddPages,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          border: Border.all(
            color: state.pagesError != null
                ? theme.colorScheme.error
                : theme.colorScheme.outline,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 48,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              'Добавить страницы документа',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'PDF, JPG, PNG, TIFF',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Список страниц
  Widget _buildPagesList(ThemeData theme, DocumentFormState state) {
    return Column(
      children: [
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: state.pages.length,
          onReorder: (oldIndex, newIndex) {
            if (newIndex > oldIndex) newIndex--;
            ref
                .read(documentFormProvider.notifier)
                .movePage(oldIndex, newIndex);
          },
          itemBuilder: (context, index) {
            final page = state.pages[index];
            return _buildPageCard(
              theme,
              page,
              index,
              key: ValueKey(page.pageNumber),
            );
          },
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _handleAddPages,
            icon: const Icon(Icons.add),
            label: const Text('Добавить страницы'),
          ),
        ),
      ],
    );
  }

  /// Карточка страницы
  Widget _buildPageCard(
    ThemeData theme,
    DocumentPageInfo page,
    int index, {
    Key? key,
  }) {
    return Card(
      key: key,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: page.isPrimary
                ? theme.colorScheme.primaryContainer
                : theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: page.isPrimary
                ? Icon(
                    Icons.star,
                    color: theme.colorScheme.onPrimaryContainer,
                    size: 20,
                  )
                : Text(
                    '${page.pageNumber}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        title: Text(
          page.fileName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            Text(page.formattedFileSize),
            if (page.isNew) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Новая',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onTertiaryContainer,
                  ),
                ),
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!page.isPrimary)
              IconButton(
                icon: const Icon(Icons.star_border),
                tooltip: 'Сделать обложкой',
                onPressed: () {
                  ref.read(documentFormProvider.notifier).setPrimaryPage(index);
                },
              ),
            IconButton(
              icon: Icon(Icons.close, color: theme.colorScheme.error),
              tooltip: 'Удалить',
              onPressed: () {
                ref.read(documentFormProvider.notifier).removePage(index);
              },
            ),
            ReorderableDragStartListener(
              index: index,
              child: const Icon(Icons.drag_handle),
            ),
          ],
        ),
      ),
    );
  }

  /// Прогресс загрузки
  Widget _buildUploadProgress(ThemeData theme, DocumentFormState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          LinearProgressIndicator(value: state.uploadProgress),
          const SizedBox(height: 4),
          Text(
            'Загрузка страницы ${state.currentUploadingPage} из ${state.totalPages}',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  /// Выпадающий список типа документа
  Widget _buildDocumentTypeDropdown(ThemeData theme, DocumentFormState state) {
    final documentTypes = [
      ('passport', 'Паспорт'),
      ('id_card', 'Удостоверение личности'),
      ('driver_license', 'Водительское удостоверение'),
      ('insurance', 'Страховой полис'),
      ('medical', 'Медицинский документ'),
      ('contract', 'Договор'),
      ('certificate', 'Сертификат'),
      ('receipt', 'Чек / Квитанция'),
      ('other', 'Другое'),
    ];

    return DropdownButtonFormField<String>(
      value: state.documentType,
      decoration: primaryInputDecoration(
        context,
        labelText: 'Тип документа',
        hintText: 'Выберите тип',
      ),
      items: [
        const DropdownMenuItem<String>(value: null, child: Text('Не указан')),
        ...documentTypes.map(
          (type) =>
              DropdownMenuItem<String>(value: type.$1, child: Text(type.$2)),
        ),
      ],
      onChanged: (value) {
        ref.read(documentFormProvider.notifier).setDocumentType(value);
      },
    );
  }
}
