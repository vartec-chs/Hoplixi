import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/cards/shared/index.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/models/dto/index.dart';
import 'package:hoplixi/main_store/provider/dao_providers.dart';
import 'package:otp/otp.dart';

class PasswordListCard extends ConsumerStatefulWidget {
  final PasswordCardDto password;
  final VoidCallback? onTap;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onTogglePin;
  final VoidCallback? onToggleArchive;
  final VoidCallback? onDelete;
  final VoidCallback? onRestore;
  final VoidCallback? onOpenHistory;

  const PasswordListCard({
    super.key,
    required this.password,
    this.onTap,
    this.onToggleFavorite,
    this.onTogglePin,
    this.onToggleArchive,
    this.onDelete,
    this.onRestore,
    this.onOpenHistory,
  });

  @override
  ConsumerState<PasswordListCard> createState() => _PasswordListCardState();
}

class _PasswordListCardState extends ConsumerState<PasswordListCard> {
  bool _passwordCopied = false;
  bool _loginCopied = false;
  bool _urlCopied = false;
  bool _isLoadingOtp = false;
  bool _codeCopied = false;

  (VaultItemsData, OtpItemsData)? _linkedOtp;
  Uint8List? _secret;
  String? _currentCode;
  int _remainingSeconds = 0;
  Timer? _totpTimer;

  @override
  void dispose() {
    _stopTimerAndCleanupOtp();
    super.dispose();
  }

  Future<void> _onExpandedChanged(bool expanded) async {
    if (expanded) {
      await _checkAndLoadOtp();
    } else {
      _stopTimerAndCleanupOtp();
    }
  }

  Future<void> _checkAndLoadOtp() async {
    setState(() => _isLoadingOtp = true);

    try {
      final otpDao = await ref.read(otpDaoProvider.future);
      final otp = await otpDao.getByPasswordItemId(widget.password.id);
      if (otp == null || !mounted) return;

      _linkedOtp = otp;
      final (_, otpItem) = otp;
      final secretBytes = await otpDao.getOtpSecretById(otpItem.itemId);
      if (secretBytes == null || !mounted) return;

      setState(() {
        _secret = secretBytes;
      });
      _generateCode();
      _startTimer();
    } finally {
      if (mounted) setState(() => _isLoadingOtp = false);
    }
  }

  void _stopTimerAndCleanupOtp() {
    _totpTimer?.cancel();
    _totpTimer = null;
    if (_secret != null) {
      for (int i = 0; i < _secret!.length; i++) {
        _secret![i] = 0;
      }
      _secret = null;
    }
    _currentCode = null;
    _linkedOtp = null;
    _remainingSeconds = 0;
  }

  void _startTimer() {
    _totpTimer?.cancel();
    if (_linkedOtp == null) return;
    _updateRemainingSeconds();

    _totpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      _updateRemainingSeconds();
      final (_, linkedOtpItem) = _linkedOtp!;
      if (_remainingSeconds == linkedOtpItem.period || _remainingSeconds == 0) {
        _generateCode();
      }
    });
  }

  void _updateRemainingSeconds() {
    if (_linkedOtp == null) return;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final (_, linkedOtpItem) = _linkedOtp!;
    setState(() {
      _remainingSeconds = linkedOtpItem.period - (now % linkedOtpItem.period);
    });
  }

  void _generateCode() {
    if (_secret == null || _linkedOtp == null) return;
    final (_, linkedOtp) = _linkedOtp!;
    final secretBase32 = String.fromCharCodes(_secret!);

    final code = OTP.generateTOTPCodeString(
      secretBase32,
      DateTime.now().millisecondsSinceEpoch,
      length: linkedOtp.digits,
      interval: linkedOtp.period,
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

    if (_linkedOtp != null) {
      final (vaultOtp, _) = _linkedOtp!;
      final vaultItemDao = await ref.read(vaultItemDaoProvider.future);
      await vaultItemDao.incrementUsage(vaultOtp.id);
    }
  }

  Future<void> _copyPassword() async {
    final passwordDao = await ref.read(passwordDaoProvider.future);
    final passwordText = await passwordDao.getPasswordFieldById(
      widget.password.id,
    );
    if (passwordText == null) {
      Toaster.error(title: 'Не удалось получить пароль');
      return;
    }
    await Clipboard.setData(ClipboardData(text: passwordText));
    setState(() => _passwordCopied = true);
    Toaster.success(title: 'Пароль скопирован');
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _passwordCopied = false);
    });
    final vaultItemDao = await ref.read(vaultItemDaoProvider.future);
    await vaultItemDao.incrementUsage(widget.password.id);
  }

  Future<void> _copyLogin() async {
    final text = widget.password.email ?? widget.password.login;
    if (text == null || text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    setState(() => _loginCopied = true);
    Toaster.success(title: 'Логин скопирован');
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _loginCopied = false);
    });
    final vaultItemDao = await ref.read(vaultItemDaoProvider.future);
    await vaultItemDao.incrementUsage(widget.password.id);
  }

  Future<void> _copyUrl() async {
    final text = widget.password.url;
    if (text == null || text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    setState(() => _urlCopied = true);
    Toaster.success(title: 'URL скопирован');
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _urlCopied = false);
    });
    final vaultItemDao = await ref.read(vaultItemDaoProvider.future);
    await vaultItemDao.incrementUsage(widget.password.id);
  }

  Widget? _buildTotpSection(ThemeData theme) {
    if (_isLoadingOtp) {
      return const SizedBox(
        height: 56,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_linkedOtp == null || _currentCode == null) return null;

    final (_, linkedOtpForProgress) = _linkedOtp!;
    final progress = _remainingSeconds / linkedOtpForProgress.period;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.security, size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'TOTP Code',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
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
    final password = widget.password;
    final displayLogin = password.email ?? password.login;
    final hostUrl = CardUtils.extractHost(password.url);
    final now = DateTime.now();
    final isExpired =
        password.expireAt != null && password.expireAt!.isBefore(now);
    final isExpiringSoon =
        !isExpired &&
        password.expireAt != null &&
        password.expireAt!.difference(now).inDays <= 30;

    return ExpandableListCard(
      title: password.name,
      subtitle: displayLogin,
      trailingSubtitle: hostUrl.isEmpty ? null : hostUrl,
      icon: Icons.lock,
      category: password.category,
      description: password.description,
      tags: password.tags,
      usedCount: password.usedCount,
      modifiedAt: password.modifiedAt,
      isFavorite: password.isFavorite,
      isPinned: password.isPinned,
      isArchived: password.isArchived,
      isDeleted: password.isDeleted,
      isExpired: isExpired,
      isExpiringSoon: isExpiringSoon,
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
          label: 'Пароль',
          onPressed: _copyPassword,
          icon: Icons.lock,
          successIcon: Icons.check,
          isSuccess: _passwordCopied,
        ),
        if (displayLogin != null)
          CardActionItem(
            label: 'Логин',
            onPressed: _copyLogin,
            icon: Icons.person,
            successIcon: Icons.check,
            isSuccess: _loginCopied,
          ),
        if ((password.url ?? '').isNotEmpty)
          CardActionItem(
            label: 'URL',
            onPressed: _copyUrl,
            icon: Icons.link,
            successIcon: Icons.check,
            isSuccess: _urlCopied,
          ),
      ],
    );
  }
}
