import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/constants/main_constants.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/cards/shared/index.dart';
import 'package:hoplixi/main_store/models/dto/index.dart';
import 'package:hoplixi/main_store/provider/dao_providers.dart';
import 'package:hoplixi/routing/paths.dart';
import 'package:otp/otp.dart';

/// Карточка TOTP для режима сетки
/// Минимальная ширина: 240px для предотвращения чрезмерного сжатия
class TotpGridCard extends ConsumerStatefulWidget {
  final OtpCardDto otp;
  final VoidCallback? onTap;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onTogglePin;
  final VoidCallback? onToggleArchive;
  final VoidCallback? onDelete;
  final VoidCallback? onRestore;

  const TotpGridCard({
    super.key,
    required this.otp,
    this.onTap,
    this.onToggleFavorite,
    this.onTogglePin,
    this.onToggleArchive,
    this.onDelete,
    this.onRestore,
  });

  @override
  ConsumerState<TotpGridCard> createState() => _TotpGridCardState();
}

class _TotpGridCardState extends ConsumerState<TotpGridCard>
    with TickerProviderStateMixin {
  bool _codeCopied = false;
  bool _isLoadingSecret = false;
  bool _isCodeVisible = false;

  late AnimationController _iconsController;
  late Animation<double> _iconsAnimation;

  // TOTP state
  Uint8List? _secret;
  String? _currentCode;
  int _remainingSeconds = 0;
  Timer? _totpTimer;

  @override
  void initState() {
    super.initState();
    _iconsController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _iconsAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _iconsController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _clearSecret();
    _totpTimer?.cancel();
    _iconsController.dispose();
    super.dispose();
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

  void _onHoverChanged(bool isHovered) {
    if (isHovered) {
      _iconsController.forward();
    } else {
      _iconsController.reverse();
    }
  }

  void _toggleCodeVisibility() {
    if (_isCodeVisible) {
      _stopTimerAndClearSecret();
      setState(() => _isCodeVisible = false);
    } else {
      _loadSecretAndStartTimer();
      setState(() => _isCodeVisible = true);
    }
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
    setState(() {
      _remainingSeconds = 0;
    });
  }

  void _startTimer() {
    _totpTimer?.cancel();
    _updateRemainingSeconds();

    _totpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || !_isCodeVisible) {
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

    try {
      final secretBase32 = String.fromCharCodes(_secret!);

      final code = OTP.generateTOTPCodeString(
        secretBase32,
        DateTime.now().millisecondsSinceEpoch,
        length: widget.otp.digits,
        interval: widget.otp.period,
        algorithm: Algorithm.SHA1,
        isGoogle: true,
      );

      setState(() {
        _currentCode = code;
      });
    } catch (e) {
      Toaster.error(title: 'Ошибка генерации кода', description: '$e');
    }
  }

  Future<void> _copyCode() async {
    if (_currentCode != null) {
      await Clipboard.setData(ClipboardData(text: _currentCode!));
      setState(() => _codeCopied = true);
      Toaster.success(title: 'Код скопирован');

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _codeCopied = false);
      });

      final otpDao = await ref.read(otpDaoProvider.future);
      await otpDao.incrementUsage(widget.otp.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final otp = widget.otp;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final cardPadding = isMobile ? 8.0 : 12.0;
    final minCardWidth = isMobile ? 160.0 : 240.0;

    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: minCardWidth),
      child: Stack(
        children: [
          Card(
            margin: EdgeInsets.zero,
            child: MouseRegion(
              onEnter: (_) => _onHoverChanged(true),
              onExit: (_) => _onHoverChanged(false),
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: EdgeInsets.all(cardPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Заголовок
                      Row(
                        children: [
                          Container(
                            width: isMobile ? 32 : 40,
                            height: isMobile ? 32 : 40,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.vpn_key,
                              size: isMobile ? 16 : 20,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),

                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              otp.issuer ?? 'Без названия',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!isMobile) const Spacer(),
                          if (!otp.isDeleted)
                            FadeTransition(
                              opacity: _iconsAnimation,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (otp.isArchived)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 4),
                                      child: Icon(
                                        Icons.archive,
                                        size: isMobile ? 14 : 16,
                                        color: Colors.blueGrey,
                                      ),
                                    ),
                                  if (otp.usedCount >=
                                      MainConstants.popularItemThreshold)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 4),
                                      child: Icon(
                                        Icons.local_fire_department,
                                        size: isMobile ? 14 : 16,
                                        color: Colors.deepOrange,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: isMobile ? 4 : 6),

                      if (otp.category != null) ...[
                        CardCategoryBadge(
                          name: otp.category!.name,
                          color: otp.category!.color,
                        ),
                        SizedBox(height: isMobile ? 3 : 4),
                      ],

                      if (otp.issuer != null && otp.issuer!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          otp.issuer!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],

                      SizedBox(height: isMobile ? 4 : 6),

                      if (otp.tags != null && otp.tags!.isNotEmpty) ...[
                        CardTagsList(tags: otp.tags!, showTitle: false),
                        SizedBox(height: isMobile ? 3 : 4),
                      ],

                      // TOTP код
                      if (!otp.isDeleted) ...[
                        if (_isCodeVisible) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                if (_isLoadingSecret)
                                  const CircularProgressIndicator()
                                else if (_currentCode != null) ...[
                                  Text(
                                    _currentCode!,
                                    style: theme.textTheme.headlineMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 4,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  LinearProgressIndicator(
                                    value: _remainingSeconds / otp.period,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Обновление через $_remainingSeconds сек',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        FadeTransition(
                          opacity: _iconsAnimation,
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _isCodeVisible ? _copyCode : null,
                                  icon: Icon(
                                    _codeCopied ? Icons.check : Icons.copy,
                                    size: 16,
                                  ),
                                  label: const Text(
                                    'Копировать',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 8,
                                    ),
                                    minimumSize: Size.zero,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _toggleCodeVisibility,
                                  icon: Icon(
                                    _isCodeVisible
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    size: 16,
                                  ),
                                  label: Text(
                                    _isCodeVisible ? 'Скрыть' : 'Показать',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 8,
                                    ),
                                    minimumSize: Size.zero,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        FadeTransition(
                          opacity: _iconsAnimation,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: Icon(
                                  otp.isPinned
                                      ? Icons.push_pin
                                      : Icons.push_pin_outlined,
                                  size: 18,
                                  color: otp.isPinned ? Colors.orange : null,
                                ),
                                onPressed: widget.onTogglePin,
                                tooltip: 'Закрепить',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                              IconButton(
                                icon: Icon(
                                  otp.isFavorite
                                      ? Icons.star
                                      : Icons.star_border,
                                  size: 18,
                                  color: otp.isFavorite ? Colors.amber : null,
                                ),
                                onPressed: widget.onToggleFavorite,
                                tooltip: 'Избранное',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () {
                                  context.push(
                                    AppRoutesPaths.dashboardEntityEdit(
                                      EntityType.otp,
                                      otp.id,
                                    ),
                                  );
                                },
                                tooltip: 'Редактировать',
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            TextButton.icon(
                              onPressed: widget.onRestore,
                              icon: const Icon(Icons.restore, size: 18),
                              label: const Text('Восстановить'),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: widget.onDelete,
                              icon: const Icon(
                                Icons.delete_forever,
                                size: 18,
                                color: Colors.red,
                              ),
                              label: const Text(
                                'Удалить',
                                style: TextStyle(color: Colors.red),
                              ),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          ...CardStatusIndicators(
            isPinned: otp.isPinned,
            isFavorite: otp.isFavorite,
            isArchived: otp.isArchived,
          ).buildPositionedWidgets(),
        ],
      ),
    );
  }
}
