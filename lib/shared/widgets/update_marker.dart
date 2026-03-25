import 'dart:async';

import 'package:flutter/material.dart';

/// Виджет-маркер для сигнализации об обновлениях данных
///
/// Показывает визуальный индикатор (красную точку) на короткое время
/// при получении события из потока обновлений
class UpdateMarker extends StatefulWidget {
  /// Поток обновлений для отслеживания
  final Stream<void> updateStream;

  /// Размер маркера в пикселях
  final double size;

  /// Цвет маркера при сигнализации
  final Color signalColor;

  /// Длительность сигнализации в миллисекундах
  final int signalDurationMs;

  const UpdateMarker({
    super.key,
    required this.updateStream,
    this.size = 8.0,
    this.signalColor = Colors.red,
    this.signalDurationMs = 2000,
  });

  @override
  State<UpdateMarker> createState() => _UpdateMarkerState();
}

class _UpdateMarkerState extends State<UpdateMarker> {
  bool _isSignaling = false;
  Timer? _signalTimer;
  StreamSubscription<void>? _subscription;

  @override
  void initState() {
    super.initState();
    _listenToUpdates();
  }

  @override
  void didUpdateWidget(UpdateMarker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.updateStream != widget.updateStream) {
      _listenToUpdates();
    }
  }

  void _listenToUpdates() {
    _subscription?.cancel();
    _subscription = widget.updateStream.listen((_) {
      if (mounted) {
        setState(() {
          _isSignaling = true;
        });
        _signalTimer?.cancel();
        _signalTimer = Timer(
          Duration(milliseconds: widget.signalDurationMs),
          () {
            if (mounted) {
              setState(() {
                _isSignaling = false;
              });
            }
          },
        );
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _signalTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _isSignaling ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: widget.signalColor,
          shape: BoxShape.circle,
          boxShadow: _isSignaling
              ? [
                  BoxShadow(
                    color: widget.signalColor.withOpacity(0.5),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
      ),
    );
  }
}

/// Пример использования с базой данных
///
/// Stream<void> watchTodosChanged(AppDatabase db) {
///   return db
///       .customSelect(
///         'SELECT 1',          // данные нам не нужны
///         readsFrom: {db.passwords}, // какие таблицы отслеживаем
///       )
///       .watch()
///       .map((_) => null);    // превращаем в Stream<void>
/// }
///
/// // В виджете:
/// UpdateMarker(
///   updateStream: watchTodosChanged(database),
/// )
