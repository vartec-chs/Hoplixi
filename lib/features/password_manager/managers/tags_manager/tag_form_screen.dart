import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/dashboard/dashboard.dart';
import 'package:hoplixi/features/password_manager/managers/providers/manager_refresh_trigger_provider.dart';
import 'package:hoplixi/shared/ui/button.dart';
import 'package:hoplixi/shared/ui/text_field.dart';
import 'package:hoplixi/vault_db/core/models/dto/system/tag_dto.dart';
import 'package:hoplixi/vault_db/core/models/field_update.dart';
import 'package:hoplixi/vault_db/providers/repository_providers.dart';

/// Экран для создания/редактирования тега
class TagFormScreen extends ConsumerStatefulWidget {
  final String? tagId;
  final VoidCallback? onSuccess;
  final EntityType? entityType;

  const TagFormScreen({super.key, this.tagId, this.onSuccess, this.entityType});

  @override
  ConsumerState<TagFormScreen> createState() => _TagFormScreenState();
}

class _TagFormScreenState extends ConsumerState<TagFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  Color? _selectedColor;
  bool _isLoading = false;
  bool _isDataLoading = true;

  bool get _isEditMode => widget.tagId != null;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (_isEditMode) {
      try {
        final repositories = await ref.read(vaultRepositories.future);
        final tagResult = await repositories.tag.getTag(widget.tagId!);
        final tag = tagResult.getOrNull()?.getOrNull();
        if (tag != null) {
          setState(() {
            _name = tag.name;
            _selectedColor = Color(0xFF000000 | tag.color);
          });
        }
      } catch (e) {
        if (mounted) {
          Toaster.error(
            title: 'Ошибка загрузки тега',
            description: e.toString(),
          );
        }
      }
    } else {
      // Режим создания - значения по умолчанию
      _name = '';
      _selectedColor = null;
    }
    setState(() {
      _isDataLoading = false;
    });
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        Color pickerColor = _selectedColor ?? Colors.blue;
        return AlertDialog(
          title: const Text('Выберите цвет'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: pickerColor,
              onColorChanged: (Color color) {
                pickerColor = color;
              },
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: [
            SmoothButton(
              type: SmoothButtonType.text,
              variant: SmoothButtonVariant.error,
              onPressed: () => Navigator.of(context).pop(),
              label: 'Отмена',
            ),
            SmoothButton(
              onPressed: () {
                setState(() {
                  _selectedColor = pickerColor;
                });
                Navigator.of(context).pop();
              },
              label: 'Выбрать',
              type: SmoothButtonType.filled,
              variant: SmoothButtonVariant.normal,
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isDataLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_isEditMode ? 'Редактировать тег' : 'Создать тег'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Редактировать тег' : 'Создать тег'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(icon: const Icon(Icons.save), onPressed: _handleSubmit),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Название тега
                  TextFormField(
                    initialValue: _name,
                    decoration: primaryInputDecoration(
                      context,
                      labelText: 'Название',
                      hintText: 'Введите название тега',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Пожалуйста, введите название';
                      }
                      return null;
                    },
                    onChanged: (value) => _name = value,
                  ),
                  const SizedBox(height: 16),

                  // Выбор цвета
                  InputDecorator(
                    decoration: primaryInputDecoration(
                      context,
                      labelText: 'Цвет тега',
                      hintText: 'Нажмите для выбора цвета',
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _showColorPicker,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _selectedColor != null
                                  ? 'Цвет выбран'
                                  : 'Выберите цвет',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color:
                                    _selectedColor ?? Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.outline,
                                  width: 1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final repositories = await ref.read(vaultRepositories.future);
      final colorInt = _selectedColor?.toARGB32() ?? 0xFFFFFF;

      if (_isEditMode) {
        // Режим редактирования
        final dto = PatchTagDto(
          id: widget.tagId!,
          name: FieldUpdate.set(_name.trim()),
          color: FieldUpdate.set(colorInt),
        );

        final result = await repositories.tag.updateTag(dto);
        result.getOrThrow();

        // Уведомляем об обновлении тега
        ref.read(managerRefreshTriggerProvider.notifier).triggerTagRefresh();

        if (mounted) {
          Toaster.success(title: 'Тег успешно обновлен');
          widget.onSuccess?.call();
          Navigator.of(context).pop(true);
        }
      } else {
        // Режим создания
        final dto = CreateTagDto(
          name: _name.trim(),
          color: colorInt,
        );

        final result = await repositories.tag.createTag(dto);
        result.getOrThrow();

        // Уведомляем о создании тега
        ref.read(managerRefreshTriggerProvider.notifier).triggerTagRefresh();

        if (mounted) {
          Toaster.success(title: 'Тег успешно создан');
          widget.onSuccess?.call();
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        Toaster.error(title: 'Ошибка', description: e.toString());
      }
    }
  }
}
