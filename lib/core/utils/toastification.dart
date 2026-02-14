import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hoplixi/core/constants/main_constants.dart';
import 'package:hoplixi/core/logger/index.dart';
import 'package:hoplixi/core/theme/index.dart';
import 'package:hoplixi/global_key.dart';
import 'package:toastification/toastification.dart';

typedef _ToastPresenter = void Function(BuildContext context);

class _BufferedToast {
  const _BufferedToast({required this.type, required this.presenter});

  final String type;
  final _ToastPresenter presenter;
}

class Toaster {
  static const String _logTag = 'Toaster';
  static const toastificationStyle = ToastificationStyle.fillColored;
  static const int _maxBufferedToasts = 100;

  static final List<_BufferedToast> _bufferedToasts = <_BufferedToast>[];
  static bool _flushScheduled = false;

  static const EdgeInsets toastPadding = EdgeInsets.symmetric(
    horizontal: 8,
    vertical: 8,
  );
  static const EdgeInsets toastMargin = EdgeInsets.symmetric(
    horizontal: 8,
    vertical: 8,
  );

  static void success({
    BuildContext? context,
    required String title,
    String? description,
    Duration? autoCloseDuration,
    ToastificationCallbacks? callbacks,
  }) {
    final primaryColor = Colors.green.shade500;

    _showOrBuffer(
      type: 'success',
      context: context,
      presenter: (contextToUse) => toastification.show(
        context: contextToUse,
        type: ToastificationType.success,
        style: toastificationStyle,
        autoCloseDuration: autoCloseDuration ?? const Duration(seconds: 5),
        title: Text(title),
        description: description != null ? Text(description) : null,
        direction: TextDirection.ltr,
        animationDuration: const Duration(milliseconds: 300),
        icon: const Icon(Icons.check),
        showIcon: true,
        primaryColor: primaryColor,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        padding: toastPadding,
        margin: toastMargin,
        borderRadius: defaultBorderRadiusValue,
        borderSide: BorderSide(color: primaryColor, width: 1),
        showProgressBar: true,
        closeOnClick: false,
        pauseOnHover: true,
        dragToClose: true,
        callbacks: callbacks ?? const ToastificationCallbacks(),
      ),
    );
  }

  static void error({
    BuildContext? context,
    required String title,
    String? description,
    Duration? autoCloseDuration,
    ToastificationCallbacks? callbacks,
  }) {
    final primaryColor = Colors.red.shade500;

    _showOrBuffer(
      type: 'error',
      context: context,
      presenter: (contextToUse) => toastification.show(
        context: contextToUse,
        type: ToastificationType.error,
        style: toastificationStyle,
        autoCloseDuration: autoCloseDuration ?? const Duration(seconds: 5),
        title: Text(title),
        description: description != null
            ? Text('(Нажмите для копирования) $description')
            : null,
        direction: TextDirection.ltr,
        animationDuration: const Duration(milliseconds: 300),
        icon: const Icon(Icons.error),
        showIcon: true,
        primaryColor: primaryColor,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        padding: toastPadding,
        margin: toastMargin,
        borderRadius: BorderRadius.circular(defaultBorderRadius),
        borderSide: BorderSide(color: primaryColor, width: 1),
        showProgressBar: true,
        closeOnClick: false,
        pauseOnHover: true,
        dragToClose: true,
        callbacks:
            callbacks ??
            ToastificationCallbacks(
              onTap: (value) =>
                  Clipboard.setData(
                    ClipboardData(text: description ?? ''),
                  ).then(
                    (value) {
                      Toaster.info(
                        context: contextToUse,
                        title: 'Скопировано',
                        description: 'Ошибка скопирована в буфер обмена',
                        autoCloseDuration: const Duration(seconds: 3),
                      );
                    },
                    onError: (error) {
                      Toaster.error(
                        context: contextToUse,
                        title: 'Ошибка',
                        description: 'Ошибка копирования: $error',
                        autoCloseDuration: const Duration(seconds: 3),
                      );
                    },
                  ),
            ),
      ),
    );
  }

  static void infoDebug({
    BuildContext? context,
    required String title,
    String? description,
    Duration? autoCloseDuration,
    ToastificationCallbacks? callbacks,
  }) {
    if (!MainConstants.isProduction) {
      final primaryColor = Colors.grey.shade800;

      _showOrBuffer(
        type: 'infoDebug',
        context: context,
        presenter: (contextToUse) => toastification.show(
          context: contextToUse,
          type: ToastificationType.info,
          style: toastificationStyle,
          autoCloseDuration: autoCloseDuration ?? const Duration(seconds: 5),
          title: Text(title),
          description: description != null ? Text(description) : null,
          direction: TextDirection.ltr,
          animationDuration: const Duration(milliseconds: 300),
          icon: const Icon(Icons.bug_report),
          showIcon: true,
          primaryColor: primaryColor,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          borderRadius: defaultBorderRadiusValue,
          borderSide: BorderSide(color: primaryColor, width: 1),
          showProgressBar: true,
          closeOnClick: false,
          pauseOnHover: true,
          dragToClose: true,
          callbacks: callbacks ?? const ToastificationCallbacks(),
        ),
      );
    }
  }

  static void warning({
    BuildContext? context,
    required String title,
    String? description,
    Duration? autoCloseDuration,
    ToastificationCallbacks? callbacks,
  }) {
    final primaryColor = Colors.orange.shade500;

    _showOrBuffer(
      type: 'warning',
      context: context,
      presenter: (contextToUse) => toastification.show(
        context: contextToUse,
        type: ToastificationType.warning,
        style: toastificationStyle,
        autoCloseDuration: autoCloseDuration ?? const Duration(seconds: 5),
        title: Text(title),
        description: description != null ? Text(description) : null,
        direction: TextDirection.ltr,
        animationDuration: const Duration(milliseconds: 300),
        icon: const Icon(Icons.bug_report),
        showIcon: true,
        primaryColor: primaryColor,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        padding: toastPadding,
        margin: toastMargin,
        borderRadius: defaultBorderRadiusValue,
        borderSide: BorderSide(color: primaryColor, width: 1),
        showProgressBar: true,
        closeOnClick: false,
        pauseOnHover: true,
        dragToClose: true,
        callbacks: callbacks ?? const ToastificationCallbacks(),
      ),
    );
  }

  static void info({
    BuildContext? context,
    required String title,
    String? description,
    Duration? autoCloseDuration,
    ToastificationCallbacks? callbacks,
  }) {
    final primaryColor = Colors.blue.shade500;

    _showOrBuffer(
      type: 'info',
      context: context,
      presenter: (contextToUse) => toastification.show(
        context: contextToUse,
        type: ToastificationType.info,
        style: toastificationStyle,
        autoCloseDuration: autoCloseDuration ?? const Duration(seconds: 5),
        title: Text(title),
        description: description != null ? Text(description) : null,
        direction: TextDirection.ltr,
        animationDuration: const Duration(milliseconds: 300),
        icon: const Icon(Icons.warning),
        showIcon: true,
        primaryColor: primaryColor,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        padding: toastPadding,
        margin: toastMargin,
        borderRadius: defaultBorderRadiusValue,
        borderSide: BorderSide(color: primaryColor, width: 1),
        showProgressBar: true,
        closeOnClick: false,
        pauseOnHover: true,
        dragToClose: true,
        callbacks: callbacks ?? const ToastificationCallbacks(),
      ),
    );
  }

  static void custom({
    BuildContext? context,
    required String title,
    String? description,
    Duration? autoCloseDuration,
    ToastificationType? type,
    ToastificationStyle? style,
    Icon? icon,
    Color? primaryColor,
    Color? backgroundColor,
    Color? foregroundColor,
    Alignment? alignment,
    bool? showIcon,
    bool? showProgressBar,
    ToastificationCallbacks? callbacks,
  }) {
    _showOrBuffer(
      type: 'custom',
      context: context,
      presenter: (contextToUse) {
        final theme = Theme.of(contextToUse);

        toastification.show(
          context: contextToUse,
          type: type ?? ToastificationType.info,
          style: style ?? toastificationStyle,
          autoCloseDuration: autoCloseDuration ?? const Duration(seconds: 5),
          title: Text(title),
          description: description != null ? Text(description) : null,
          alignment: alignment,
          direction: TextDirection.ltr,
          animationDuration: const Duration(milliseconds: 300),
          icon: icon ?? const Icon(Icons.notifications),
          showIcon: showIcon ?? true,
          primaryColor: primaryColor ?? theme.colorScheme.primary,
          backgroundColor: backgroundColor ?? theme.colorScheme.surface,
          foregroundColor: foregroundColor ?? theme.colorScheme.onSurface,
          padding: toastPadding,
          margin: toastMargin,
          borderRadius: defaultBorderRadiusValue,
          showProgressBar: showProgressBar ?? true,
          closeOnClick: false,
          pauseOnHover: true,
          dragToClose: true,
          callbacks: callbacks ?? const ToastificationCallbacks(),
        );
      },
    );
  }

  static void _showOrBuffer({
    required String type,
    required _ToastPresenter presenter,
    BuildContext? context,
  }) {
    final contextToUse = context ?? navigatorKey.currentContext;
    if (contextToUse == null) {
      _bufferToast(type: type, presenter: presenter);
      return;
    }

    _flushBufferedToasts(contextToUse);
    presenter(contextToUse);
  }

  static void _bufferToast({
    required String type,
    required _ToastPresenter presenter,
  }) {
    if (_bufferedToasts.length >= _maxBufferedToasts) {
      _bufferedToasts.removeAt(0);
    }
    _bufferedToasts.add(_BufferedToast(type: type, presenter: presenter));
    logWarning(
      'Toast buffered until context is available: $type (${_bufferedToasts.length})',
      tag: _logTag,
    );
    _scheduleFlush();
  }

  static void _scheduleFlush() {
    if (_flushScheduled || _bufferedToasts.isEmpty) {
      return;
    }

    _flushScheduled = true;
    try {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _flushScheduled = false;
        _tryFlushBufferedToasts();
      });
      return;
    } catch (_) {
      // Binding may be unavailable very early in startup.
    }

    unawaited(
      Future<void>.delayed(const Duration(milliseconds: 100), () {
        _flushScheduled = false;
        _tryFlushBufferedToasts();
      }),
    );
  }

  static void _tryFlushBufferedToasts() {
    if (_bufferedToasts.isEmpty) {
      return;
    }

    final context = navigatorKey.currentContext;
    if (context == null) {
      _scheduleFlush();
      return;
    }

    _flushBufferedToasts(context);
  }

  static void _flushBufferedToasts(BuildContext context) {
    if (_bufferedToasts.isEmpty) {
      return;
    }

    final pending = List<_BufferedToast>.from(_bufferedToasts);
    _bufferedToasts.clear();

    for (final toast in pending) {
      try {
        toast.presenter(context);
      } catch (error) {
        logError(
          'Failed to show buffered toast (${toast.type}): $error',
          tag: _logTag,
        );
      }
    }
  }
}
