import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:hoplixi/core/logger/index.dart';
import 'package:hoplixi/core/utils/toastification.dart';

void setupErrorHandling() {
  // Handle Flutter errors
  FlutterError.onError = (FlutterErrorDetails details) {
    // Ignore specific debugNeedsLayout assertion error WoltModalSheet Flutter issue
    final exceptionStr = details.exceptionAsString();
    if (exceptionStr.contains("'!debugNeedsLayout': is not true.")) {
      return;
    }

    // Записываем краш-репорт для Flutter ошибок
    logCrash(
      message: 'Flutter error',
      error: details.exception,
      stackTrace: details.stack ?? StackTrace.current,
      errorType: 'FlutterError',
    );

    Toaster.error(
      title: 'Ошибка Flutter',
      description: details.exceptionAsString(),
    );
  };

  // Handle platform errors
  PlatformDispatcher.instance.onError = (error, stackTrace) {
    // Записываем краш-репорт для платформенных ошибок
    logCrash(
      message: 'Platform error',
      error: error,
      stackTrace: stackTrace,
      errorType: 'PlatformError',
    );

    Toaster.error(title: 'Ошибка платформы', description: error.toString());
    return true;
  };

  // Optional: Catch errors in the widget tree
  ErrorWidget.builder = (errorDetails) {
    logCrash(
      message: 'Widget error',
      error: errorDetails.exception,
      stackTrace: errorDetails.stack ?? StackTrace.current,
      errorType: 'WidgetError',
    );
    Toaster.error(
      title: 'Ошибка виджета',
      description: errorDetails.exceptionAsString(),
    );
    return ErrorWidget(errorDetails.exception);
  };
}
