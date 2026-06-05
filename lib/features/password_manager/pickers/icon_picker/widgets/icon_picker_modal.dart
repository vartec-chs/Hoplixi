import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

import 'icon_picker_grid.dart';
import 'icon_picker_search_bar.dart';

/// Показать модальное окно выбора иконки
///
/// Возвращает ID выбранной иконки или null если пользователь отменил выбор
Future<String?> showIconPickerModal(BuildContext context, WidgetRef ref) async {
  String? selectedIconId;
  final searchQuery = ValueNotifier<String>('');

  try {
    await WoltModalSheet.show<void>(
      context: context,
      barrierDismissible: true,
      useSafeArea: true,
      useRootNavigator: true,
      pageListBuilder: (modalContext) {
        return [
          WoltModalSheetPage(
            surfaceTintColor: Colors.transparent,
            hasTopBarLayer: true,
            topBarTitle: Text(
              'Выбрать иконку',
              style: Theme.of(modalContext).textTheme.titleMedium,
            ),
            isTopBarLayerAlwaysVisible: true,
            leadingNavBarWidget: Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(modalContext).pop(),
                tooltip: 'Закрыть',
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: IconPickerSearchBar(
                    initialValue: searchQuery.value,
                    // если у тебя есть onChanged:
                    onChanged: (value) => searchQuery.value = value,
                  ),
                ),
                const Divider(height: 1),
                SizedBox(
                  height: MediaQuery.of(modalContext).size.height * 0.6,
                  child: ValueListenableBuilder<String>(
                    valueListenable: searchQuery,
                    builder: (context, query, _) {
                      return IconPickerGrid(
                        searchQuery: query,
                        onIconSelected: (iconId) {
                          selectedIconId = iconId;
                          Navigator.of(modalContext).pop();
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ];
      },
    );

    return selectedIconId;
  } finally {
    searchQuery.dispose();
  }
}
