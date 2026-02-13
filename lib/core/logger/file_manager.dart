import 'dart:io';
import 'dart:convert';
import 'package:hoplixi/core/app_paths.dart';
import 'package:hoplixi/core/logger/models.dart';
import 'package:intl/intl.dart';

import 'package:path/path.dart' as path;

class FileManager {
  final LoggerConfig config;
  late Directory _logDirectory;
  late Directory _crashDirectory;

  FileManager(this.config);

  Future<void> initialize() async {
    _logDirectory = Directory(
      await AppPaths.appLogsPath,
    ); // Use the updated method to get logs path
    _crashDirectory = Directory(
      await AppPaths.appCrashReportsPath,
    ); // Use the updated method to get crash reports path

    if (config.autoCleanup) {
      await _cleanupOldFiles();
    }
  }

  Future<File> getCurrentLogFile() async {
    final now = DateTime.now();
    final dateStr = DateFormat('yyyy-MM-dd').format(now);
    final fileName = 'app_log_$dateStr.jsonl';
    return File(path.join(_logDirectory.path, fileName));
  }

  Future<File> getCrashReportFile() async {
    final now = DateTime.now();
    final dateTimeStr = DateFormat('yyyy-MM-dd_HH-mm-ss').format(now);
    final fileName = 'crash_report_$dateTimeStr.json';
    return File(path.join(_crashDirectory.path, fileName));
  }

  Future<void> writeLogEntry(LogEntry entry) async {
    final file = await getCurrentLogFile();
    final jsonStr = jsonEncode(entry.toJson());
    await file.writeAsString('$jsonStr\n', mode: FileMode.append, flush: true);
  }

  Future<void> writeSessionStart(Session session) async {
    final file = await getCurrentLogFile();
    final sessionData = {
      'type': 'session_start',
      'processId': pid,
      'timestamp': DateTime.now().toIso8601String(),
      'session': session.toJson(),
    };
    final jsonStr = jsonEncode(sessionData);
    await file.writeAsString('$jsonStr\n', mode: FileMode.append, flush: true);
  }

  Future<void> writeSessionEnd(Session session) async {
    final file = await getCurrentLogFile();
    final sessionData = {
      'type': 'session_end',
      'processId': pid,
      'timestamp': DateTime.now().toIso8601String(),
      'session': session.toJson(),
    };
    final jsonStr = jsonEncode(sessionData);
    await file.writeAsString('$jsonStr\n', mode: FileMode.append, flush: true);
  }

  Future<void> writeCrashReport(
    dynamic error,
    StackTrace stackTrace,
    Session session,
  ) async {
    final file = await getCrashReportFile();
    final crashData = {
      'timestamp': DateTime.now().toIso8601String(),
      'error': error.toString(),
      'stackTrace': stackTrace.toString(),
      'session': session.toJson(),
    };
    await file.writeAsString(jsonEncode(crashData), mode: FileMode.write);
  }

  Future<void> _cleanupOldFiles() async {
    await _cleanupDirectory(_logDirectory);
    await _cleanupDirectory(_crashDirectory);
  }

  Future<void> _cleanupDirectory(Directory directory) async {
    final files = directory.listSync().whereType<File>().cast<File>().toList();

    // Sort by modification time (newest first)
    files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

    // Remove excess files
    if (files.length > config.maxFileCount) {
      for (int i = config.maxFileCount; i < files.length; i++) {
        await files[i].delete();
      }
    }

    // Remove files that exceed size limit
    for (final file in files) {
      final stat = await file.stat();
      if (stat.size > config.maxFileSize) {
        await file.delete();
      }
    }
  }
}
