import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/cards/shared/index.dart';
import 'package:hoplixi/main_store/models/dto/index.dart';
import 'package:hoplixi/main_store/provider/dao_providers.dart';
import 'package:otp/otp.dart';

class TotpListCard extends ConsumerStatefulWidget {
  final OtpCardDto otp;
  final VoidCallback? onTap;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onTogglePin;
  final VoidCallback? onToggleArchive;
  final VoidCallback? onDelete;
  final VoidCallback? onRestore;
  final VoidCallback? onOpenHistory;

  const TotpListCard({
    super.key,
    required this.otp,
    this.onTap,
    this.onToggleFavorite,
    this.onTogglePin,
    this.onToggleArchive,
    this.onDelete,
    this.onRestore,
    this.onOpenHistory,
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

  @override
  void dispose() {
    _stopTimerAndClearSecret();
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
      final otpDao = await ref.read(otpDaoProvider.future);
      final secretBytes = await otpDao.getOtpSecretById(widget.otp.id);

      if (secretBytes != null && mounted) {
        setState(() {
          _secret = secretBytes;
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

  void _stopTimerAndClearSecret() {
    _totpTimer?.cancel();
    _totpTimer = null;
    _clearSecret();
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
      if (_remainingSeconds == widget.otp.period || _remainingSeconds == 0) {
        _generateCode();
      }
    });
  }

  void _updateRemainingSeconds() {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final period = widget.otp.period;
    setState(() {
      _remainingSeconds = period - (now % period);
    });
  }

  void _generateCode() {
    if (_secret == null) return;

    final secretBase32 = String.fromCharCodes(_secret!);
    final code = OTP.generateTOTPCodeString(
      secretBase32,
      DateTime.now().millisecondsSinceEpoch,
      length: widget.otp.digits,
      interval: widget.otp.period,
      isGoogle: true,
      algorithm: Algorithm.SHA1,
    );

    setState(() {
      _currentCode = code;
    });
  }

  Future<void> _copyCode() async {
    if (_currentCode == null) return;

    await Clipboard.setData(ClipboardData(text: _currentCode!));
    setState(() => _codeCopied = true);
    Toaster.success(title: 'Код скопирован');

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _codeCopied = false);
    });

    final vaultItemDao = await ref.read(vaultItemDaoProvider.future);
    await vaultItemDao.incrementUsage(widget.otp.id);
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

    final progress = _remainingSeconds / widget.otp.period;

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
    final otp = widget.otp;
    final title = otp.issuer ?? otp.accountName ?? 'OTP';
    final subtitle = [
      if (otp.issuer != null && otp.accountName != null) otp.accountName!,
      '${otp.digits} цифр',
      '${otp.period}с',
    ].join(' • ');

    return ExpandableListCard(
      title: title,
      subtitle: subtitle,
      icon: Icons.vpn_key,
      category: otp.category,
      tags: otp.tags,
      usedCount: otp.usedCount,
      modifiedAt: otp.modifiedAt,
      isFavorite: otp.isFavorite,
      isPinned: otp.isPinned,
      isArchived: otp.isArchived,
      isDeleted: otp.isDeleted,
      onToggleFavorite: widget.onToggleFavorite,
      onTogglePin: widget.onTogglePin,
      onToggleArchive: widget.onToggleArchive,
      onDelete: widget.onDelete,
      onRestore: widget.onRestore,
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
