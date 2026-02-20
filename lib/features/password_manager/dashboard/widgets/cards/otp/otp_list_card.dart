// ---------- Карточка OTP (TOTP) для режима списка ----------

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/main_store/models/dto/index.dart';
import 'package:hoplixi/main_store/provider/dao_providers.dart';
import 'package:otp/otp.dart';

import '../shared/index.dart';

/// Карточка TOTP для режима списка (рефакторинг с использованием shared компонентов)
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

class _TotpListCardState extends ConsumerState<TotpListCard>
    with TickerProviderStateMixin {
  bool _isExpanded = false;
  bool _isHovered = false;
  bool _codeCopied = false;
  bool _isLoadingSecret = false;

  late AnimationController _expandController;
  late Animation<double> _expandAnimation;
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
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _expandController, curve: Curves.easeInOut),
    );

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
    _expandController.dispose();
    _iconsController.dispose();
    super.dispose();
  }

  /// Очищает секрет из памяти
  void _clearSecret() {
    if (_secret != null) {
      // Перезаписываем данные нулями перед очисткой
      for (int i = 0; i < _secret!.length; i++) {
        _secret![i] = 0;
      }
      _secret = null;
    }
    _currentCode = null;
  }

  void _toggleExpanded() {
    setState(() => _isExpanded = !_isExpanded);
    if (_isExpanded) {
      _expandController.forward();
      _iconsController.forward();
      // Загружаем секрет и начинаем генерацию кода
      _loadSecretAndStartTimer();
    } else {
      _expandController.reverse();
      if (!_isHovered) {
        _iconsController.reverse();
      }
      // Очищаем секрет при закрытии карточки
      _stopTimerAndClearSecret();
    }
  }

  void _onHoverChanged(bool isHovered) {
    setState(() => _isHovered = isHovered);
    if (isHovered) {
      _iconsController.forward();
    } else if (!_isExpanded) {
      _iconsController.reverse();
    }
  }

  /// Загружает секрет из БД и запускает таймер генерации кода
  Future<void> _loadSecretAndStartTimer() async {
    if (_secret != null) {
      // Секрет уже загружен, просто обновляем код
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

  /// Останавливает таймер и очищает секрет
  void _stopTimerAndClearSecret() {
    _totpTimer?.cancel();
    _totpTimer = null;
    _clearSecret();
    setState(() {
      _remainingSeconds = 0;
    });
  }

  /// Запускает таймер обновления кода
  void _startTimer() {
    _totpTimer?.cancel();
    _updateRemainingSeconds();

    _totpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || !_isExpanded) {
        timer.cancel();
        return;
      }

      _updateRemainingSeconds();

      // Если время истекло, генерируем новый код
      if (_remainingSeconds == widget.otp.period || _remainingSeconds == 0) {
        _generateCode();
      }
    });
  }

  /// Обновляет оставшееся время до смены кода
  void _updateRemainingSeconds() {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final period = widget.otp.period;
    setState(() {
      _remainingSeconds = period - (now % period);
    });
  }

  /// Генерирует TOTP код
  void _generateCode() {
    if (_secret == null) return;

    try {
      // Секрет в БД хранится как ASCII коды Base32 строки (codeUnits),
      // поэтому просто конвертируем байты обратно в строку
      final secretBase32 = String.fromCharCodes(_secret!);

      final code = OTP.generateTOTPCodeString(
        secretBase32,
        DateTime.now().millisecondsSinceEpoch,
        length: widget.otp.digits,
        interval: widget.otp.period,
        isGoogle: true, // true = секрет передаётся как Base32 строка
        algorithm: Algorithm.SHA1,
      );

      setState(() {
        _currentCode = code;
      });
    } catch (e) {
      Toaster.error(title: 'Ошибка генерации кода', description: '$e');
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

    final vaultItemDao = await ref.read(vaultItemDaoProvider.future);
    await vaultItemDao.incrementUsage(widget.otp.id);
  }

  /// Форматирует код с разделением (например: "123 456")
  String _formatCode(String code) {
    if (code.length <= 3) return code;

    final buffer = StringBuffer();
    for (int i = 0; i < code.length; i++) {
      if (i > 0 && i % 3 == 0) {
        buffer.write(' ');
      }
      buffer.write(code[i]);
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayName = widget.otp.issuer ?? widget.otp.accountName ?? 'OTP';
    final subtitle = widget.otp.issuer != null ? widget.otp.accountName : null;

    return Stack(
      children: [
        Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.hardEdge,
          elevation: 0,
          borderOnForeground: true,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),

          child: Column(
            children: [
              _buildHeader(theme, displayName, subtitle),
              _buildExpandedContent(theme),
            ],
          ),
        ),
        // Индикаторы статуса
        ...CardStatusIndicators(
          isPinned: widget.otp.isPinned,
          isFavorite: widget.otp.isFavorite,
          isArchived: widget.otp.isArchived,
        ).buildPositionedWidgets(),
      ],
    );
  }

  /// Строит заголовок карточки
  Widget _buildHeader(ThemeData theme, String displayName, String? subtitle) {
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
                  color: theme.colorScheme.primaryContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.security, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 6),
              // Основная информация
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Категория
                    if (widget.otp.category != null)
                      CardCategoryBadge(
                        name: widget.otp.category!.name,
                        color: widget.otp.category!.color,
                      ),
                    // Название
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            displayName,
                            style: theme.textTheme.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
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

  /// Строит кнопки действий в заголовке
  Widget _buildHeaderActions(ThemeData theme) {
    final otp = widget.otp;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!otp.isDeleted) ...[
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
                    otp.isFavorite ? Icons.star : Icons.star_border,
                    color: otp.isFavorite ? Colors.amber : null,
                  ),
                  onPressed: widget.onToggleFavorite,
                  tooltip: otp.isFavorite
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
                    otp.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                    color: otp.isPinned ? Colors.orange : null,
                  ),
                  onPressed: widget.onTogglePin,
                  tooltip: otp.isPinned ? 'Открепить' : 'Закрепить',
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

  /// Строит развёрнутый контент
  Widget _buildExpandedContent(ThemeData theme) {
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
            const SizedBox(height: 16),

            // TOTP код с прогресс-баром
            _buildTotpCodeSection(theme),

            // Теги
            if (widget.otp.tags != null && widget.otp.tags!.isNotEmpty) ...[
              const SizedBox(height: 16),
              CardTagsList(tags: widget.otp.tags!),
            ],

            // Метаинформация
            const SizedBox(height: 12),
            CardMetaInfo(
              usedCount: widget.otp.usedCount,
              modifiedAt: widget.otp.modifiedAt,
            ),
            const SizedBox(height: 12),

            // Кнопки действий
            CardActionButtons(
              isDeleted: widget.otp.isDeleted,
              isArchived: widget.otp.isArchived,
              onRestore: widget.onRestore,
              onDelete: widget.onDelete,
              onToggleArchive: widget.onToggleArchive,
            ),
          ],
        ),
      ),
    );
  }

  /// Строит секцию с TOTP кодом и таймером
  Widget _buildTotpCodeSection(ThemeData theme) {
    final progress = _remainingSeconds / widget.otp.period;
    final isLowTime = _remainingSeconds <= 5;

    return Container(
      padding: const EdgeInsets.all(16),
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
        children: [
          // Код
          if (_isLoadingSecret)
            const SizedBox(
              height: 48,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_currentCode != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Код разбитый на группы по 3 цифры
                Text(
                  _formatCode(_currentCode!),
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                    color: isLowTime ? Colors.red : null,
                  ),
                ),
                const SizedBox(width: 16),
                // Кнопка копирования
                IconButton.filled(
                  onPressed: _copyCode,
                  icon: Icon(_codeCopied ? Icons.check : Icons.copy),
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
            SizedBox(
              height: 48,
              child: Center(
                child: Text(
                  'Нажмите чтобы показать код',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ),
            ),

          const SizedBox(height: 12),

          // Прогресс-бар с таймером
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation(
                      isLowTime ? Colors.red : theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isLowTime
                      ? Colors.red.withOpacity(0.1)
                      : theme.colorScheme.primaryContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$_remainingSecondsс',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isLowTime ? Colors.red : theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
