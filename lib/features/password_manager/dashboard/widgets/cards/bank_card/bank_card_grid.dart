// ---------- Карточки для банковских карт ----------

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/constants/main_constants.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/main_store/models/dto/index.dart';
import 'package:hoplixi/routing/paths.dart';
import 'package:hoplixi/shared/ui/button.dart';

/// Карточка банковской карты для режима сетки
class BankCardGridCard extends ConsumerStatefulWidget {
  final BankCardCardDto bankCard;
  final VoidCallback? onTap;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onTogglePin;
  final VoidCallback? onToggleArchive;
  final VoidCallback? onDelete;
  final VoidCallback? onRestore;

  const BankCardGridCard({
    super.key,
    required this.bankCard,
    this.onTap,
    this.onToggleFavorite,
    this.onTogglePin,
    this.onToggleArchive,
    this.onDelete,
    this.onRestore,
  });

  @override
  ConsumerState<BankCardGridCard> createState() => _BankCardGridCardState();
}

class _BankCardGridCardState extends ConsumerState<BankCardGridCard>
    with TickerProviderStateMixin {
  bool _cardNumberCopied = false;
  bool _isHovered = false;
  late AnimationController _iconsController;
  late Animation<double> _iconsAnimation;

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
    _iconsController.dispose();
    super.dispose();
  }

  void _onHoverChanged(bool isHovered) {
    setState(() => _isHovered = isHovered);
    if (isHovered) {
      _iconsController.forward();
    } else {
      _iconsController.reverse();
    }
  }

  Color _parseColor(String? colorHex) {
    if (colorHex == null || colorHex.isEmpty) return Colors.grey;
    try {
      final hex = colorHex.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return Colors.grey;
    }
  }

  String _maskCardNumber(String cardNumber) {
    final digitsOnly = cardNumber.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length < 4) return '•••• ••••';
    final lastFour = digitsOnly.substring(digitsOnly.length - 4);
    return '•••• $lastFour';
  }

  Color _getCardTypeColor(String? cardType) {
    switch (cardType?.toLowerCase()) {
      case 'debit':
        return Colors.green;
      case 'credit':
        return Colors.blue;
      case 'prepaid':
        return Colors.orange;
      case 'virtual':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getCardTypeLabel(String? cardType) {
    switch (cardType?.toLowerCase()) {
      case 'debit':
        return 'Дебетовая';
      case 'credit':
        return 'Кредитная';
      case 'prepaid':
        return 'Предоплаченная';
      case 'virtual':
        return 'Виртуальная';
      default:
        return 'Карта';
    }
  }

  bool _isExpired() {
    final now = DateTime.now();
    final expiryYear = int.tryParse(widget.bankCard.expiryYear) ?? 0;
    final expiryMonth = int.tryParse(widget.bankCard.expiryMonth) ?? 0;

    if (expiryYear < now.year) return true;
    if (expiryYear == now.year && expiryMonth < now.month) return true;
    return false;
  }

  bool _isExpiringSoon() {
    if (_isExpired()) return false;

    final now = DateTime.now();
    final expiryYear = int.tryParse(widget.bankCard.expiryYear) ?? 0;
    final expiryMonth = int.tryParse(widget.bankCard.expiryMonth) ?? 0;

    final expiryDate = DateTime(expiryYear, expiryMonth + 1, 0);
    final threeMonthsFromNow = now.add(const Duration(days: 90));

    return expiryDate.isBefore(threeMonthsFromNow);
  }

  Future<void> _copyCardNumber() async {
    await Clipboard.setData(
      ClipboardData(
        text: widget.bankCard.cardNumber.replaceAll(RegExp(r'\D'), ''),
      ),
    );
    setState(() => _cardNumberCopied = true);
    Toaster.success(title: 'Номер карты скопирован');

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _cardNumberCopied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maskedNumber = _maskCardNumber(widget.bankCard.cardNumber);
    final isExpired = _isExpired();
    final isExpiringSoon = _isExpiringSoon();

    return Stack(
      children: [
        Card(
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isExpired
                ? const BorderSide(color: Colors.red, width: 1.5)
                : isExpiringSoon
                ? const BorderSide(color: Colors.orange, width: 1.5)
                : BorderSide.none,
          ),
          child: MouseRegion(
            onEnter: (_) => _onHoverChanged(true),
            onExit: (_) => _onHoverChanged(false),
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Заголовок
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: _getCardTypeColor(
                              widget.bankCard.cardType,
                            ).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.credit_card,
                            size: 18,
                            color: _getCardTypeColor(widget.bankCard.cardType),
                          ),
                        ),
                        const Spacer(),
                        if (!widget.bankCard.isDeleted) ...[
                          // Иконки состояния с анимацией
                          AnimatedBuilder(
                            animation: _iconsAnimation,
                            builder: (context, child) {
                              return Opacity(
                                opacity: _iconsAnimation.value,
                                child: Transform.scale(
                                  scale: 0.8 + (_iconsAnimation.value * 0.2),
                                  alignment: Alignment.centerRight,
                                  child: child,
                                ),
                              );
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isExpired)
                                  const Padding(
                                    padding: EdgeInsets.only(right: 2),
                                    child: Icon(
                                      Icons.warning,
                                      size: 12,
                                      color: Colors.red,
                                    ),
                                  ),
                                if (isExpiringSoon && !isExpired)
                                  const Padding(
                                    padding: EdgeInsets.only(right: 2),
                                    child: Icon(
                                      Icons.schedule,
                                      size: 12,
                                      color: Colors.orange,
                                    ),
                                  ),
                                if (widget.bankCard.isArchived)
                                  const Padding(
                                    padding: EdgeInsets.only(right: 2),
                                    child: Icon(
                                      Icons.archive,
                                      size: 12,
                                      color: Colors.blueGrey,
                                    ),
                                  ),
                                if (widget.bankCard.usedCount >=
                                    MainConstants.popularItemThreshold)
                                  const Padding(
                                    padding: EdgeInsets.only(right: 2),
                                    child: Icon(
                                      Icons.local_fire_department,
                                      size: 12,
                                      color: Colors.deepOrange,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          // Кнопки действия с анимацией
                          AnimatedBuilder(
                            animation: _iconsAnimation,
                            builder: (context, child) {
                              return Opacity(
                                opacity: _iconsAnimation.value,
                                child: Transform.scale(
                                  scale: 0.8 + (_iconsAnimation.value * 0.2),
                                  alignment: Alignment.centerRight,
                                  child: child,
                                ),
                              );
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    widget.bankCard.isPinned
                                        ? Icons.push_pin
                                        : Icons.push_pin_outlined,
                                    size: 14,
                                    color: widget.bankCard.isPinned
                                        ? Colors.orange
                                        : null,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: widget.onTogglePin,
                                ),
                                IconButton(
                                  icon: Icon(
                                    widget.bankCard.isFavorite
                                        ? Icons.star
                                        : Icons.star_border,
                                    color: widget.bankCard.isFavorite
                                        ? Colors.amber
                                        : null,
                                    size: 14,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: widget.onToggleFavorite,
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    size: 14,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () {
                                    context.push(
                                      AppRoutesPaths.dashboardEntityEdit(
                                        EntityType.bankCard,
                                        widget.bankCard.id,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          IconButton(
                            icon: const Icon(Icons.restore, size: 12),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: widget.onRestore,
                            tooltip: 'Восстановить',
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_forever,
                              size: 12,
                              color: Colors.red,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: widget.onDelete,
                            tooltip: 'Удалить навсегда',
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Тип карты
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getCardTypeColor(
                          widget.bankCard.cardType,
                        ).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _getCardTypeLabel(widget.bankCard.cardType),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: _getCardTypeColor(widget.bankCard.cardType),
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Название
                    Text(
                      widget.bankCard.name,
                      style: theme.textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Маскированный номер
                    Text(
                      maskedNumber,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                        fontFamily: 'monospace',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Срок действия
                    Text(
                      '${widget.bankCard.expiryMonth}/${widget.bankCard.expiryYear.substring(2)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isExpired
                            ? Colors.red
                            : isExpiringSoon
                            ? Colors.orange
                            : Colors.grey.shade600,
                        fontSize: 10,
                        fontWeight: isExpired || isExpiringSoon
                            ? FontWeight.bold
                            : null,
                      ),
                    ),

                    const Spacer(),

                    // Теги
                    if (widget.bankCard.tags != null &&
                        widget.bankCard.tags!.isNotEmpty) ...[
                      SizedBox(
                        height: 20,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: widget.bankCard.tags!.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 4),
                          itemBuilder: (context, index) {
                            final tag = widget.bankCard.tags![index];
                            final tagColor = _parseColor(tag.color);
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: tagColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                tag.name,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: tagColor,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],

                    // Кнопка копирования номера карты
                    SizedBox(
                      width: double.infinity,
                      child: SmoothButton(
                        label: _cardNumberCopied ? 'Скопировано' : 'Копировать',
                        onPressed: _copyCardNumber,
                        type: SmoothButtonType.outlined,
                        variant: SmoothButtonVariant.normal,
                        icon: Icon(
                          _cardNumberCopied ? Icons.check : Icons.copy,
                          size: 14,
                        ),
                        iconPosition: SmoothButtonIconPosition.start,
                        size: SmoothButtonSize.small,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (widget.bankCard.isPinned)
          Positioned(
            top: 6,
            left: 8,
            child: Transform.rotate(
              angle: -0.52,
              child: const Icon(Icons.push_pin, size: 16, color: Colors.orange),
            ),
          ),
        if (widget.bankCard.isFavorite)
          Positioned(
            top: 6,
            left: widget.bankCard.isPinned ? 30 : 8,
            child: Transform.rotate(
              angle: -0.52,
              child: const Icon(Icons.star, size: 14, color: Colors.amber),
            ),
          ),
      ],
    );
  }
}
