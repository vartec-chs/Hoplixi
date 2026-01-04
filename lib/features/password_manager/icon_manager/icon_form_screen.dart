import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/main_store/models/dto/icon_dto.dart';
import 'package:hoplixi/main_store/models/enums/entity_types.dart';
import 'package:hoplixi/main_store/provider/dao_providers.dart';
import 'package:hoplixi/shared/ui/text_field.dart';
import 'package:image/image.dart' as img;

/// Экран для создания/редактирования иконки
class IconFormScreen extends ConsumerStatefulWidget {
  final String? iconId;
  final VoidCallback? onSuccess;

  const IconFormScreen({super.key, this.iconId, this.onSuccess});

  @override
  ConsumerState<IconFormScreen> createState() => _IconFormScreenState();
}

class _IconFormScreenState extends ConsumerState<IconFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late String _type;
  Uint8List? _iconData;
  String? _fileName;
  bool _isLoading = false;
  bool _isDataLoading = true;

  // Константы
  static const int _maxFileSizeBytes = 500 * 1024; // 500 KB
  static const int _targetImageSize = 256; // 256x256 px

  bool get _isEditMode => widget.iconId != null;

  @override
  void initState() {
    super.initState();
    // Инициализируем значения по умолчанию
    _name = '';
    _type = '';
    _loadData();
  }

  Future<void> _loadData() async {
    if (_isEditMode) {
      try {
        final iconDao = await ref.read(iconDaoProvider.future);
        final icon = await iconDao.getIconByIdNotData(widget.iconId!);
        logDebug('Loaded icon metadata: $icon');
        if (icon != null) {
          // Загружаем данные иконки
          final data = await iconDao.getIconData(widget.iconId!);

          if (data == null || data.isEmpty) {
            if (mounted) {
              Toaster.error(
                title: 'Ошибка загрузки данных иконки',
                description: 'Не удалось загрузить данные иконки',
              );
            }
          } else {
            setState(() {
              _name = icon.name;
              _type = icon.type;
              _iconData = data;
            });
          }
        } else {
          if (mounted) {
            Toaster.error(
              title: 'Ошибка загрузки иконки',
              description: 'Иконка не найдена',
            );
          }
        }
      } catch (e) {
        if (mounted) {
          Toaster.error(
            title: 'Ошибка загрузки иконки',
            description: e.toString(),
          );
        }
      }
    }
    setState(() {
      _isDataLoading = false;
    });
  }

  /// Обрезать изображение до 256x256
  Future<Uint8List> _resizeImage(Uint8List imageData) async {
    final image = img.decodeImage(imageData);
    if (image == null) {
      throw Exception('Не удалось декодировать изображение');
    }

    // Обрезаем изображение до 256x256 с сохранением пропорций
    final resized = img.copyResize(
      image,
      width: _targetImageSize,
      height: _targetImageSize,
      interpolation: img.Interpolation.linear,
    );

    // Кодируем обратно в PNG
    return Uint8List.fromList(img.encodePng(resized));
  }

  /// Проверить размер файла
  bool _checkFileSize(Uint8List data) {
    return data.length <= _maxFileSizeBytes;
  }

  /// Виджет для предпросмотра иконки
  Widget _buildIconPreview(Uint8List data, String type) {
    final isSvg = type == 'svg';

    if (isSvg) {
      return SvgPicture.memory(
        data,
        height: 80,
        width: 80,
        fit: BoxFit.contain,
        placeholderBuilder: (context) => const SizedBox(
          width: 80,
          height: 80,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    } else {
      return Image.memory(
        data,
        height: 80,
        width: 80,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.image, size: 80);
        },
      );
    }
  }

  /// Обработка выбора файла
  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['png', 'svg'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final data = file.bytes;

        if (data == null) {
          Toaster.error(
            title: 'Ошибка',
            description: 'Не удалось прочитать файл',
          );
          return;
        }

        if (!_checkFileSize(data)) {
          Toaster.error(
            title: 'Файл слишком большой',
            description: 'Максимальный размер файла: 500 КБ',
          );
          return;
        }

        String processedType = file.extension?.toLowerCase() ?? '';
        Uint8List processedData = data;

        // Обрабатываем PNG
        if (processedType == 'png') {
          try {
            processedData = await _resizeImage(data);
            processedType = 'png';
          } catch (e) {
            Toaster.error(
              title: 'Ошибка обработки изображения',
              description: e.toString(),
            );
            return;
          }
        } else if (processedType == 'svg') {
          processedType = 'svg';
        }

        setState(() {
          _iconData = processedData;
          _type = processedType;
          _fileName = file.name;
        });

        logDebug(
          'File selected: ${file.name}, Size: ${processedData.length} bytes, Type: $processedType',
        );
      }
    } catch (e) {
      Toaster.error(title: 'Ошибка выбора файла', description: e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isDataLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_isEditMode ? 'Редактировать иконку' : 'Создать иконку'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Редактировать иконку' : 'Создать иконку'),
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
                      // Название иконки
                      TextFormField(
                        initialValue: _name,
                        decoration: primaryInputDecoration(
                          context,
                          labelText: 'Название',
                          hintText: 'Введите название иконки',
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

                      // Выбор файла
                      OutlinedButton.icon(
                        onPressed: _pickFile,
                        icon: const Icon(Icons.upload_file),
                        label: Text(
                          _fileName ??
                              (_isEditMode
                                  ? 'Изменить файл (опционально)'
                                  : 'Выбрать файл'),
                        ),
                      ),

                      if (_fileName != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          '${_isEditMode ? 'Новый файл' : 'Выбран'}: $_fileName',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          'Поддерживаемые форматы: SVG, PNG (макс. 500 КБ)',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ] else ...[
                        const SizedBox(height: 8),
                        Text(
                          'Поддерживаемые форматы: SVG, PNG (макс. 500 КБ)',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        Text(
                          'PNG будет автоматически обрезан до 256x256 px',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],

                      if (_iconData != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          height: 100,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(context).dividerColor,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: _buildIconPreview(_iconData!, _type),
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    // Проверяем, что файл выбран (обязательно для создания, опционально для редактирования)
    if (!_isEditMode && _iconData == null) {
      Toaster.error(
        title: 'Ошибка',
        description: 'Пожалуйста, выберите файл иконки',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final iconDao = await ref.read(iconDaoProvider.future);

      if (_isEditMode) {
        // Режим редактирования
        final dto = UpdateIconDto(
          name: _name.trim(),
          type: _iconData != null
              ? _type
              : null, // Обновляем тип только если файл изменен
          data: _iconData,
        );

        await iconDao.updateIcon(widget.iconId!, dto);

        if (mounted) {
          Toaster.success(title: 'Иконка успешно обновлена');
          widget.onSuccess?.call();
          Navigator.of(context).pop(true);
        }
      } else {
        // Режим создания
        final dto = CreateIconDto(
          name: _name.trim(),
          type: IconTypeX.fromString(_type),
          data: _iconData!,
        );

        await iconDao.createIcon(dto);

        if (mounted) {
          Toaster.success(title: 'Иконка успешно создана');
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
