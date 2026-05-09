import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/logger/logger.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/dashboard_v2/dashboard_v2.dart';
import 'package:hoplixi/features/password_manager/dashboard_v2/providers/dashboard_list_refresh_trigger_provider.dart';
import 'package:hoplixi/features/password_manager/forms/note_form/models/note_form_state.dart';
import 'package:hoplixi/features/password_manager/forms/note_form/widgets/expandable_quill_modal.dart';
import 'package:hoplixi/features/password_manager/pickers/vault_item_picker/vault_item_picker_modal.dart';
import 'package:hoplixi/shared/ui/button.dart';
import 'package:hoplixi/shared/ui/modal_sheet_close_button.dart';
import 'package:hoplixi/shared/utils/vault_link_utils.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

import '../providers/note_form_provider.dart';
import '../widgets/note_links_section.dart';
import '../widgets/note_metadata_modal.dart';

/// Экран формы создания/редактирования заметки
/// Основной интерфейс - QuillEditor для редактирования контента
/// Быстрое сохранение сохраняет без метаданных, кнопка настроек открывает модальное окно
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

    // В режиме создания мгновенно обновляем title из первой строки
    if (!isEditMode) {
      final plainText = _quillController.document.toPlainText();
      final firstLine = plainText.split('\n').first.trim();
      final currentState = ref.read(noteFormProvider);
      if (firstLine != currentState.title) {
        ref.read(noteFormProvider.notifier).setTitle(firstLine);
      }
    }
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

  /// Вставить ссылку на объект хранилища
  Future<void> _insertNoteLink() async {
    final result = await showVaultItemPickerModal(
      context,
      ref,
      excludeItemId: widget.noteId,
    );

    if (result == null) return;

    // Получаем текущую позицию курсора
    final selection = _quillController.selection;
    final index = selection.baseOffset;
    final length = selection.extentOffset - index;

    // Создаем текст ссылки
    final linkText = result.name;

    final linkUrl = buildVaultItemLinkUrl(
      entityId: result.vaultItemType.toEntityType().id,
      itemId: result.id,
    );

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

    logInfo('Добавлена ссылка на объект: ${result.id}');
  }

  /// Быстрое сохранение без открытия модального окна
  void _handleQuickSave() async {
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

    // Для режима создания: если заголовок пустой, берем первую строку
    if (!isEditMode && state.title.isEmpty) {
      final firstLine = state.content.split('\n').first.trim();
      if (firstLine.isNotEmpty) {
        ref.read(noteFormProvider.notifier).setTitle(firstLine);
      }
    }

    // Сохраняем
    final success = await ref.read(noteFormProvider.notifier).save();

    if (!mounted) return;

    if (success) {
      Toaster.success(
        title: isEditMode ? 'Заметка обновлена' : 'Заметка создана',
        description: 'Изменения успешно сохранены',
      );
      context.pop(true);

      if (isEditMode) {
        logInfo('Заметка отредактирована: ${widget.noteId}');
        DataRefreshHelper.refreshNotes(ref);
      } else {
        logInfo('Создана новая заметка');
        DataRefreshHelper.refreshNotes(ref);
      }
    } else {
      Toaster.error(
        title: 'Ошибка сохранения',
        description: 'Не удалось сохранить заметку',
      );
    }
  }

  /// Показать модальное окно настроек
  void _handleSettings() async {
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

  /// Обработка клика по внутренней ссылке note/vault.
  void _handleVaultLinkClick(ParsedVaultLink link) {
    // Сначала сохраняем текущую заметку (если есть изменения)
    _updateStateFromController();

    final entityType = link.isLegacyNoteLink
        ? EntityType.note
        : EntityType.fromId(link.entityId!);
    if (entityType == null) {
      return;
    }

    // Показываем диалог с опциями
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Открыть ${entityType.label.toLowerCase()}'),
        content: const Text(
          'Хотите открыть связанную запись? Текущие несохраненные изменения останутся.',
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
              context.pushNamed(
                'entity_edit',
                pathParameters: {'entity': entityType.id, 'id': link.itemId},
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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: [
              SmoothButton(
                onPressed: () => Navigator.pop(context, false),
                label: 'Отмена',
                type: .text,
              ),

              SmoothButton(
                onPressed: () => Navigator.pop(context, true),
                type: .filled,
                variant: .error,
                label: 'Закрыть без сохранения',
              ),
            ],
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
          leadingNavBarWidget: const Padding(
            padding: EdgeInsets.only(left: 8.0),
            child: ModalSheetCloseButton(),
          ),

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

  Future<void> _handleQuillLaunchUrl(String url) async {
    logInfo('QuillEditor onLaunchUrl: $url');
    final link = parseVaultLink(url);
    if (link != null) {
      _handleVaultLinkClick(link);
    }
  }

  void _openExpandedEditorModal() {
    final state = ref.read(noteFormProvider);
    final title = state.title.trim().isEmpty ? 'Заметки' : state.title.trim();

    showQuillEditorModal(
      context: context,
      controller: _quillController,
      title: title,
      toolbar: _buildQuillToolbar(focusNode: null),
      onLaunchUrl: _handleQuillLaunchUrl,
    );
  }

  Widget _buildQuillToolbar({required FocusNode? focusNode}) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.dividerColor, width: 1)),
      ),
      child: QuillSimpleToolbar(
        controller: _quillController,
        config: QuillSimpleToolbarConfig(
          showClipboardPaste: true,
          multiRowsDisplay: false,
          decoration: const BoxDecoration(color: Colors.transparent),
          toolbarSize: 40,
          dialogTheme: QuillDialogTheme(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            dialogBackgroundColor: theme.colorScheme.surface,
          ),
          customButtons: [
            QuillToolbarCustomButtonOptions(
              icon: const Icon(Icons.link),
              tooltip: 'Ссылка на объект',
              onPressed: () async {
                await _insertNoteLink();
              },
            ),
          ],
          buttonOptions: QuillSimpleToolbarButtonOptions(
            base: QuillToolbarBaseButtonOptions(
              afterButtonPressed: () {
                focusNode?.requestFocus();
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuillEditor({
    required FocusNode focusNode,
    required ScrollController scrollController,
  }) {
    final theme = Theme.of(context);

    return QuillEditor(
      focusNode: focusNode,
      scrollController: scrollController,
      controller: _quillController,
      config: QuillEditorConfig(
        placeholder: 'Начните писать заметку...',
        padding: const EdgeInsets.all(12),
        expands: true,
        dialogTheme: QuillDialogTheme(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          dialogBackgroundColor: theme.colorScheme.surface,
        ),
        onLaunchUrl: _handleQuillLaunchUrl,
        onTapDown: (details, p1) {
          return false;
        },
        customStyles: DefaultStyles(
          link: TextStyle(
            color: theme.colorScheme.primary,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          title: Text(
            isEditMode
                ? state.title
                : state.title.isNotEmpty
                ? state.title
                : 'Создать заметку',
          ),
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
            IconButton(
              icon: const Icon(Icons.open_in_full),
              tooltip: 'Развернуть редактор',
              onPressed: _openExpandedEditorModal,
            ),
            IconButton(
              icon: Icon(
                _quillController.readOnly ? Icons.edit : Icons.visibility,
              ),
              tooltip: _quillController.readOnly
                  ? 'Режим редактирования'
                  : 'Режим просмотра',
              onPressed: () {
                setState(() {
                  _quillController.readOnly = !_quillController.readOnly;
                });
              },
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
            else ...[
              IconButton(
                icon: const Icon(Icons.save),
                tooltip: 'Быстрое сохранение',
                onPressed: _handleQuickSave,
              ),
              IconButton(
                icon: const Icon(Icons.settings),
                tooltip: 'Настройки',
                onPressed: _handleSettings,
              ),
            ],
          ],
        ),
        body: SafeArea(
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    // Панель инструментов Quill
                    _buildQuillToolbar(focusNode: _editorFocusNode),

                    // Редактор Quill
                    Expanded(
                      child: _buildQuillEditor(
                        focusNode: _editorFocusNode,
                        scrollController: _editorScrollController,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
