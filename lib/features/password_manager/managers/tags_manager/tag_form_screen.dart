import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/features/password_manager/managers/tags_manager/providers/tag_filter_provider.dart';
import 'package:hoplixi/main_store/models/dto/tag_dto.dart';
import 'package:hoplixi/main_store/models/enums/entity_types.dart';
import 'package:hoplixi/main_store/provider/dao_providers.dart';
import 'package:hoplixi/shared/ui/button.dart';
import 'package:hoplixi/shared/ui/text_field.dart';

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
  late TagType _selectedType;
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
        final tagDao = await ref.read(tagDaoProvider.future);
        final tag = await tagDao.getTagById(widget.tagId!);
        if (tag != null) {
          setState(() {
            _name = tag.name;
            _selectedType = tag.type;

            // Конвертируем HEX строку в Color если есть
            if (tag.color.isNotEmpty) {
              try {
                final hexColor = tag.color.replaceAll('#', '');
                _selectedColor = Color(int.parse('FF$hexColor', radix: 16));
              } catch (e) {
                _selectedColor = null;
              }
            }
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
      _selectedType = widget.entityType != null
          ? _convertEntityTypeToTagType(widget.entityType!)
          : TagType.mixed;
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
        child: Column(
          children: [
            Center(
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

                      // Тип тега
                      if (_isEditMode)
                        // В режиме редактирования - только для чтения
                        TextFormField(
                          initialValue: _getTagTypeLabel(_selectedType),
                          decoration: primaryInputDecoration(
                            context,
                            labelText: 'Тип тега',
                          ),
                          enabled: false,
                        )
                      else
                        // В режиме создания - dropdown
                        DropdownButtonFormField<TagType>(
                          value: _selectedType,
                          decoration: primaryInputDecoration(
                            context,
                            labelText: 'Тип тега',
                          ),
                          items: TagType.values.map((type) {
                            return DropdownMenuItem(
                              value: type,
                              child: Text(_getTagTypeLabel(type)),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedType = value;
                              });
                            }
                          },
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
          ],
        ),
      ),
    );

    // Кнопки действий внизу
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final tagDao = await ref.read(tagDaoProvider.future);

      // Конвертируем Color в HEX строку без альфа-канала
      String? colorHex;
      if (_selectedColor != null) {
        colorHex = _selectedColor!
            .toARGB32()
            .toRadixString(16)
            .substring(2)
            .toUpperCase();
      }

      if (_isEditMode) {
        // Режим редактирования
        final dto = UpdateTagDto(name: _name.trim(), color: colorHex);

        await tagDao.updateTag(widget.tagId!, dto);

        // Уведомляем об обновлении тега
        ref
            .read(tagFilterProvider.notifier)
            .notifyTagUpdated(tagId: widget.tagId);

        if (mounted) {
          Toaster.success(title: 'Тег успешно обновлен');
          widget.onSuccess?.call();
          Navigator.of(context).pop(true);
        }
      } else {
        // Режим создания
        final dto = CreateTagDto(
          name: _name.trim(),
          type: _selectedType.value,
          color: colorHex,
        );

        final createdTagId = await tagDao.createTag(dto);

        // Уведомляем о создании тега
        ref
            .read(tagFilterProvider.notifier)
            .notifyTagAdded(tagId: createdTagId);

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

/// Получить человекочитаемое название типа тега
String _getTagTypeLabel(TagType type) {
  switch (type) {
    case TagType.note:
      return 'Заметки';
    case TagType.password:
      return 'Пароли';
    case TagType.totp:
      return 'TOTP коды';
    case TagType.bankCard:
      return 'Банковские карты';
    case TagType.file:
      return 'Файлы';
    case TagType.document:
      return 'Документы';
    case TagType.mixed:
      return 'Смешанная';
  }
}

/// Преобразовать EntityType в TagType
TagType _convertEntityTypeToTagType(EntityType entityType) {
  switch (entityType) {
    case EntityType.password:
      return TagType.password;
    case EntityType.note:
      return TagType.note;
    case EntityType.bankCard:
      return TagType.bankCard;
    case EntityType.file:
      return TagType.file;
    case EntityType.otp:
      return TagType.totp;
    case EntityType.document:
      return TagType.document;
  }
}
