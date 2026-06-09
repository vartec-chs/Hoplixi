import 'package:flutter/material.dart';
import 'package:hoplixi/core/theme/theme.dart';
import 'package:hoplixi/shared/ui/button.dart';
import 'package:hoplixi/shared/ui/text_field.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class PasswordDialog extends StatefulWidget {
  final String dbName;

  const PasswordDialog({super.key, required this.dbName});

  @override
  State<PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<PasswordDialog> {
  final _controller = TextEditingController();
  bool _obscureText = true;
  bool _savePassword = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fillColor = AppColors.getInputFieldBackgroundColor(context);
    return AlertDialog(
      insetPadding: const EdgeInsets.all(12),
      title: Text('Введите пароль для "${widget.dbName}"'),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _controller,
              obscureText: _obscureText,
              decoration: primaryInputDecoration(
                context,
                labelText: 'Пароль',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureText ? LucideIcons.eye : LucideIcons.eyeClosed,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureText = !_obscureText;
                    });
                  },
                ),
              ),
              onSubmitted: (value) =>
                  Navigator.of(context).pop((value, _savePassword)),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              tileColor: fillColor,
              title: const Text('Сохранить пароль'),
              value: _savePassword,
              onChanged: (value) {
                setState(() {
                  _savePassword = value;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        SmoothButton.text(
          onPressed: () => Navigator.of(context).pop(),
          label: 'Отмена',
          variant: SmoothButtonVariant.error,
        ),
        SmoothButton.primary(
          label: 'Открыть',
          onPressed: () =>
              Navigator.of(context).pop((_controller.text, _savePassword)),
        ),
      ],
    );
  }
}
