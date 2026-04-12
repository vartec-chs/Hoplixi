import 'dart:io';

import 'package:hoplixi/core/app_paths.dart';

Future<File> resolvePasswordGeneratorProfilesFile() async {
  final filePath = await AppPaths.passwordGeneratorProfilesFilePath;
  return File(filePath);
}
