import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/vault_db/core/models/dto/dto.dart';
import 'package:otp/otp.dart';

import '../shared/shared.dart';

class TotpListCard extends ConsumerStatefulWidget {
  final FilteredCardDto<OtpCardDto> data;
  final VoidCallback? onTap;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onTogglePin;
  final VoidCallback? onToggleArchive;
  final VoidCallback? onDelete;
  final VoidCallback? onRestore;
  final VoidCallback? onOpenHistory;
  final VoidCallback? onOpenView;

  const TotpListCard({
    super.key,
    required this.data,
    this.onTap,
    this.onToggleFavorite,
    this.onTogglePin,
    this.onToggleArchive,
    this.onDelete,
    this.onRestore,
    this.onOpenHistory,
    this.onOpenView,
  });

  @override
  ConsumerState<TotpListCard> createState() => _TotpListCardState();
}

class _TotpListCardState extends ConsumerState<TotpListCard> {
  bool _codeCopied = false;
  bool _isLoadingSecret = false;

  Uint8List? _secret;
  String? _currentCode;
  int _remainingSeconds = 0;
  Timer? _totpTimer;

  String get _itemId => widget.data.card.item.itemId;
  int get _period => widget.data.card.data.period ?? 30;

  @override
  void dispose() {
    _stopTimerAndClearSecret(updateState: false);
    super.dispose();
  }

  Future<void> _onExpandedChanged(bool expanded) async {
    if (expanded) {
      await _loadSecretAndStartTimer();
    } else {
      _stopTimerAndClearSecret();
    }
  }

  void _clearSecret() {
    if (_secret != null) {
      for (int i = 0; i < _secret!.length; i++) {
        _secret![i] = 0;
      }
      _secret = null;
    }
    _currentCode = null;
  }

  Future<void> _loadSecretAndStartTimer() async {
    if (_secret != null) {
      _generateCode();
      _startTimer();
      return;
    }

    setState(() => _isLoadingSecret = true);

    try {
      final value = null;

      if (value != null && mounted) {
        setState(() {
          _secret = value;
          _isLoadingSecret = false;
        });
        _generateCode();
        _startTimer();
      } else {
        if (mounted) {
          setState(() => _isLoadingSecret = false);
          Toaster.error(title: 'Не удалось получить секрет OTP');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingSecret = false);
        Toaster.error(title: 'Ошибка загрузки секрета', description: '$e');
      }
    }
  }

  void _stopTimerAndClearSecret({bool updateState = true}) {
    _totpTimer?.cancel();
    _totpTimer = null;
    _clearSecret();

    if (!updateState || !mounted) {
      _remainingSeconds = 0;
      return;
    }

    setState(() => _remainingSeconds = 0);
  }

  void _startTimer() {
    _totpTimer?.cancel();
    _updateRemainingSeconds();

    _totpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      _updateRemainingSeconds();
      if (_remainingSeconds == _period || _remainingSeconds == 0) {
        _generateCode();
      }
    });
  }

  void _updateRemainingSeconds() {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    setState(() {
      _remainingSeconds = _period - (now % _period);
    });
  }

  void _generateCode() {
    if (_secret == null) return;

    final secretBase32 = String.fromCharCodes(_secret!);
    final otp = widget.data.card.data;
    final code = OTP.generateTOTPCodeString(
      secretBase32,
      DateTime.now().millisecondsSinceEpoch,
      length: otp.digits,
      interval: _period,
      isGoogle: true,
      algorithm: Algorithm.SHA1,
    );

    setState(() {
      _currentCode = code;
    });
  }

  Future<void> _copyCode() async {
    if (_currentCode == null) return;

    final copied = await copyCardValue(
      ref: ref,
      itemId: _itemId,
      text: _currentCode,
    );
    if (!copied) return;
    setState(() => _codeCopied = true);
    Toaster.success(title: 'Код скопирован');

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _codeCopied = false);
    });
  }

  Widget? _buildTotpSection(ThemeData theme) {
    if (_isLoadingSecret) {
      return const SizedBox(
        height: 56,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_currentCode == null) {
      return null;
    }

    final progress = _remainingSeconds / _period;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.security, size: 16),
              const SizedBox(width: 8),
              Text('TOTP Code', style: theme.textTheme.labelMedium),
              const Spacer(),
              Text('$_remainingSecondsс'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                _currentCode!,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontFamily: 'monospace',
                  letterSpacing: 2,
                ),
              ),
              const Spacer(),
              IconButton.filled(
                onPressed: _copyCode,
                icon: Icon(_codeCopied ? Icons.check : Icons.copy, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: progress),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.data.card.item;
    final otp = widget.data.card.data;
    final title = otp.issuer ?? otp.accountName ?? 'OTP';
    final subtitle = [
      if (otp.issuer != null && otp.accountName != null) otp.accountName!,
      '${otp.digits} цифр',
      '${otp.period ?? 30}с',
    ].join(' • ');

    return ExpandableListCard(
      title: title,
      subtitle: subtitle,
      fallbackIcon: Icons.vpn_key,
      category: widget.data.meta.category,
      description: item.description,
      tags: widget.data.meta.tags,
      modifiedAt: item.modifiedAt,
      isFavorite: item.isFavorite,
      isPinned: item.isPinned,
      isArchived: item.isArchived,
      isDeleted: item.isDeleted,
      onToggleFavorite: widget.onToggleFavorite,
      onTogglePin: widget.onTogglePin,
      onToggleArchive: widget.onToggleArchive,
      onDelete: widget.onDelete,
      onRestore: widget.onRestore,
      onOpenView: widget.onOpenView,
      onOpenHistory: widget.onOpenHistory,
      onExpandedChanged: _onExpandedChanged,
      customExpandedContent: _buildTotpSection(Theme.of(context)),
      copyActions: [
        CardActionItem(
          label: 'Код',
          onPressed: _copyCode,
          icon: Icons.copy,
          successIcon: Icons.check,
          isSuccess: _codeCopied,
        ),
      ],
    );
  }
}
