import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/dashboard/dashboard.dart';
import 'package:hoplixi/features/password_manager/managers/providers/manager_refresh_trigger_provider.dart';
import 'package:hoplixi/features/password_manager/pickers/category_picker/widgets/category_picker_field.dart';
import 'package:hoplixi/routing/paths.dart';
import 'package:hoplixi/shared/ui/button.dart';
import 'package:hoplixi/shared/ui/text_field.dart';
import 'package:hoplixi/shared/widgets/icon_source_picker_button.dart';
import 'package:hoplixi/vault_db/core/models/dto/system/category_dto.dart';
import 'package:hoplixi/vault_db/core/models/dto/system/icon_dto.dart';
import 'package:hoplixi/vault_db/core/models/dto/system/icon_ref_dto.dart';
import 'package:hoplixi/vault_db/core/models/field_update.dart';
import 'package:hoplixi/vault_db/providers/providers.dart';

/// Экран для создания/редактирования категории
class CategoryFormScreen extends ConsumerStatefulWidget {
  final String? categoryId;
  final VoidCallback? onSuccess;
  final EntityType forEntity;

  const CategoryFormScreen({
    super.key,
    this.categoryId,
    this.onSuccess,
    required this.forEntity,
  });

  @override
  ConsumerState<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends ConsumerState<CategoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  Color? _selectedColor;
  IconRefDto? _iconRef;
  String? _parentId;
  String? _parentName;
  bool _isLoading = false;
  bool _isDataLoading = true;

  bool get _isEditMode => widget.categoryId != null;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (_isEditMode) {
      try {
        final repos = await ref.read(vaultRepositories.future);
        final categoryResult = await repos.category.getCategory(
          widget.categoryId!,
        );
        final category = categoryResult.getOrNull()?.getOrNull();

        if (category != null) {
          String? parentName;
          if (category.parentId != null) {
            final parentResult = await repos.category.getCategory(
              category.parentId!,
            );
            parentName = parentResult.getOrNull()?.getOrNull()?.name;
          }

          IconRefDto? iconRef;
          if (category.iconRefId != null) {
            final iconResult = await repos.icon.getIconRef(category.iconRefId!);
            final viewDto = iconResult.getOrNull()?.getOrNull();
            if (viewDto != null) {
              iconRef = IconRefDto(
                id: viewDto.id,
                iconSourceType: viewDto.iconSourceType,
                iconPackId: viewDto.iconPackId,
                iconValue: viewDto.iconValue,
                customIconId: viewDto.customIconId,
                color: viewDto.color,
                backgroundColor: viewDto.backgroundColor,
                createdAt: viewDto.createdAt,
                modifiedAt: viewDto.modifiedAt,
              );
            }
          }

          setState(() {
            _name = category.name;
            _iconRef = iconRef;
            _parentId = category.parentId;
            _parentName = parentName;
            _selectedColor = Color(0xFF000000 | category.color);
          });
        }
      } catch (e) {
        if (mounted) {
          Toaster.error(
            title: 'Ошибка загрузки категории',
            description: e.toString(),
          );
        }
      }
    } else {
      _name = '';
      _iconRef = null;
      _selectedColor = null;
      _parentId = null;
      _parentName = null;
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
              enableAlpha: false,
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

  Future<bool> _handleBeforeIconPickerOpen(BuildContext context) async {
    try {
      final repos = await ref.read(vaultRepositories.future);
      final icons = await repos.icon.getCustomIcons();

      if (icons.getOrNull()?.isNotEmpty ?? false) {
        return true;
      }

      if (!context.mounted) {
        return false;
      }

      final shouldCreate = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Иконки не найдены'),
            content: const Text(
              'Для категории пока нет доступных иконок. Создать новую иконку сейчас?',
            ),
            actions: [
              SmoothButton(
                type: SmoothButtonType.text,
                variant: SmoothButtonVariant.error,
                onPressed: () => Navigator.of(dialogContext).pop(false),
                label: 'Нет',
              ),
              SmoothButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                label: 'Создать',
                type: SmoothButtonType.filled,
                variant: SmoothButtonVariant.normal,
              ),
            ],
          );
        },
      );

      if (shouldCreate != true || !context.mounted) {
        return false;
      }

      final created = await context.push<bool>(
        AppRoutesPaths.iconAddForEntity(widget.forEntity),
      );

      return created == true;
    } catch (e) {
      if (context.mounted) {
        Toaster.error(
          title: 'Ошибка загрузки иконок',
          description: e.toString(),
        );
      }
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isDataLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            _isEditMode ? 'Редактировать категорию' : 'Создать категорию',
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditMode ? 'Редактировать категорию' : 'Создать категорию',
        ),
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
                  // Выбор иконки
                  Center(
                    child: IconSourcePickerButton(
                      iconRef: _iconRef,
                      fallbackIcon: Icons.folder_outlined,
                      title: 'Иконка категории',
                      subtitle:
                          'Выберите пользовательскую иконку или SVG из импортированного пака.',
                      onBeforeOpenDbPicker: _handleBeforeIconPickerOpen,
                      onChanged: (iconRef) {
                        setState(() {
                          _iconRef = iconRef;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Название категории
                  TextFormField(
                    initialValue: _name,
                    decoration: primaryInputDecoration(
                      context,
                      labelText: 'Название',
                      hintText: 'Введите название категории',
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

                  // Родительская категория
                  CategoryPickerField(
                    label: 'Родительская категория',
                    hintText: 'Выберите родителя (необязательно)',
                    selectedCategoryId: _parentId,
                    selectedCategoryName: _parentName,
                    onCategorySelected: (id, name) {
                      setState(() {
                        _parentId = id;
                        _parentName = name;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Выбор цвета
                  InputDecorator(
                    decoration: primaryInputDecoration(
                      context,
                      labelText: 'Цвет категории',
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
                                color: _selectedColor ?? Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.outline,
                                  width: 1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
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
      final repos = await ref.read(vaultRepositories.future);

      // Сначала разбираемся с IconRef
      String? iconRefId;
      if (_iconRef != null) {
        // Если иконка выбрана, создаем IconRef если это новый
        if (_iconRef!.id == null) {
          final createIconRefDto = CreateIconRefDto(
            iconSourceType: _iconRef!.iconSourceType,
            iconPackId: _iconRef!.iconPackId,
            iconValue: _iconRef!.iconValue,
            customIconId: _iconRef!.customIconId,
          );
          final res = await repos.icon.createIconRef(createIconRefDto);
          iconRefId = res.getOrThrow();
        } else {
          iconRefId = _iconRef!.id;
        }
      }

      final colorInt = (_selectedColor?.toARGB32() ?? 0xFFFFFF) & 0xFFFFFF;

      if (_isEditMode) {
        final dto = PatchCategoryDto(
          id: widget.categoryId!,
          name: FieldUpdate.set(_name.trim()),
          iconRefId: FieldUpdate.set(iconRefId),
          color: FieldUpdate.set(colorInt),
          parentId: FieldUpdate.set(_parentId),
        );

        final result = await repos.category.updateCategory(dto);
        result.getOrThrow();

        ref
            .read(managerRefreshTriggerProvider.notifier)
            .triggerCategoryRefresh();

        if (mounted) {
          Toaster.success(title: 'Категория успешно обновлена');
          widget.onSuccess?.call();
          Navigator.of(context).pop(true);
        }
      } else {
        final dto = CreateCategoryDto(
          name: _name.trim(),
          iconRefId: iconRefId,
          color: colorInt,
          parentId: _parentId,
        );

        final result = await repos.category.createCategory(dto);
        result.getOrThrow();

        ref
            .read(managerRefreshTriggerProvider.notifier)
            .triggerCategoryRefresh();

        if (mounted) {
          Toaster.success(title: 'Категория успешно создана');
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
