import 'package:flutter/material.dart';
import 'package:hoplixi/shared/ui/text_field.dart';

/// Виджет поиска для экрана истории
class HistorySearchBar extends StatefulWidget {
  const HistorySearchBar({
    super.key,
    required this.onSearchChanged,
    required this.onClear,
    this.initialQuery = '',
  });

  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClear;
  final String initialQuery;

  @override
  State<HistorySearchBar> createState() => _HistorySearchBarState();
}

class _HistorySearchBarState extends State<HistorySearchBar> {
  late final TextEditingController _controller;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
    _hasText = widget.initialQuery.isNotEmpty;
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _controller.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
    widget.onSearchChanged(_controller.text);
  }

  void _clearSearch() {
    _controller.clear();
    widget.onClear();
  }

  @override
  Widget build(BuildContext context) {
    return PrimaryTextField(
      controller: _controller,
      hintText: 'Поиск в истории...',
      prefixIcon: const Icon(Icons.search),
      suffixIcon: _hasText
          ? IconButton(
              icon: const Icon(Icons.close),
              onPressed: _clearSearch,
              tooltip: 'Очистить поиск',
            )
          : null,
    );
  }
}
