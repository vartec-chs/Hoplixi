import 'dart:async';

import 'package:flutter/material.dart';

class StoreOpeningOverlayHost extends StatefulWidget {
  const StoreOpeningOverlayHost({required this.visible, super.key});

  final bool visible;

  @override
  State<StoreOpeningOverlayHost> createState() =>
      _StoreOpeningOverlayHostState();
}

class _StoreOpeningOverlayHostState extends State<StoreOpeningOverlayHost> {
  static const _hideDelay = Duration(milliseconds: 400);
  static const _animationDuration = Duration(milliseconds: 220);

  Timer? _hideDelayTimer;
  Timer? _disposeTimer;
  bool _isMounted = false;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();

    if (widget.visible) {
      _showOverlay();
    }
  }

  @override
  void didUpdateWidget(covariant StoreOpeningOverlayHost oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.visible == oldWidget.visible) return;

    if (widget.visible) {
      _showOverlay();
    } else {
      _hideOverlayWithDelay();
    }
  }

  void _showOverlay() {
    _hideDelayTimer?.cancel();
    _disposeTimer?.cancel();

    if (!_isMounted) {
      setState(() {
        _isMounted = true;
        _isVisible = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !widget.visible) return;
        setState(() {
          _isVisible = true;
        });
      });
      return;
    }

    if (!_isVisible) {
      setState(() {
        _isVisible = true;
      });
    }
  }

  void _hideOverlayWithDelay() {
    _hideDelayTimer?.cancel();
    _disposeTimer?.cancel();

    _hideDelayTimer = Timer(_hideDelay, () {
      if (!mounted || widget.visible || !_isMounted) return;

      setState(() {
        _isVisible = false;
      });

      _disposeTimer = Timer(_animationDuration, () {
        if (!mounted || widget.visible) return;

        setState(() {
          _isMounted = false;
        });
      });
    });
  }

  @override
  void dispose() {
    _hideDelayTimer?.cancel();
    _disposeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isMounted) {
      return const SizedBox.shrink();
    }

    return AbsorbPointer(
      absorbing: true,
      child: AnimatedOpacity(
        opacity: _isVisible ? 1 : 0,
        duration: _animationDuration,
        curve: Curves.easeOutCubic,
        child: _StoreOpeningOverlay(visible: _isVisible),
      ),
    );
  }
}

class _StoreOpeningOverlay extends StatelessWidget {
  const _StoreOpeningOverlay({required this.visible});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ColoredBox(
      color: theme.colorScheme.scrim.withValues(alpha: 0.72),
      child: Center(
        child: AnimatedScale(
          scale: visible ? 1 : 0.96,
          duration: _StoreOpeningOverlayHostState._animationDuration,
          curve: Curves.easeOutCubic,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator.adaptive(),
              const SizedBox(height: 16),
              Text(
                'Открытие хранилища...',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
