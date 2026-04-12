import 'package:hoplixi/setup/app_bootstrap.dart';
import 'package:universal_platform/universal_platform.dart';

Future<void> main(List<String> args) async {
  if (UniversalPlatform.isWeb) {
    throw UnsupportedError(
      'Web platform is not supported in this version. '
      'Please use a different platform.',
    );
  }

  await runGuardedApp(args);
}
