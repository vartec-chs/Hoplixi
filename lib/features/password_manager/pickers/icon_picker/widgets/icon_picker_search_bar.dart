import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hoplixi/shared/ui/text_field.dart';

/// Виджет поля поиска для icon picker
class IconPickerSearchBar extends StatefulWidget {
  final ValueChanged<String> onChanged;
  final String initialValue;

  const IconPickerSearchBar({
    super.key,
    required this.onChanged,
    this.initialValue = '',
  });

  @override
  State<IconPickerSearchBar> createState() => _IconPickerSearchBarState();
}

class _IconPickerSearchBarState extends State<IconPickerSearchBar> {
  late final TextEditingController _controller;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      widget.onChanged(value);
    });
    setState(() {}); // Для обновления кнопки очистки
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
                  _onSearchChanged('');
                },
              )
            : null,
      ),
      onChanged: _onSearchChanged,
    );
  }
}
