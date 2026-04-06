import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/password_manager/managers/category_manager/providers/category_filter_provider.dart';
import 'package:hoplixi/main_store/models/enums/index.dart';
import 'package:hoplixi/main_store/models/filter/categories_filter.dart';
import 'package:hoplixi/shared/ui/button.dart';
import 'package:hoplixi/shared/ui/text_field.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

int countCategoryManagerFilters(CategoriesFilter filter) {
  var count = 0;
  count += filter.types.whereType<CategoryType>().length;
  if (filter.color != null && filter.color!.trim().isNotEmpty) {
    count++;
  }
  if (filter.hasIcon != null) {
    count++;
  }
  if (filter.hasDescription != null) {
    count++;
  }
  return count;
}

Future<void> showCategoryManagerFilterSheet(
  BuildContext context,
  WidgetRef ref,
  CategoriesFilter filter,
) async {
  final selectedTypes = filter.types.whereType<CategoryType>().toSet();
  final colorController = TextEditingController(text: filter.color ?? '');
  var hasIcon = filter.hasIcon;
  var hasDescription = filter.hasDescription;

  try {
    await WoltModalSheet.show<void>(
      useRootNavigator: true,
      context: context,
      barrierDismissible: true,
      pageListBuilder: (modalSheetContext) => [
        WoltModalSheetPage(
          hasTopBarLayer: true,
          isTopBarLayerAlwaysVisible: true,
          surfaceTintColor: Colors.transparent,
          topBarTitle: Text(
            'Фильтрация категорий',
            style: Theme.of(modalSheetContext).textTheme.titleMedium,
          ),
          leadingNavBarWidget: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(modalSheetContext).pop(),
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return SafeArea(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 8,
                    bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Типы',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final type in CategoryType.values)
                            FilterChip(
                              label: Text(categoryTypeLabel(type)),
                              selected: selectedTypes.contains(type),
                              onSelected: (selected) {
                                setModalState(() {
                                  if (selected) {
                                    selectedTypes.add(type);
                                  } else {
                                    selectedTypes.remove(type);
                                  }
                                });
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: colorController,
                        readOnly: true,
                        decoration: primaryInputDecoration(
                          context,
                          labelText: 'Цвет',
                          hintText: 'Нажмите, чтобы выбрать',
                          prefixIcon: const Icon(Icons.palette_outlined),
                          suffixIcon: colorController.text.trim().isNotEmpty
                              ? IconButton(
                                  tooltip: 'Сбросить цвет',
                                  onPressed: () {
                                    colorController.clear();
                                    setModalState(() {});
                                  },
                                  icon: const Icon(Icons.close_rounded),
                                )
                              : null,
                        ),
                        onTap: () async {
                          final pickedColor = await _showCategoryColorPicker(
                            context,
                            initialColor:
                                _parseFilterColor(colorController.text) ??
                                Theme.of(context).colorScheme.primary,
                          );
                          if (pickedColor == null) {
                            return;
                          }

                          colorController.text = _colorToFilterHex(pickedColor);
                          setModalState(() {});
                        },
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Иконка',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('Любые'),
                            selected: hasIcon == null,
                            onSelected: (_) =>
                                setModalState(() => hasIcon = null),
                          ),
                          ChoiceChip(
                            label: const Text('Только с иконкой'),
                            selected: hasIcon == true,
                            onSelected: (_) =>
                                setModalState(() => hasIcon = true),
                          ),
                          ChoiceChip(
                            label: const Text('Только без иконки'),
                            selected: hasIcon == false,
                            onSelected: (_) =>
                                setModalState(() => hasIcon = false),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Описание',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('Любые'),
                            selected: hasDescription == null,
                            onSelected: (_) =>
                                setModalState(() => hasDescription = null),
                          ),
                          ChoiceChip(
                            label: const Text('Только с описанием'),
                            selected: hasDescription == true,
                            onSelected: (_) =>
                                setModalState(() => hasDescription = true),
                          ),
                          ChoiceChip(
                            label: const Text('Только без описания'),
                            selected: hasDescription == false,
                            onSelected: (_) =>
                                setModalState(() => hasDescription = false),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: SmoothButton(
                              onPressed: () {
                                selectedTypes.clear();
                                colorController.clear();
                                hasIcon = null;
                                hasDescription = null;
                                setModalState(() {});
                              },
                              label: 'Сбросить',
                              type: SmoothButtonType.text,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SmoothButton(
                              onPressed: () {
                                ref
                                    .read(categoryFilterProvider.notifier)
                                    .updateFilter(
                                      filter.copyWith(
                                        types: selectedTypes
                                            .cast<CategoryType?>()
                                            .toList(growable: false),
                                        color:
                                            colorController.text.trim().isEmpty
                                            ? null
                                            : colorController.text.trim(),
                                        hasIcon: hasIcon,
                                        hasDescription: hasDescription,
                                      ),
                                    );
                                Navigator.of(modalSheetContext).pop();
                              },
                              label: 'Применить',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  } finally {
    colorController.dispose();
  }
}

Future<Color?> _showCategoryColorPicker(
  BuildContext context, {
  required Color initialColor,
}) {
  var pickerColor = initialColor;

  return showDialog<Color>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Выберите цвет'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: pickerColor,
            onColorChanged: (color) => pickerColor = color,
            pickerAreaHeightPercent: 0.8,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(pickerColor),
            child: const Text('Выбрать'),
          ),
        ],
      );
    },
  );
}

Color? _parseFilterColor(String? colorHex) {
  final normalized = colorHex?.replaceAll('#', '').trim();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }

  final value = int.tryParse(normalized, radix: 16);
  if (value == null) {
    return null;
  }

  return Color(0xFF000000 | value);
}

String _colorToFilterHex(Color color) {
  return color.value.toRadixString(16).substring(2).toUpperCase();
}

String categoryTypeLabel(CategoryType type) {
  return switch (type) {
    CategoryType.note => 'Заметки',
    CategoryType.password => 'Пароли',
    CategoryType.totp => 'TOTP',
    CategoryType.bankCard => 'Банковские карты',
    CategoryType.file => 'Файлы',
    CategoryType.document => 'Документы',
    CategoryType.contact => 'Контакты',
    CategoryType.apiKey => 'API ключи',
    CategoryType.sshKey => 'SSH ключи',
    CategoryType.certificate => 'Сертификаты',
    CategoryType.cryptoWallet => 'Криптокошельки',
    CategoryType.wifi => 'Wi-Fi',
    CategoryType.identity => 'Профили',
    CategoryType.licenseKey => 'Лицензионные ключи',
    CategoryType.recoveryCodes => 'Коды восстановления',
    CategoryType.loyaltyCard => 'Карты лояльности',
    CategoryType.mixed => 'Смешанные',
  };
}
