import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/logger/index.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/data_refresh_trigger_provider.dart';
import 'package:hoplixi/features/password_manager/forms/note_form/models/note_form_state.dart';
import 'package:hoplixi/shared/ui/button.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

import '../providers/note_form_provider.dart';
import '../widgets/note_links_section.dart';
import '../widgets/note_metadata_modal.dart';
import '../widgets/note_picker_modal.dart';

/// Экран формы создания/редактирования заметки
/// Основной интерфейс - QuillEditor для редактирования контента
/// При сохранении открывается модальное окно для редактирования метаданных
class NoteFormScreen extends ConsumerStatefulWidget {
  const NoteFormScreen({super.key, this.noteId});

  /// ID заметки для редактирования (null = режим создания)
  final String? noteId;

  @override
  ConsumerState<NoteFormScreen> createState() => _NoteFormScreenState();
}

class _NoteFormScreenState extends ConsumerState<NoteFormScreen> {
  late final QuillController _quillController;
  final FocusNode _editorFocusNode = FocusNode();
  final ScrollController _editorScrollController = ScrollController();
  bool _isInitialized = false;

  bool get isEditMode => widget.noteId != null;

  @override
  void initState() {
    super.initState();

    // Инициализируем пустой контроллер
    _quillController = QuillController.basic(
      config: const QuillControllerConfig(
        clipboardConfig: QuillClipboardConfig(enableExternalRichPaste: true),
      ),
    );

    // Слушаем изменения документа для отслеживания связей
    _quillController.addListener(_onDocumentChanged);

    // Инициализация формы
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(noteFormProvider.notifier);
      if (widget.noteId != null) {
        notifier.initForEdit(widget.noteId!);
      } else {
        notifier.initForCreate();
      }

      // Слушаем изменения состояния для синхронизации контроллера
      ref.listenManual(noteFormProvider, (previous, next) {
        if (!_isInitialized &&
            next.isEditMode &&
            !next.isLoading &&
            next.deltaJson.isNotEmpty &&
            next.deltaJson != '[]') {
          _syncControllerWithState(next);
        }
      }, fireImmediately: true);
    });
  }

  /// Обработка изменений документа для отслеживания связей
  void _onDocumentChanged() {
    // Обновляем стейт при каждом изменении
    _updateStateFromController();
  }

  @override
  void dispose() {
    _quillController.removeListener(_onDocumentChanged);
    _quillController.dispose();
    _editorFocusNode.dispose();
    _editorScrollController.dispose();
    super.dispose();
  }

  /// Синхронизировать контроллер с состоянием провайдера
  void _syncControllerWithState(NoteFormState state) {
    if (_isInitialized) return;

    try {
      final deltaJson = jsonDecode(state.deltaJson) as List<dynamic>;
      _quillController.document = Document.fromJson(deltaJson);
      _isInitialized = true;
    } catch (e) {
      // Если не удалось распарсить, оставляем пустой документ
      _isInitialized = true;
    }
  }

  /// Обновить состояние провайдера из контроллера
  void _updateStateFromController() {
    ref.read(noteFormProvider.notifier).updateFromController(_quillController);
  }

  /// Вставить ссылку на заметку
  Future<void> _insertNoteLink() async {
    // Импортируем функцию из note_link_button
    final result = await showNotePickerModal(
      context,
      ref,
      excludeNoteId: widget.noteId, // Исключаем текущую заметку
    );

    if (result == null) return;

    // Получаем текущую позицию курсора
    final selection = _quillController.selection;
    final index = selection.baseOffset;
    final length = selection.extentOffset - index;

    // Создаем текст ссылки
    final linkText = result.name;

    // Формируем URL ссылки (внутренний формат для заметок)
    final linkUrl = 'note://${result.id}';

    // Вставляем ссылку
    if (length > 0) {
      // Если есть выделенный текст - преобразуем его в ссылку
      _quillController.formatText(index, length, LinkAttribute(linkUrl));
    } else {
      // Если нет выделения - вставляем новый текст со ссылкой
      _quillController.document.insert(index, linkText);
      _quillController.formatText(
        index,
        linkText.length,
        LinkAttribute(linkUrl),
      );

      // Перемещаем курсор в конец вставленного текста
      _quillController.updateSelection(
        TextSelection.collapsed(offset: (index + linkText.length).toInt()),
        ChangeSource.local,
      );
    }

    // Обновляем стейт с новыми связями
    _updateStateFromController();

    // Возвращаем фокус в редактор
    _editorFocusNode.requestFocus();

    logInfo('Добавлена ссылка на заметку: ${result.id}');
  }

  /// Показать модальное окно и сохранить заметку
  void _handleSave() async {
    // Сначала обновляем контент из редактора
    _updateStateFromController();

    final state = ref.read(noteFormProvider);

    // Проверяем, что контент не пустой
    if (state.content.trim().isEmpty) {
      Toaster.warning(
        title: 'Пустая заметка',
        description: 'Добавьте содержание перед сохранением',
      );
      return;
    }

    // Показываем модальное окно для редактирования метаданных
    final result = await showNoteMetadataModal(
      context,
      isEditMode: isEditMode,
      onSave: () async {
        final success = await ref.read(noteFormProvider.notifier).save();

        if (!mounted) return;

        if (success) {
          Toaster.success(
            title: isEditMode ? 'Заметка обновлена' : 'Заметка создана',
            description: 'Изменения успешно сохранены',
          );
          context.pop(true);
        } else {
          Toaster.error(
            title: 'Ошибка сохранения',
            description: 'Не удалось сохранить заметку',
          );
        }
      },
    );

    // Если пользователь отменил модальное окно
    if (result == true) {
      if (isEditMode) {
        logInfo('Заметка отредактирована: ${widget.noteId}');
        DataRefreshHelper.refreshNotes(ref);
      } else {
        logInfo('Создана новая заметка');
        DataRefreshHelper.refreshNotes(ref);
      }
    }
  }

  /// Обработка клика по ссылке на заметку
  void _handleNoteLinkClick(String noteId) {
    // Сначала сохраняем текущую заметку (если есть изменения)
    _updateStateFromController();

    // Показываем диалог с опциями
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Открыть заметку'),
        content: const Text(
          'Хотите открыть связанную заметку? Текущие несохраненные изменения останутся.',
        ),
        actions: [
          SmoothButton(
            onPressed: () => Navigator.pop(context),
            label: 'Отмена',
            type: .outlined,
            variant: .error,
          ),
          SmoothButton(
            onPressed: () {
              Navigator.pop(context);
              // Открываем заметку в новом окне (через навигацию)
              context.pushNamed(
                'entity_edit',
                pathParameters: {'entity': EntityType.note.id, 'id': noteId},
              );
            },
            label: 'Открыть',
            type: .filled,
          ),
        ],
      ),
    );
  }

  /// Проверка несохраненных изменений перед закрытием
  Future<bool> _checkUnsavedChanges() async {
    final state = ref.read(noteFormProvider);

    // Если нет изменений или не режим редактирования, можно закрывать
    if (!state.isEditMode || state.edited != true) {
      return true;
    }

    // Показываем диалог подтверждения
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Несохраненные изменения'),
        content: const Text(
          'У вас есть несохраненные изменения. Вы уверены, что хотите закрыть без сохранения?',
        ),
        actions: [
          SmoothButton(
            onPressed: () => Navigator.pop(context, false),
            label: 'Отмена',
            type: .outlined,
            variant: .error,
          ),
          SmoothButton(
            onPressed: () => Navigator.pop(context, true),
            type: .filled,
            variant: .error,
            label: 'Закрыть без сохранения',
          ),
        ],
      ),
    );

    return result ?? false;
  }

  /// Показать модальное окно со связями заметки
  void _showLinksModal() {
    if (!isEditMode || widget.noteId == null) return;

    WoltModalSheet.show(
      useRootNavigator: true,
      context: context,

      pageListBuilder: (modalSheetContext) => [
        SliverWoltModalSheetPage(
          hasTopBarLayer: true,
          isTopBarLayerAlwaysVisible: true,

          topBarTitle: Builder(
            builder: (context) {
              return Text(
                'Связи заметки',
                style: Theme.of(context).textTheme.titleMedium,
              );
            },
          ),
          mainContentSliversBuilder: (context) => [
            SliverToBoxAdapter(child: NoteLinksSection(noteId: widget.noteId!)),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(noteFormProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final canClose = await _checkUnsavedChanges();
        if (canClose && context.mounted) {
          context.pop(false);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(isEditMode ? 'Редактировать заметку' : 'Новая заметка'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              final canClose = await _checkUnsavedChanges();
              if (canClose && context.mounted) {
                context.pop(false);
              }
            },
          ),
          actions: [
            if (isEditMode)
              IconButton(
                icon: const Icon(Icons.link),
                tooltip: 'Связи заметки',
                onPressed: _showLinksModal,
              ),
            if (state.isSaving)
              const Padding(
                padding: EdgeInsets.all(12.0),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              IconButton(
                icon: const Icon(Icons.save),
                tooltip: 'Сохранить',
                onPressed: _handleSave,
              ),
          ],
        ),
        body: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Панель инструментов Quill
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      border: Border(
                        bottom: BorderSide(color: theme.dividerColor, width: 1),
                      ),
                    ),
                    child: QuillSimpleToolbar(
                      controller: _quillController,
                      config: QuillSimpleToolbarConfig(
                        showClipboardPaste: true,
                        multiRowsDisplay: false,
                        dialogTheme: QuillDialogTheme(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        customButtons: [
                          // Кастомная кнопка для ссылки на заметку
                          QuillToolbarCustomButtonOptions(
                            icon: const Icon(Icons.link),
                            tooltip: 'Ссылка на заметку',
                            onPressed: () async {
                              await _insertNoteLink();
                            },
                          ),
                        ],
                        buttonOptions: QuillSimpleToolbarButtonOptions(
                          base: QuillToolbarBaseButtonOptions(
                            afterButtonPressed: () {
                              // Возвращаем фокус в редактор после нажатия кнопки
                              _editorFocusNode.requestFocus();
                            },
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Редактор Quill
                  Expanded(
                    child: QuillEditor(
                      focusNode: _editorFocusNode,
                      scrollController: _editorScrollController,
                      controller: _quillController,
                      config: QuillEditorConfig(
                        placeholder: 'Начните писать заметку...',
                        padding: const EdgeInsets.all(16),
                        expands: true,
                        onLaunchUrl: (url) async {
                          logInfo('QuillEditor onLaunchUrl: $url');
                          // Перехватываем ссылки на заметки, чтобы не открывать в браузере
                          // Quill может добавить https:// перед note://

                          if (url.contains('note://')) {
                            final noteId = url.split('//').last;
                            _handleNoteLinkClick(noteId);
                          }
                          // Для обычных URL можно добавить url_launcher
                        },
                        onTapDown: (details, p1) {
                          // Обработка тапов
                          return false;
                        },
                        customStyles: DefaultStyles(
                          link: TextStyle(
                            color: theme.colorScheme.primary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
