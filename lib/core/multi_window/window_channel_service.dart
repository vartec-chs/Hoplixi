import 'dart:async';
import 'dart:developer' as developer;

import 'package:desktop_multi_window/desktop_multi_window.dart';

/// Имена каналов для общения между окнами.
///
/// Каждый канал — это пара `WindowMethodChannel` в режиме
/// [ChannelMode.bidirectional], что позволяет главному окну
/// и суб-окну вызывать методы друг друга.
abstract final class WindowChannels {
  /// Канал генератора паролей.
  ///
  /// Методы:
  /// - `submit_password` — суб-окно → главное окно:
  ///   отправляет сгенерированный пароль.
  /// - `cancel` — суб-окно → главное окно:
  ///   пользователь закрыл окно без выбора.
  static const passwordGenerator = WindowMethodChannel(
    'hoplixi/password_generator',
  );

  /// Канал авторизации.
  ///
  /// Методы:
  /// - `submit_credentials` — суб-окно → главное окно:
  ///   отправляет данные для входа.
  /// - `cancel` — суб-окно → главное окно:
  ///   пользователь отменил авторизацию.
  static const auth = WindowMethodChannel('hoplixi/auth');
}

/// Сервис для межоконного общения.
///
/// Объединяет `WindowMethodChannel` (для передачи данных)
/// с `Completer` (для паттерна «запрос–ответ»).
///
/// ### Пример: вызов генератора и получение пароля
///
/// ```dart
/// // В главном окне:
/// final password = await WindowChannelService.instance
///     .requestFromWindow<String>(
///   channel: WindowChannels.passwordGenerator,
///   windowType: SubWindowType.passwordGenerator,
/// );
///
/// if (password != null) {
///   // Используем сгенерированный пароль
/// }
/// ```
class WindowChannelService {
  static const String _tag = 'WindowChannelService';

  WindowChannelService._();

  static final WindowChannelService instance = WindowChannelService._();

  /// Текущие активные запросы, ожидающие ответа
  /// от суб-окон.
  ///
  /// Ключ — имя канала, значение — `Completer`
  /// для завершения `Future` с результатом.
  final Map<String, Completer<dynamic>> _pendingRequests = {};

  /// Регистрирует обработчик входящих сообщений
  /// на канале [channel] в **главном** окне.
  ///
  /// Вызывается один раз при старте приложения.
  /// Обработчик автоматически завершает ожидающие
  /// `Completer` при получении `submit_*` / `cancel`.
  Future<void> registerMainHandler({
    required WindowMethodChannel channel,
  }) async {
    try {
      await channel.setMethodCallHandler((call) async {
        developer.log(
          'Получен вызов: ${call.method} '
          'на канале ${channel.name}',
          name: _tag,
        );

        final completer = _pendingRequests[channel.name];

        switch (call.method) {
          case 'submit_result':
            if (completer != null && !completer.isCompleted) {
              completer.complete(call.arguments);
            }
            return 'ok';

          case 'cancel':
            if (completer != null && !completer.isCompleted) {
              completer.complete(null);
            }
            return 'ok';

          default:
            developer.log(
              'Неизвестный метод: ${call.method}',
              name: _tag,
              level: 900,
            );
            return null;
        }
      });

      developer.log('Зарегистрирован хендлер: ${channel.name}', name: _tag);
    } on WindowChannelException catch (e) {
      developer.log(
        'Ошибка регистрации канала ${channel.name}',
        name: _tag,
        error: e,
        level: 1000,
      );
    }
  }

  /// Регистрирует обработчик входящих сообщений
  /// на канале [channel] в **суб-окне**.
  ///
  /// Суб-окно регистрируется как партнёр
  /// bidirectional-канала. [handler] вызывается
  /// для каждого входящего запроса от главного окна.
  Future<void> registerSubWindowHandler({
    required WindowMethodChannel channel,
    required Future<dynamic> Function(String method, dynamic args) handler,
  }) async {
    try {
      await channel.setMethodCallHandler((call) async {
        developer.log(
          'Суб-окно: получен вызов ${call.method} '
          'на канале ${channel.name}',
          name: _tag,
        );
        return handler(call.method, call.arguments);
      });

      developer.log(
        'Суб-окно: зарегистрирован хендлер '
        '${channel.name}',
        name: _tag,
      );
    } on WindowChannelException catch (e) {
      developer.log(
        'Суб-окно: ошибка регистрации '
        '${channel.name}',
        name: _tag,
        error: e,
        level: 1000,
      );
    }
  }

  /// Создаёт ожидающий запрос для канала.
  ///
  /// Возвращает `Future<T?>`, который завершается,
  /// когда суб-окно вызовет `submitResult` или `cancel`
  /// на том же канале, либо по таймауту.
  ///
  /// [timeout] — максимальное время ожидания ответа.
  /// По умолчанию `null` (без таймаута, ожидание
  /// до закрытия окна или вызова `cancel`/`submit`).
  Future<T?> waitForResult<T>({
    required WindowMethodChannel channel,
    Duration? timeout,
  }) {
    // Отменяем предыдущий ожидающий запрос
    // на этом канале, если был
    _cancelPending(channel.name);

    final completer = Completer<dynamic>();
    _pendingRequests[channel.name] = completer;

    var future = completer.future;
    if (timeout != null) {
      future = future.timeout(
        timeout,
        onTimeout: () {
          _cancelPending(channel.name);
          return null;
        },
      );
    }

    return future.then((value) {
      _pendingRequests.remove(channel.name);
      return value as T?;
    });
  }

  /// Отправляет результат из суб-окна
  /// в главное окно.
  ///
  /// Вызывается в суб-окне, когда пользователь
  /// принял решение (например, нажал «Использовать»
  /// в генераторе паролей).
  Future<void> submitResult({
    required WindowMethodChannel channel,
    dynamic result,
  }) async {
    try {
      await channel.invokeMethod('submit_result', result);
      developer.log(
        'Отправлен результат на канал '
        '${channel.name}',
        name: _tag,
      );
    } on WindowChannelException catch (e) {
      developer.log(
        'Ошибка отправки результата: '
        '${channel.name}',
        name: _tag,
        error: e,
        level: 1000,
      );
    }
  }

  /// Уведомляет главное окно об отмене из суб-окна.
  Future<void> cancelFromSubWindow({
    required WindowMethodChannel channel,
  }) async {
    try {
      await channel.invokeMethod('cancel');
      developer.log(
        'Отправлена отмена на канал '
        '${channel.name}',
        name: _tag,
      );
    } on WindowChannelException catch (e) {
      // Игнорируем ошибку при отмене — главное окно
      // могло уже закрыть канал
      developer.log(
        'Ошибка отправки отмены: ${channel.name}',
        name: _tag,
        error: e,
      );
    }
  }

  /// Отменяет ожидающий запрос локально
  /// (без отправки в суб-окно).
  void _cancelPending(String channelName) {
    final existing = _pendingRequests.remove(channelName);
    if (existing != null && !existing.isCompleted) {
      existing.complete(null);
    }
  }

  /// Снимает регистрацию канала и отменяет
  /// ожидающий запрос.
  Future<void> unregister({required WindowMethodChannel channel}) async {
    _cancelPending(channel.name);
    try {
      await channel.setMethodCallHandler(null);
    } catch (_) {
      // Ошибка при снятии не критична
    }
  }

  /// Очищает все ожидающие запросы.
  void disposeAll() {
    for (final entry in _pendingRequests.entries) {
      if (!entry.value.isCompleted) {
        entry.value.complete(null);
      }
    }
    _pendingRequests.clear();
  }
}
