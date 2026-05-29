import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/password_manager/pickers/file_picker/file_picker_modal.dart';
import 'package:hoplixi/vault_db/providers/repository_providers.dart';
import 'package:hoplixi/shared/ui/text_field.dart';
import 'package:result_dart/result_dart.dart';

/// Поле формы для выбора файла из хранилища.
///
/// Открывает [showFilePickerModal] по клику или клавиатурному вводу.
/// Поддерживает автоматическую загрузку имени файла по [selectedFileId].
class FilePickerField extends ConsumerStatefulWidget {
  const FilePickerField({
    super.key,
    this.onFileSelected,
    this.selectedFileId,
    this.selectedFileName,
    this.label,
    this.hintText,
    this.enabled = true,
    this.focusNode,
    this.autofocus = false,
  });

  /// Коллбэк при выборе файла (id, name)
  final void Function(String? fileId, String? fileName)? onFileSelected;

  /// ID выбранного файла
  final String? selectedFileId;

  /// Отображаемое имя выбранного файла (опционально — загружается по id)
  final String? selectedFileName;

  /// Метка поля
  final String? label;

  /// Текст подсказки
  final String? hintText;

  /// Доступность поля
  final bool enabled;

  /// FocusNode для управления фокусом извне
  final FocusNode? focusNode;

  /// Автоматический фокус при монтировании
  final bool autofocus;

  @override
  ConsumerState<FilePickerField> createState() => _FilePickerFieldState();
}

class _FilePickerFieldState extends ConsumerState<FilePickerField> {
  late final FocusNode _internalFocusNode;
  FocusNode get _effectiveFocusNode => widget.focusNode ?? _internalFocusNode;

  /// Кэшированное имя файла, загруженное по id
  String? _resolvedFileName;
  bool _isResolvingFileName = false;

  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _internalFocusNode = FocusNode();
    _syncResolvedFileName();
  }

  @override
  void didUpdateWidget(covariant FilePickerField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedFileId != widget.selectedFileId ||
        oldWidget.selectedFileName != widget.selectedFileName) {
      _resolvedFileName = null;
      _isResolvingFileName = false;
      _syncResolvedFileName();
    }
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _internalFocusNode.dispose();
    }
    super.dispose();
  }

  void _handleTap() {
    if (!widget.enabled) return;
    _effectiveFocusNode.requestFocus();
    _openPicker();
  }

  void _handleClear() {
    if (!widget.enabled) return;
    widget.onFileSelected?.call(null, null);
    _effectiveFocusNode.requestFocus();
  }

  Future<void> _openPicker() async {
    final result = await showFilePickerModal(context, ref);
    if (result != null) {
      widget.onFileSelected?.call(result.id, result.name);
    }
  }

  Future<void> _syncResolvedFileName() async {
    final fileId = widget.selectedFileId;
    final fileName = widget.selectedFileName;

    if (fileName != null && fileName.isNotEmpty) {
      _resolvedFileName = fileName;
      _isResolvingFileName = false;
      return;
    }

    if (fileId == null || fileId.isEmpty) {
      _resolvedFileName = null;
      _isResolvingFileName = false;
      return;
    }

    if (!_isResolvingFileName && mounted) {
      setState(() => _isResolvingFileName = true);
    }

    final repos = await ref.read(vaultRepositories.future);
    final result = await repos.file.getCardById(fileId);
    final file = result.getOrNull()?.getOrNull();
    if (!mounted || widget.selectedFileId != fileId) return;

    setState(() {
      _resolvedFileName = file?.file.fileName ?? file?.item.name;
      _isResolvingFileName = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final effectiveLabel = widget.label ?? 'Выберите файл';
    final effectiveHint = widget.hintText ?? 'Выберите файл';

    // Определяем эффективное отображаемое имя файла
    String? effectiveFileName = widget.selectedFileName;

    if (widget.selectedFileId != null &&
        widget.selectedFileId!.isNotEmpty &&
        (widget.selectedFileName == null || widget.selectedFileName!.isEmpty)) {
      effectiveFileName =
          _resolvedFileName ?? (_isResolvingFileName ? 'Загрузка...' : null);
    }

    final hasValue = effectiveFileName != null && effectiveFileName.isNotEmpty;

    return Semantics(
      label: effectiveLabel,
      value: hasValue ? effectiveFileName : null,
      hint: hasValue ? null : effectiveHint,
      button: true,
      enabled: widget.enabled,
      focusable: widget.enabled,
      onTap: widget.enabled ? _openPicker : null,
      child: Focus(
        focusNode: _effectiveFocusNode,
        autofocus: widget.autofocus,
        canRequestFocus: widget.enabled,
        onKeyEvent: (node, event) {
          if (!widget.enabled) return KeyEventResult.ignored;

          if (event is KeyDownEvent &&
              (event.logicalKey == LogicalKeyboardKey.enter ||
                  event.logicalKey == LogicalKeyboardKey.space)) {
            _openPicker();
            return KeyEventResult.handled;
          }

          if (event is KeyDownEvent &&
              hasValue &&
              (event.logicalKey == LogicalKeyboardKey.delete ||
                  event.logicalKey == LogicalKeyboardKey.backspace)) {
            _handleClear();
            return KeyEventResult.handled;
          }

          return KeyEventResult.ignored;
        },
        child: AnimatedBuilder(
          animation: _effectiveFocusNode,
          builder: (context, child) {
            final isFocused = _effectiveFocusNode.hasFocus;

            return GestureDetector(
              onTap: _handleTap,
              behavior: HitTestBehavior.opaque,
              child: MouseRegion(
                cursor: widget.enabled
                    ? SystemMouseCursors.click
                    : SystemMouseCursors.basic,
                onEnter: (_) {
                  if (widget.enabled && !_isHovered) {
                    setState(() => _isHovered = true);
                  }
                },
                onExit: (_) {
                  if (_isHovered) setState(() => _isHovered = false);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeInOut,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: InputDecorator(
                    decoration: primaryInputDecoration(
                      context,
                      labelText: effectiveLabel,
                      hintText: hasValue ? null : effectiveHint,
                      enabled: widget.enabled,
                      isFocused: isFocused,
                      prefixIcon: Icon(
                        Icons.attach_file_outlined,
                        color: isFocused
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                      ),
                      suffixIcon: hasValue && widget.enabled
                          ? IconButton(
                              icon: Icon(
                                Icons.clear,
                                size: 20,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              onPressed: _handleClear,
                              tooltip: 'Очистить',
                            )
                          : null,
                    ),
                    child: IgnorePointer(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            hasValue ? effectiveFileName! : effectiveHint,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: hasValue
                                  ? colorScheme.onSurface
                                  : colorScheme.onSurface.withOpacity(0.6),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
