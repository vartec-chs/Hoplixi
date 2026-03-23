import 'package:url_launcher/url_launcher.dart';

Future<void> launchDesktopBrowser(Uri uri) async {
  final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!launched) {
    throw UnsupportedError('Could not launch desktop browser for $uri');
  }
}
