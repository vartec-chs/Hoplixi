import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

/// Расширение [WindowController] для управления окном
/// через `window_manager`.
///
/// Добавляет методы [center], [close], [setSize], [setTitle]
/// и [setMinSize], которые вызываются удалённо через
/// inter-window method channel.
extension WindowControllerExt on WindowController {
  /// Инициализирует обработчик методов окна.
  ///
  /// Вызывается внутри суб-окна для обработки
  /// входящих команд от главного окна.
  Future<void> initWindowMethodHandler() async {
    await setWindowMethodHandler((call) async {
      switch (call.method) {
        case 'window_center':
          await windowManager.center();
        case 'window_close':
          await windowManager.close();
        case 'window_set_size':
          final args = call.arguments as Map;
          final w = (args['width'] as num).toDouble();
          final h = (args['height'] as num).toDouble();
          await windowManager.setSize(Size(w, h));
        case 'window_set_title':
          final title = call.arguments as String;
          await windowManager.setTitle(title);
        case 'window_set_min_size':
          final args = call.arguments as Map;
          final w = (args['width'] as num).toDouble();
          final h = (args['height'] as num).toDouble();
          await windowManager.setMinimumSize(Size(w, h));
        default:
          throw MissingPluginException('Метод не реализован: ${call.method}');
      }
    });
  }

  /// Центрирует окно на экране.
  Future<void> center() => invokeMethod('window_center');

  /// Закрывает окно.
  Future<void> close() => invokeMethod('window_close');

  /// Устанавливает размер окна.
  Future<void> setSize(Size size) => invokeMethod('window_set_size', {
    'width': size.width,
    'height': size.height,
  });

  /// Устанавливает заголовок окна.
  Future<void> setTitle(String title) =>
      invokeMethod('window_set_title', title);

  /// Устанавливает минимальный размер окна.
  Future<void> setMinSize(Size size) => invokeMethod('window_set_min_size', {
    'width': size.width,
    'height': size.height,
  });
}
