import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/password_manager/managers/category_manager/providers/category_filter_provider.dart';
import 'package:hoplixi/shared/ui/button.dart';
import 'package:hoplixi/shared/ui/text_field.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

import '../models/category_manager_filter.dart';

int countCategoryManagerFilters(CategoryManagerFilter filter) {
  var count = 0;
  if (filter.color != null) {
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
  CategoryManagerFilter filter,
) async {
  int? selectedColor = filter.color;
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
                      const SizedBox(height: 20),
                      InputDecorator(
                        decoration: primaryInputDecoration(
                          context,
                          labelText: 'Цвет',
                          hintText: 'Нажмите, чтобы выбрать',
                          prefixIcon: const Icon(Icons.palette_outlined),
                        ),
                        child: InkWell(
                          onTap: () async {
                            final pickedColor = await _showCategoryColorPicker(
                              context,
                              initialColor: selectedColor != null
                                  ? Color(0xFF000000 | selectedColor!)
                                  : Theme.of(context).colorScheme.primary,
                            );
                            if (pickedColor == null) {
                              return;
                            }

                            setModalState(() {
                              selectedColor = pickedColor.toARGB32() & 0xFFFFFF;
                            });
                          },
                          child: Row(
                            children: [
                              if (selectedColor != null)
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: Color(0xFF000000 | selectedColor!),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              const SizedBox(width: 8),
                              Text(selectedColor != null ? 'Выбран' : 'Любой'),
                              const Spacer(),
                              if (selectedColor != null)
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: const Icon(Icons.close, size: 16),
                                  onPressed: () {
                                    setModalState(() {
                                      selectedColor = null;
                                    });
                                  },
                                ),
                            ],
                          ),
                        ),
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
                                setModalState(() {
                                  selectedColor = null;
                                  hasIcon = null;
                                  hasDescription = null;
                                });
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
                                        color: selectedColor,
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
  } finally {}
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
          SmoothButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            label: 'Отмена',
            type: SmoothButtonType.text,
          ),
          SmoothButton(
            onPressed: () => Navigator.of(dialogContext).pop(pickerColor),
            label: 'Выбрать',
          ),
        ],
      );
    },
  );
}
