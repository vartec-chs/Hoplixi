import 'dart:developer' as developer;

import 'package:desktop_multi_window/desktop_multi_window.dart';

import 'sub_window_type.dart';
import 'window_channel_service.dart';
import 'window_controller_ext.dart';

/// Сервис для работы с мульти-окнами через
/// `desktop_multi_window`.
///
/// Предоставляет удобный API для создания, поиска
/// и закрытия дополнительных окон приложения.
class MultiWindowService {
  static const String _tag = 'MultiWindowService';

  MultiWindowService._();

  static final MultiWindowService instance = MultiWindowService._();

  /// Открывает новое суб-окно заданного типа.
  ///
  /// Если окно такого типа уже существует (в режиме
  /// единственного экземпляра), фокусирует его вместо
  /// создания нового.
  ///
  /// [type] — тип суб-окна из [SubWindowType].
  /// [payload] — дополнительные данные для окна.
  /// [singleInstance] — если `true`, не создаёт дублирующее
  /// окно того же типа.
  Future<WindowController?> openWindow({
    required SubWindowType type,
    Map<String, dynamic> payload = const {},
    bool singleInstance = true,
  }) async {
    try {
      // Проверка на существующее окно в single-instance режиме
      if (singleInstance) {
        final existing = await findWindowByType(type);
        if (existing != null) {
          developer.log(
            'Окно типа ${type.name} уже открыто, '
            'фокусируем',
            name: _tag,
          );
          await existing.show();
          return existing;
        }
      }

      final args = SubWindowArguments(type: type, payload: payload);

      final controller = await WindowController.create(
        WindowConfiguration(hiddenAtLaunch: true, arguments: args.encode()),
      );

      developer.log(
        'Открыто окно: ${type.name} '
        '(id=${controller.windowId})',
        name: _tag,
      );

      return controller;
    } catch (e, s) {
      developer.log(
        'Ошибка создания окна ${type.name}',
        name: _tag,
        error: e,
        stackTrace: s,
        level: 1000,
      );
      return null;
    }
  }

  /// Открывает суб-окно и ожидает результат от него.
  ///
  /// Регистрирует хендлер на [channel], открывает окно,
  /// ждёт пока суб-окно вызовет `submitResult`
  /// или `cancel` / закроется. Возвращает результат
  /// типа [T] или `null` при отмене.
  ///
  /// ### Пример
  ///
  /// ```dart
  /// final password = await MultiWindowService.instance
  ///     .openAndWaitResult<String>(
  ///   type: SubWindowType.passwordGenerator,
  ///   channel: WindowChannels.passwordGenerator,
  /// );
  /// ```
  Future<T?> openAndWaitResult<T>({
    required SubWindowType type,
    required WindowMethodChannel channel,
    Map<String, dynamic> payload = const {},
    Duration? timeout,
  }) async {
    final channelService = WindowChannelService.instance;

    // Регистрируем хендлер для приёма результата
    await channelService.registerMainHandler(channel: channel);

    // Создаём ожидающий запрос
    final resultFuture = channelService.waitForResult<T>(
      channel: channel,
      timeout: timeout,
    );

    // Открываем окно
    final controller = await openWindow(type: type, payload: payload);

    if (controller == null) {
      await channelService.unregister(channel: channel);
      return null;
    }

    // Ожидаем результат
    final result = await resultFuture;

    developer.log('Результат от ${type.name}: $result', name: _tag);

    return result;
  }

  /// Ищет уже существующее окно заданного типа.
  ///
  /// Возвращает [WindowController] первого найденного окна
  /// или `null`, если подходящего нет.
  Future<WindowController?> findWindowByType(SubWindowType type) async {
    try {
      final controllers = await WindowController.getAll();
      for (final controller in controllers) {
        final parsed = SubWindowArguments.decode(controller.arguments);
        if (parsed?.type == type) {
          return controller;
        }
      }
    } catch (e) {
      developer.log('Ошибка поиска окна ${type.name}', name: _tag, error: e);
    }
    return null;
  }

  /// Закрывает все суб-окна заданного типа.
  Future<void> closeWindowsByType(SubWindowType type) async {
    try {
      final controllers = await WindowController.getAll();
      for (final controller in controllers) {
        final parsed = SubWindowArguments.decode(controller.arguments);
        if (parsed?.type == type) {
          await controller.close();
        }
      }
    } catch (e) {
      developer.log('Ошибка закрытия окон ${type.name}', name: _tag, error: e);
    }
  }

  /// Закрывает все суб-окна.
  Future<void> closeAll() async {
    try {
      final controllers = await WindowController.getAll();
      for (final controller in controllers) {
        // Не закрываем главное окно (id == '0')
        if (controller.windowId != '0') {
          await controller.close();
        }
      }
    } catch (e) {
      developer.log('Ошибка закрытия всех окон', name: _tag, error: e);
    }
  }
}
