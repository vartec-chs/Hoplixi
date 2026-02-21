import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/cards/shared/index.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/models/dto/index.dart';
import 'package:hoplixi/main_store/provider/dao_providers.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:otp/otp.dart';

/// Карточка пароля для режима списка (переписана с shared компонентами)
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

class _PasswordListCardState extends ConsumerState<PasswordListCard>
    with TickerProviderStateMixin {
  bool _isExpanded = false;
  bool _isHovered = false;
  bool _passwordCopied = false;
  bool _loginCopied = false;
  bool _urlCopied = false;
  bool _isLoadingOtp = false;
  bool _codeCopied = false;

  late final AnimationController _expandController;
  late final Animation<double> _expandAnimation;
  late final AnimationController _iconsController;
  late final Animation<double> _iconsAnimation;

  // TOTP state
  (VaultItemsData, OtpItemsData)? _linkedOtp;
  Uint8List? _secret;
  String? _currentCode;
  int _remainingSeconds = 0;
  Timer? _totpTimer;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOut,
    );

    _iconsController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _iconsAnimation = CurvedAnimation(
      parent: _iconsController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _stopTimerAndCleanupOtp();
    _expandController.dispose();
    _iconsController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() => _isExpanded = !_isExpanded);
    if (_isExpanded) {
      _expandController.forward();
      _iconsController.forward();
      _checkAndLoadOtp();
    } else {
      _expandController.reverse();
      if (!_isHovered) {
        _iconsController.reverse();
      }
      _stopTimerAndCleanupOtp();
    }
  }

  Future<void> _checkAndLoadOtp() async {
    setState(() => _isLoadingOtp = true);

    try {
      final otpDao = await ref.read(otpDaoProvider.future);
      final otp = await otpDao.getByPasswordItemId(widget.password.id);

      if (otp != null && mounted) {
        _linkedOtp = otp;
        final (_, otpItem) = otp;
        final secretBytes = await otpDao.getOtpSecretById(otpItem.itemId);

        if (secretBytes != null && mounted) {
          setState(() {
            _secret = secretBytes;
          });
          _generateCode();
          _startTimer();
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error loading OTP for password: $e');
    } finally {
      if (mounted) setState(() => _isLoadingOtp = false);
    }
  }

  void _stopTimerAndCleanupOtp() {
    _totpTimer?.cancel();
    _totpTimer = null;
    // Очищаем секрет
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
      if (!mounted || !_isExpanded) {
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
    final period = linkedOtpItem.period;
    setState(() {
      _remainingSeconds = period - (now % period);
    });
  }

  void _generateCode() {
    if (_secret == null || _linkedOtp == null) return;
    final (_, linkedOtp) = _linkedOtp!;

    try {
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
    } catch (e) {
      // ignore: avoid_print
      print('Error generating TOTP code: $e');
    }
  }

  Future<void> _copyCode() async {
    if (_currentCode == null) return;

    await Clipboard.setData(ClipboardData(text: _currentCode!));
    setState(() => _codeCopied = true);
    Toaster.success(title: 'Код скопирован');

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _codeCopied = false);
    });

    // Инкрементируем использование связанного OTP
    if (_linkedOtp != null) {
      final (vaultOtp, _) = _linkedOtp!;
      final vaultItemDao = await ref.read(vaultItemDaoProvider.future);
      await vaultItemDao.incrementUsage(vaultOtp.id);
    }
  }

  String _formatCode(String code) {
    if (code.length <= 3) return code;
    final buffer = StringBuffer();
    for (int i = 0; i < code.length; i++) {
      if (i > 0 && i % 3 == 0) buffer.write(' ');
      buffer.write(code[i]);
    }
    return buffer.toString();
  }

  void _onHoverChanged(bool isHovered) {
    setState(() => _isHovered = isHovered);
    if (isHovered) {
      _iconsController.forward();
    } else if (!_isExpanded) {
      _iconsController.reverse();
    }
  }

  Future<void> _copyPassword() async {
    final passwordDao = await ref.read(passwordDaoProvider.future);
    final passwordText = await passwordDao.getPasswordFieldById(
      widget.password.id,
    );

    if (passwordText != null) {
      await Clipboard.setData(ClipboardData(text: passwordText));
      setState(() => _passwordCopied = true);
      Toaster.success(title: 'Пароль скопирован');

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _passwordCopied = false);
      });
    } else {
      Toaster.error(title: 'Не удалось получить пароль');
    }

    final vaultItemDao = await ref.read(vaultItemDaoProvider.future);
    await vaultItemDao.incrementUsage(widget.password.id);
  }

  Future<void> _copyLogin() async {
    final text = widget.password.email ?? widget.password.login;
    if (text != null && text.isNotEmpty) {
      await Clipboard.setData(ClipboardData(text: text));
      setState(() => _loginCopied = true);
      Toaster.success(title: 'Логин скопирован');

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _loginCopied = false);
      });
    }

    final vaultItemDao = await ref.read(vaultItemDaoProvider.future);
    await vaultItemDao.incrementUsage(widget.password.id);
  }

  Future<void> _copyUrl() async {
    final url = widget.password.url;
    if (url != null && url.isNotEmpty) {
      await Clipboard.setData(ClipboardData(text: url));
      setState(() => _urlCopied = true);
      Toaster.success(title: 'URL скопирован');

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _urlCopied = false);
      });
    }

    final vaultItemDao = await ref.read(vaultItemDaoProvider.future);
    await vaultItemDao.incrementUsage(widget.password.id);
  }

  List<CardActionItem> _buildCopyActions() {
    final displayLogin = widget.password.email ?? widget.password.login;
    final actions = <CardActionItem>[
      CardActionItem(
        label: 'Пароль',
        onPressed: _copyPassword,
        icon: Icons.lock,
        successIcon: Icons.check,
        isSuccess: _passwordCopied,
      ),
    ];

    if (displayLogin != null) {
      actions.add(
        CardActionItem(
          label: 'Логин',
          onPressed: _copyLogin,
          icon: Icons.person,
          successIcon: Icons.check,
          isSuccess: _loginCopied,
        ),
      );
    }

    if (widget.password.url != null && widget.password.url!.isNotEmpty) {
      actions.add(
        CardActionItem(
          label: 'URL',
          onPressed: _copyUrl,
          icon: Icons.link,
          successIcon: Icons.check,
          isSuccess: _urlCopied,
        ),
      );
    }

    return actions;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final password = widget.password;
    final displayLogin = password.email ?? password.login;
    final hostUrl = CardUtils.extractHost(password.url);

    // Вычисление состояния истечения срока действия
    final DateTime now = DateTime.now();
    final bool isExpired =
        password.expireAt != null && password.expireAt!.isBefore(now);
    final bool isExpiringSoon =
        !isExpired &&
        password.expireAt != null &&
        password.expireAt!.difference(now).inDays <= 30; // 30 дней до истечения

    return Stack(
      children: [
        Card(
          clipBehavior: Clip.hardEdge,
          margin: EdgeInsets.zero,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),

          child: Column(
            children: [
              // Основная часть карточки (заголовок)
              _buildHeader(
                theme,
                displayLogin,
                hostUrl,
                isExpired,
                isExpiringSoon,
              ),
              // Развернутый контент
              _buildExpandedContent(theme),
            ],
          ),
        ),
        // Индикаторы статуса
        ...CardStatusIndicators(
          isPinned: password.isPinned,
          isFavorite: password.isFavorite,
          isArchived: password.isArchived,
        ).buildPositionedWidgets(),
      ],
    );
  }

  Widget _buildHeader(
    ThemeData theme,
    String? displayLogin,
    String hostUrl,
    bool isExpired,
    bool isExpiringSoon,
  ) {
    final password = widget.password;

    return MouseRegion(
      onEnter: (_) => _onHoverChanged(true),
      onExit: (_) => _onHoverChanged(false),
      child: InkWell(
        onTap: _toggleExpanded,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              // Иконка
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.lock, color: theme.colorScheme.onSurface),
              ),
              const SizedBox(width: 6),
              // Основная информация
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (password.category != null)
                      CardCategoryBadge(
                        name: password.category!.name,
                        color: password.category!.color,
                      ),
                    Text(
                      password.name,
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (displayLogin != null || hostUrl.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (displayLogin != null) ...[
                            Expanded(
                              child: Text(
                                displayLogin,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.grey,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (hostUrl.isNotEmpty) const SizedBox(width: 4),
                          ],
                          if (hostUrl.isNotEmpty)
                            Text(
                              hostUrl,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey.shade600,
                                fontSize: 10,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // Иконки предупреждения об истечении
              if (isExpired)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    LucideIcons.clockAlert,
                    size: 18,
                    color: theme.colorScheme.error,
                  ),
                )
              else if (isExpiringSoon)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    LucideIcons.clock,
                    size: 18,
                    color: Colors.orange,
                  ),
                ),
              // Действия
              _buildHeaderActions(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderActions(ThemeData theme) {
    final password = widget.password;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!password.isDeleted) ...[
          AnimatedBuilder(
            animation: _iconsAnimation,
            builder: (context, child) {
              return IgnorePointer(
                ignoring: _iconsAnimation.value == 0,
                child: Opacity(opacity: _iconsAnimation.value, child: child),
              );
            },
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    password.isFavorite ? Icons.star : Icons.star_border,
                    color: password.isFavorite ? Colors.amber : null,
                  ),
                  onPressed: widget.onToggleFavorite,
                  tooltip: password.isFavorite
                      ? 'Убрать из избранного'
                      : 'В избранное',
                ),
              ],
            ),
          ),
          AnimatedBuilder(
            animation: _iconsAnimation,
            builder: (context, child) {
              return IgnorePointer(
                ignoring: _iconsAnimation.value == 0,
                child: SizeTransition(
                  sizeFactor: _iconsAnimation,
                  axis: Axis.horizontal,
                  child: child,
                ),
              );
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    password.isPinned
                        ? Icons.push_pin
                        : Icons.push_pin_outlined,
                    color: password.isPinned ? Colors.orange : null,
                  ),
                  onPressed: widget.onTogglePin,
                  tooltip: password.isPinned ? 'Открепить' : 'Закрепить',
                ),
                if (widget.onOpenHistory != null)
                  IconButton(
                    icon: const Icon(Icons.history, size: 18),
                    onPressed: widget.onOpenHistory,
                    tooltip: 'История',
                  ),
              ],
            ),
          ),
        ] else ...[
          IconButton(
            icon: const Icon(Icons.restore_from_trash),
            onPressed: widget.onRestore,
            tooltip: 'Восстановить',
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever, color: Colors.red),
            onPressed: widget.onDelete,
            tooltip: 'Удалить навсегда',
          ),
        ],
        IconButton(
          icon: Icon(
            _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
          ),
          onPressed: _toggleExpanded,
        ),
      ],
    );
  }

  Widget _buildExpandedContent(ThemeData theme) {
    final password = widget.password;

    return AnimatedBuilder(
      animation: _expandAnimation,
      builder: (context, child) {
        return ClipRect(
          child: Align(
            alignment: Alignment.topCenter,
            heightFactor: _expandAnimation.value,
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Категория (расширенная)
            if (password.category != null) ...[
              CardCategoryBadge(
                name: password.category!.name,
                color: password.category!.color,
                showIcon: true,
              ),
              const SizedBox(height: 12),
            ],

            // Описание
            if (password.description != null &&
                password.description!.isNotEmpty) ...[
              Text(
                'Описание:',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(password.description!, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 12),
            ],

            // TOTP Section
            if (_linkedOtp != null || _isLoadingOtp) ...[
              _buildTotpCodeSection(theme),
              const SizedBox(height: 12),
            ],

            // Кнопки копирования (горизонтальный скролл)
            HorizontalScrollableActions(actions: _buildCopyActions()),

            // Теги
            if (password.tags != null && password.tags!.isNotEmpty) ...[
              const SizedBox(height: 12),
              CardTagsList(tags: password.tags),
            ],

            // Метаинформация
            const SizedBox(height: 12),
            CardMetaInfo(
              usedCount: password.usedCount,
              modifiedAt: password.modifiedAt,
            ),

            // Кнопки удаления/восстановления/архивации
            const SizedBox(height: 12),
            CardActionButtons(
              isDeleted: password.isDeleted,
              isArchived: password.isArchived,
              onRestore: widget.onRestore,
              onDelete: widget.onDelete,
              onToggleArchive: widget.onToggleArchive,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotpCodeSection(ThemeData theme) {
    if (_isLoadingOtp && _linkedOtp == null) {
      return const SizedBox(
        height: 60,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_linkedOtp == null) return const SizedBox.shrink();

    final (_, linkedOtpForProgress) = _linkedOtp!;
    final progress = _remainingSeconds / linkedOtpForProgress.period;
    final isLowTime = _remainingSeconds <= 5;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLowTime
              ? Colors.red.withOpacity(0.5)
              : theme.colorScheme.outline.withOpacity(0.2),
          width: 1,
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
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (_currentCode != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isLowTime
                        ? Colors.red.withOpacity(0.1)
                        : theme.colorScheme.primaryContainer.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$_remainingSecondsс',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isLowTime ? Colors.red : theme.colorScheme.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (_currentCode != null)
            Row(
              children: [
                Text(
                  _formatCode(_currentCode!),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: isLowTime ? Colors.red : null,
                  ),
                ),
                const Spacer(),
                IconButton.filled(
                  onPressed: _copyCode,
                  icon: Icon(_codeCopied ? Icons.check : Icons.copy, size: 18),
                  constraints: const BoxConstraints(
                    minHeight: 32,
                    minWidth: 32,
                  ),
                  padding: EdgeInsets.zero,
                  style: IconButton.styleFrom(
                    backgroundColor: _codeCopied
                        ? Colors.green
                        : theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  tooltip: 'Копировать код',
                ),
              ],
            )
          else
            const Center(child: Text('Код недоступен')),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(
                isLowTime ? Colors.red : theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
