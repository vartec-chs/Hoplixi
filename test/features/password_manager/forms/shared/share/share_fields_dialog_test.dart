import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoplixi/features/password_manager/forms/shared/share/share_fields_dialog.dart';
import 'package:hoplixi/features/password_manager/forms/shared/share/share_text_formatter.dart';
import 'package:hoplixi/features/password_manager/forms/shared/share/shareable_field.dart';
import 'package:hoplixi/generated/l10n/translations.g.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  group('buildShareText', () {
    test('keeps selected fields in order and skips unselected fields', () {
      final entity = ShareableEntity(
        title: 'Example',
        entityTypeLabel: 'Password',
        fields: [
          const ShareableField(id: 'login', label: 'Login', value: 'alice'),
          const ShareableField(
            id: 'password',
            label: 'Password',
            value: 'secret',
            isSensitive: true,
          ),
          const ShareableField(
            id: 'url',
            label: 'URL',
            value: 'https://a.test',
          ),
        ],
      );

      final text = buildShareText(entity, {'url', 'login'});

      expect(text, 'Example\n\nLogin: alice\n\nURL: https://a.test');
    });

    test('formats multiline values without losing line breaks', () {
      final entity = ShareableEntity(
        title: 'Note',
        entityTypeLabel: 'Note',
        fields: [
          const ShareableField(
            id: 'content',
            label: 'Content',
            value: 'first\nsecond',
          ),
        ],
      );

      final text = buildShareText(entity, {'content'});

      expect(text, 'Note\n\nContent:\nfirst\nsecond');
    });
  });

  group('showShareFieldsDialog', () {
    testWidgets('shows fields and keeps sensitive fields unchecked', (
      tester,
    ) async {
      LocaleSettings.setLocaleRaw('en');

      await tester.pumpWidget(
        TranslationProvider(
          child: MaterialApp(
            home: Builder(
              builder: (context) => TextButton(
                onPressed: () => showShareFieldsDialog(
                  context: context,
                  entity: _entity(),
                  share: (_) async =>
                      const ShareResult('', ShareResultStatus.success),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Login'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);

      final loginTile = tester.widget<CheckboxListTile>(
        find.widgetWithText(CheckboxListTile, 'Login'),
      );
      final passwordTile = tester.widget<CheckboxListTile>(
        find.widgetWithText(CheckboxListTile, 'Password'),
      );

      expect(loginTile.value, isTrue);
      expect(passwordTile.value, isFalse);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).enabled,
        isTrue,
      );
    });

    testWidgets('disables share when nothing is selected', (tester) async {
      LocaleSettings.setLocaleRaw('en');

      await tester.pumpWidget(
        TranslationProvider(
          child: MaterialApp(
            home: Builder(
              builder: (context) => TextButton(
                onPressed: () => showShareFieldsDialog(
                  context: context,
                  entity: const ShareableEntity(
                    title: 'Secret',
                    entityTypeLabel: 'Password',
                    fields: [
                      ShareableField(
                        id: 'password',
                        label: 'Password',
                        value: 'secret',
                        isSensitive: true,
                      ),
                    ],
                  ),
                  share: (_) async =>
                      const ShareResult('', ShareResultStatus.success),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).enabled,
        isFalse,
      );

      await tester.tap(find.text('Select all'));
      await tester.pump();

      final passwordTile = tester.widget<CheckboxListTile>(
        find.widgetWithText(CheckboxListTile, 'Password'),
      );
      expect(passwordTile.value, isTrue);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).enabled,
        isTrue,
      );
    });
  });
}

ShareableEntity _entity() {
  return const ShareableEntity(
    title: 'Example',
    entityTypeLabel: 'Password',
    fields: [
      ShareableField(id: 'login', label: 'Login', value: 'alice'),
      ShareableField(
        id: 'password',
        label: 'Password',
        value: 'secret',
        isSensitive: true,
      ),
    ],
  );
}
