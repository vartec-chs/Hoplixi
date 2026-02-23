import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/localization/locale_provider.dart';

enum LanguageSwitcherStyle { compact, settings }

class LanguageSwitcher extends ConsumerWidget {
  const LanguageSwitcher({
    super.key,
    this.style = LanguageSwitcherStyle.compact,
    this.size = 26,
    this.showCompactCode = false,
  });

  final LanguageSwitcherStyle style;
  final double size;
  final bool showCompactCode;

  static const Map<String, String> _languages = {
    'en': 'English',
    'ru': 'Русский',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localeAsync = ref.watch(localeProvider);
    final activeLanguageCode = localeAsync.value?.languageCode ?? 'en';

    switch (style) {
      case LanguageSwitcherStyle.compact:
        final compactCode = activeLanguageCode.toUpperCase();
        return PopupMenuButton<String>(
          tooltip: 'Язык',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.language, size: size),
              if (showCompactCode) ...[
                const SizedBox(width: 4),
                Text(
                  compactCode,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ],
          ),
          onSelected: (languageCode) =>
              _setLanguageCode(ref, languageCode: languageCode),
          itemBuilder: (context) => _languages.entries.map((entry) {
            final isSelected = activeLanguageCode == entry.key;
            return PopupMenuItem<String>(
              value: entry.key,
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    child: isSelected
                        ? const Icon(Icons.check, size: 16)
                        : const SizedBox.shrink(),
                  ),
                  const SizedBox(width: 8),
                  Text(entry.value),
                ],
              ),
            );
          }).toList(),
        );
      case LanguageSwitcherStyle.settings:
        return ListTile(
          leading: const Icon(Icons.language),
          title: const Text('Язык'),
          subtitle: Text(_languageName(activeLanguageCode)),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () => _showLanguageDialog(context, ref),
        );
    }
  }

  Future<void> _setLanguageCode(
    WidgetRef ref, {
    required String languageCode,
  }) async {
    await ref.read(localeProvider.notifier).setLocaleCode(languageCode);
  }

  String _languageName(String languageCode) {
    return _languages[languageCode] ?? languageCode;
  }

  Future<void> _showLanguageDialog(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выберите язык'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _languages.entries.map((entry) {
            return ListTile(
              title: Text(entry.value),
              onTap: () => Navigator.pop(context, entry.key),
            );
          }).toList(),
        ),
      ),
    );

    if (result == null) {
      return;
    }

    await _setLanguageCode(ref, languageCode: result);
  }
}
