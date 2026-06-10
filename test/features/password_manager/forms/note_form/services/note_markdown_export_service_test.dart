import 'dart:convert';

import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoplixi/features/password_manager/forms/note_form/services/note_markdown_export_service.dart';

void main() {
  group('NoteMarkdownExportService', () {
    const service = NoteMarkdownExportService();

    test('builds Obsidian markdown with frontmatter', () {
      final delta = Delta()
        ..insert('Hello ')
        ..insert('world', {'bold': true})
        ..insert('\n');

      final export = service.build(
        title: 'Project: Plan',
        description: 'Short description',
        deltaJson: jsonEncode(delta.toJson()),
        fallbackContent: 'fallback',
        categoryName: 'Work',
        tagNames: ['urgent task', 'Work'],
        createdAt: DateTime.utc(2026, 6, 10, 12),
        modifiedAt: DateTime.utc(2026, 6, 10, 13),
      );

      expect(export.fileName, 'Project_ Plan.md');
      expect(export.content, contains('title: "Project: Plan"'));
      expect(export.content, contains('category: "Work"'));
      expect(export.content, contains('  - "urgent-task"'));
      expect(export.content, contains('created: "2026-06-10T12:00:00.000Z"'));
      expect(export.content, contains('# Project: Plan'));
      expect(export.content, contains('Short description'));
      expect(export.content, contains('Hello **world**'));
    });

    test('falls back to plain content when delta json is invalid', () {
      final export = service.build(
        title: 'Broken note',
        deltaJson: '{',
        fallbackContent: 'Plain content',
      );

      expect(export.content, contains('Plain content'));
    });
  });
}
