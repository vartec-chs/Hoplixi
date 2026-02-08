import 'package:flutter/services.dart';

class MainConstants {
  static const String appName = 'Hoplixi';
  static const bool isProduction = bool.fromEnvironment('dart.vm.product');
  static const String appFolderName = 'hoplixi';

  static const Size defaultWindowSize = Size(650, 720);
  static const Size minWindowSize = Size(400, 500);
  static const Size maxWindowSize = Size(1920, 1080);

  // dashboard size
  static const Size defaultDashboardSize = Size(1080, 750);
  static const bool isCenter = true;

  static const int databaseSchemaVersion = 1;
  static const String dbExtension = '.hplxdb';
  static const String encryptedFileExtension = '.hplxenc';

  // Минимальное количество использований для считания записи часто используемой
  static const int frequentlyUsedThreshold = 5;

  // Минимальное количество использований для считания записи популярной
  static const int popularItemThreshold = 100;

  static const double kMobileBreakpoint = 700.0;
  static const double kDesktopBreakpoint = 1000.0;
}
