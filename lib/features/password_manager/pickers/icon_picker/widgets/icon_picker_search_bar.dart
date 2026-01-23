import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/shared/ui/text_field.dart';
import '../provider/icon_picker_filter_provider.dart';

/// Виджет поля поиска для icon picker
class IconPickerSearchBar extends ConsumerStatefulWidget {
  const IconPickerSearchBar({super.key});

  @override
  ConsumerState<IconPickerSearchBar> createState() =>
      _IconPickerSearchBarState();
}

class _IconPickerSearchBarState extends ConsumerState<IconPickerSearchBar> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      decoration: primaryInputDecoration(
        context,
        hintText: 'Поиск иконок...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _controller.clear();
                  ref.read(iconPickerSearchProvider.notifier).clear();
                  setState(() {});
                },
              )
            : null,
      ),
      onChanged: (value) {
        ref.read(iconPickerSearchProvider.notifier).updateQuery(value);
        setState(() {}); // Обновляем для показа/скрытия кнопки очистки
      },
    );
  }
}
