import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_quill/quill_delta.dart';
import 'package:markdown_quill/markdown_quill.dart';

class NoteMarkdownExport {
  const NoteMarkdownExport({required this.fileName, required this.content});

  final String fileName;
  final String content;

  Uint8List get bytes => Uint8List.fromList(utf8.encode(content));
}

class NoteMarkdownExportService {
  const NoteMarkdownExportService();

  NoteMarkdownExport build({
    required String title,
    required String deltaJson,
    required String fallbackContent,
    String? description,
    String? categoryName,
    List<String> tagNames = const [],
    DateTime? createdAt,
    DateTime? modifiedAt,
  }) {
    final normalizedTitle = title.trim().isEmpty
        ? 'Untitled note'
        : title.trim();
    final normalizedTags = _normalizeTags(tagNames);
    final markdownBody = _convertDeltaToMarkdown(
      deltaJson: deltaJson,
      fallbackContent: fallbackContent,
    );

    final buffer = StringBuffer()
      ..writeln('---')
      ..writeln('title: ${_yamlScalar(normalizedTitle)}')
      ..writeln('type: note');

    final normalizedCategory = categoryName?.trim();
    if (normalizedCategory != null && normalizedCategory.isNotEmpty) {
      buffer.writeln('category: ${_yamlScalar(normalizedCategory)}');
    }

    if (normalizedTags.isNotEmpty) {
      buffer.writeln('tags:');
      for (final tag in normalizedTags) {
        buffer.writeln('  - ${_yamlScalar(tag)}');
      }
    }

    if (createdAt != null) {
      buffer.writeln('created: ${_yamlScalar(createdAt.toIso8601String())}');
    }
    if (modifiedAt != null) {
      buffer.writeln('updated: ${_yamlScalar(modifiedAt.toIso8601String())}');
    }

    buffer.writeln('---');
    buffer.writeln();
    buffer.writeln('# $normalizedTitle');

    final normalizedDescription = description?.trim();
    if (normalizedDescription != null && normalizedDescription.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln(normalizedDescription);
    }

    final normalizedBody = markdownBody.trim();
    if (normalizedBody.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln(normalizedBody);
    }

    return NoteMarkdownExport(
      fileName: '${_sanitizeFileName(normalizedTitle)}.md',
      content: buffer.toString(),
    );
  }

  String _convertDeltaToMarkdown({
    required String deltaJson,
    required String fallbackContent,
  }) {
    if (deltaJson.trim().isEmpty) {
      return fallbackContent;
    }

    try {
      final decoded = jsonDecode(deltaJson) as List<dynamic>;
      final delta = Delta.fromJson(decoded.cast<Map<String, dynamic>>());
      return DeltaToMarkdown(
        customContentHandler: DeltaToMarkdown.escapeSpecialCharactersRelaxed,
      ).convert(delta);
    } catch (_) {
      return fallbackContent;
    }
  }

  List<String> _normalizeTags(List<String> tags) {
    final result = <String>{};
    for (final tag in tags) {
      final normalized = tag.trim().replaceAll(RegExp(r'\s+'), '-');
      if (normalized.isNotEmpty) {
        result.add(normalized);
      }
    }
    return result.toList(growable: false);
  }

  String _yamlScalar(String value) {
    final escaped = value.replaceAll(r'\', r'\\').replaceAll('"', r'\"');
    return '"$escaped"';
  }

  String _sanitizeFileName(String value) {
    final sanitized = value
        .replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '_')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .replaceAll(RegExp(r'[. ]+$'), '');

    if (sanitized.isEmpty) {
      return 'Untitled note';
    }
    return sanitized.length <= 80
        ? sanitized
        : sanitized.substring(0, 80).trim();
  }
}
