import 'package:hoplixi/core/services/services.dart';

class LaunchContext {
  const LaunchContext({this.filePath, required this.startInTray});

  final String? filePath;
  final bool startInTray;
}

LaunchContext parseLaunchContext(List<String> args) {
  if (args.isEmpty) {
    return const LaunchContext(filePath: null, startInTray: false);
  }

  var startInTray = false;
  String? filePath;

  for (final rawArg in args) {
    final arg = rawArg.trim().replaceAll('"', '').replaceAll("'", '');
    if (arg.isEmpty) {
      continue;
    }

    if (arg == LaunchAtStartupService.startInTrayArg ||
        arg.contains(LaunchAtStartupService.startInTrayArg)) {
      startInTray = true;
      continue;
    }

    filePath ??= arg;
  }

  return LaunchContext(filePath: filePath, startInTray: startInTray);
}

Map<String, dynamic> buildFocusMetadata(String? filePath) {
  final metadata = <String, dynamic>{};
  final normalized = filePath?.trim();
  if (normalized != null && normalized.isNotEmpty) {
    metadata['filePath'] = normalized;
  }
  return metadata;
}

String? extractIncomingFilePath(Map<String, dynamic> metadata) {
  final rawFilePath = metadata['filePath'];
  if (rawFilePath is! String) {
    return null;
  }

  final normalized = rawFilePath.trim();
  if (normalized.isEmpty) {
    return null;
  }

  return normalized;
}
