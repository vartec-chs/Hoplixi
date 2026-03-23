import 'dart:io';

Future<void> launchDesktopBrowser(Uri uri) async {
  if (Platform.isWindows) {
    await Process.start('cmd', <String>['/c', 'start', '', uri.toString()]);
    return;
  }

  if (Platform.isMacOS) {
    await Process.start('open', <String>[uri.toString()]);
    return;
  }

  if (Platform.isLinux) {
    await Process.start('xdg-open', <String>[uri.toString()]);
    return;
  }

  throw UnsupportedError('Desktop browser launch is not supported here.');
}
