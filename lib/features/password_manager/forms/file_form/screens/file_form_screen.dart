import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/pickers/category_picker/category_picker.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/form_close_button.dart';
import 'package:hoplixi/features/password_manager/pickers/note_picker/note_picker_field.dart';
import 'package:hoplixi/features/password_manager/pickers/tags_picker/tags_picker.dart';
import 'package:hoplixi/main_store/models/enums/entity_types.dart';
import 'package:hoplixi/main_store/provider/dao_providers.dart';
import 'package:hoplixi/shared/ui/text_field.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../models/file_form_state.dart';
import '../providers/file_form_provider.dart';

/// Экран формы создания/редактирования файла
class FileFormScreen extends ConsumerStatefulWidget {
  const FileFormScreen({super.key, this.fileId});

  /// ID файла для редактирования (null = режим создания)
  final String? fileId;

  @override
  ConsumerState<FileFormScreen> createState() => _FileFormScreenState();
}

class _FileFormScreenState extends ConsumerState<FileFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  String? _noteName;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController();
    _descriptionController = TextEditingController();

    // Инициализация формы
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(fileFormProvider.notifier);
      if (widget.fileId != null) {
        notifier.initForEdit(widget.fileId!);
      } else {
        notifier.initForCreate();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _handleSave() async {
    final notifier = ref.read(fileFormProvider.notifier);
    final success = await notifier.save();

    if (!mounted) return;

    if (success) {
      Toaster.success(
        title: widget.fileId != null ? 'Файл обновлен' : 'Файл загружен',
        description: 'Изменения успешно сохранены',
      );
      context.pop(true);
    } else {
      Toaster.error(
        title: 'Ошибка сохранения',
        description: 'Не удалось сохранить файл',
      );
    }
  }

  void _handlePickFile() async {
    await ref.read(fileFormProvider.notifier).pickFile();
  }

  Future<void> _loadNoteName(String noteId) async {
    final noteDao = ref.read(noteDaoProvider);
    final asyncValue = noteDao;

    // Ждём данные из AsyncValue
    if (!asyncValue.hasValue) return;

    final note = await asyncValue.value!.getNoteById(noteId);
    if (mounted) {
      setState(() {
        _noteName = note?.title;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(fileFormProvider);

    // Загрузка имени заметки
    ref.listen(fileFormProvider, (prev, next) {
      if (next.noteId != null && next.noteId != prev?.noteId) {
        _loadNoteName(next.noteId!);
      } else if (next.noteId == null) {
        setState(() => _noteName = null);
      }
    });

    // Синхронизация контроллеров с состоянием при загрузке данных
    if (state.isEditMode && !state.isLoading) {
      if (_nameController.text != state.name) {
        _nameController.text = state.name;
      }
      if (_descriptionController.text != state.description) {
        _descriptionController.text = state.description;
      }
    }

    // Синхронизация имени после выбора файла
    if (!state.isEditMode && state.selectedFile != null) {
      if (_nameController.text != state.name) {
        _nameController.text = state.name;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.fileId != null ? 'Редактировать файл' : 'Загрузить файл',
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
        leading: FormCloseButton(),
      ),
      body: SafeArea(
        child: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Expanded(
                    child: Form(
                      key: _formKey,
                      child: ListView(
                        padding: const EdgeInsets.all(12),
                        children: [
                          // Выбор файла (только для режима создания)
                          if (!state.isEditMode) ...[
                            _buildFilePickerSection(theme, state),
                            const SizedBox(height: 16),
                          ],

                          if (state.isSaving && state.uploadProgress > 0)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Column(
                                children: [
                                  LinearProgressIndicator(
                                    value: state.uploadProgress,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Шифрование: ${(state.uploadProgress * 100).toStringAsFixed(0)}%',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),

                          // Информация о файле (режим редактирования)
                          if (state.isEditMode) ...[
                            Text(
                              'Файл',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (state.selectedFile != null)
                              _buildSelectedFileCard(theme, state)
                            else
                              _buildExistingFileInfo(theme, state),
                            if (state.selectedFile == null) ...[
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton.icon(
                                  onPressed: _handlePickFile,
                                  icon: const Icon(Icons.file_upload_outlined),
                                  label: const Text('Заменить файл'),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                          ],

                          // Название *
                          TextField(
                            controller: _nameController,
                            decoration: primaryInputDecoration(
                              context,
                              labelText: 'Название *',
                              hintText: 'Введите название файла',
                              errorText: state.nameError,
                              prefixIcon: Icon(LucideIcons.tag),
                            ),
                            onChanged: (value) {
                              ref
                                  .read(fileFormProvider.notifier)
                                  .setName(value);
                            },
                          ),
                          const SizedBox(height: 16),

                          // Категория
                          CategoryPickerField(
                            selectedCategoryId: state.categoryId,
                            selectedCategoryName: state.categoryName,
                            label: 'Категория',
                            hintText: 'Выберите категорию',
                            filterByType: [
                              CategoryType.file,
                              CategoryType.mixed,
                            ],
                            onCategorySelected: (categoryId, categoryName) {
                              ref
                                  .read(fileFormProvider.notifier)
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
                            filterByType: [TagType.file, TagType.mixed],
                            onTagsSelected: (tagIds, tagNames) {
                              ref
                                  .read(fileFormProvider.notifier)
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
                              hintText: 'Краткое описание файла',
                              prefixIcon: Icon(LucideIcons.fileText),
                            ),
                            maxLines: 3,
                            onChanged: (value) {
                              ref
                                  .read(fileFormProvider.notifier)
                                  .setDescription(value);
                            },
                          ),
                          const SizedBox(height: 16),

                          // Заметки
                          NotePickerField(
                            selectedNoteId: state.noteId,
                            selectedNoteName: _noteName,
                             hintText: 'Выберите заметку',
                            onNoteSelected: (noteId, noteName) {
                              ref
                                  .read(fileFormProvider.notifier)
                                  .setNoteId(noteId);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Прогресс загрузки
                ],
              ),
      ),
    );
  }

  /// Секция выбора файла
  Widget _buildFilePickerSection(ThemeData theme, FileFormState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Файл *',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        if (state.selectedFile != null)
          _buildSelectedFileCard(theme, state)
        else
          _buildFilePickerButton(theme, state),
        if (state.fileError != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              state.fileError!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
      ],
    );
  }

  /// Кнопка выбора файла
  Widget _buildFilePickerButton(ThemeData theme, FileFormState state) {
    return InkWell(
      onTap: _handlePickFile,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          border: Border.all(
            color: state.fileError != null
                ? theme.colorScheme.error
                : theme.colorScheme.outline,
            width: 1.5,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              Icons.cloud_upload_outlined,
              size: 48,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              'Нажмите для выбора файла',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Поддерживаются любые типы файлов',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Карточка выбранного файла
  Widget _buildSelectedFileCard(ThemeData theme, FileFormState state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getFileIcon(state.selectedFileExtension ?? ''),
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.selectedFileName ?? '',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  state.formattedFileSize,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: theme.colorScheme.error),
            onPressed: () {
              ref.read(fileFormProvider.notifier).clearSelectedFile();
            },
          ),
        ],
      ),
    );
  }

  /// Информация о существующем файле (режим редактирования)
  Widget _buildExistingFileInfo(ThemeData theme, FileFormState state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getFileIcon(state.existingFileExtension ?? ''),
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.existingFileName ?? 'Файл',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  state.formattedFileSize,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.lock_outline, color: theme.colorScheme.primary, size: 20),
          const SizedBox(width: 4),
          Text(
            'Зашифрован',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  /// Получить иконку для типа файла
  IconData _getFileIcon(String extension) {
    final ext = extension.toLowerCase().replaceAll('.', '');
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return Icons.image;
      case 'mp3':
      case 'wav':
      case 'flac':
        return Icons.audio_file;
      case 'mp4':
      case 'avi':
      case 'mkv':
      case 'mov':
        return Icons.video_file;
      case 'zip':
      case 'rar':
      case '7z':
      case 'tar':
      case 'gz':
        return Icons.folder_zip;
      case 'txt':
        return Icons.text_snippet;
      case 'json':
      case 'xml':
      case 'yaml':
      case 'yml':
        return Icons.data_object;
      default:
        return Icons.insert_drive_file;
    }
  }
}
