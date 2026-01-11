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

/// Карточка банковской карты для режима сетки
/// Минимальная ширина: 240px для предотвращения чрезмерного сжатия
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
    if (isHovered) {
      _iconsController.forward();
    } else {
      _iconsController.reverse();
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

    final bankCardDao = await ref.read(bankCardDaoProvider.future);
    await bankCardDao.incrementUsage(widget.bankCard.id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bankCard = widget.bankCard;
    final maskedNumber = _maskCardNumber(bankCard.cardNumber);
    final isExpired = _isExpired();
    final isExpiringSoon = _isExpiringSoon();
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
                  padding: EdgeInsets.all(cardPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _getCardTypeColor(
                                bankCard.cardType,
                              ).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.credit_card,
                              size: 20,
                              color: _getCardTypeColor(bankCard.cardType),
                            ),
                          ),

                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              bankCard.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),

                          if (!isMobile) const Spacer(),
                          if (!bankCard.isDeleted)
                            FadeTransition(
                              opacity: _iconsAnimation,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (bankCard.isArchived)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 4),
                                      child: Icon(
                                        Icons.archive,
                                        size: isMobile ? 14 : 16,
                                        color: Colors.blueGrey,
                                      ),
                                    ),
                                  if (bankCard.usedCount >=
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

                      if (bankCard.category != null) ...[
                        CardCategoryBadge(
                          name: bankCard.category!.name,
                          color: bankCard.category!.color,
                        ),
                        SizedBox(height: isMobile ? 3 : 4),
                      ],

                      const SizedBox(height: 4),
                      Text(
                        maskedNumber,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontFamily: 'Courier',
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 4),
                      Text(
                        '${_getCardTypeLabel(bankCard.cardType)} • ${bankCard.expiryMonth}/${bankCard.expiryYear}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isExpired
                              ? Colors.red
                              : isExpiringSoon
                              ? Colors.orange
                              : Colors.grey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      if (isExpired)
                        Text(
                          'Срок истёк',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                      SizedBox(height: isMobile ? 6 : 8),

                      if (bankCard.tags != null &&
                          bankCard.tags!.isNotEmpty) ...[
                        CardTagsList(tags: bankCard.tags!, showTitle: false),
                        SizedBox(height: isMobile ? 4 : 6),
                      ],

                      if (!bankCard.isDeleted) ...[
                        const SizedBox(height: 8),
                        FadeTransition(
                          opacity: _iconsAnimation,
                          child: OutlinedButton.icon(
                            onPressed: _copyCardNumber,
                            icon: Icon(
                              _cardNumberCopied ? Icons.check : Icons.copy,
                              size: 16,
                            ),
                            label: const Text(
                              'Номер карты',
                              style: TextStyle(fontSize: 12),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 8,
                              ),
                              minimumSize: const Size.fromHeight(36),
                            ),
                          ),
                        ),
                        SizedBox(height: isMobile ? 3 : 4),
                        FadeTransition(
                          opacity: _iconsAnimation,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: Icon(
                                  bankCard.isPinned
                                      ? Icons.push_pin
                                      : Icons.push_pin_outlined,
                                  size: 18,
                                  color: bankCard.isPinned
                                      ? Colors.orange
                                      : null,
                                ),
                                onPressed: widget.onTogglePin,
                                tooltip: 'Закрепить',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                              IconButton(
                                icon: Icon(
                                  bankCard.isFavorite
                                      ? Icons.star
                                      : Icons.star_border,
                                  size: 18,
                                  color: bankCard.isFavorite
                                      ? Colors.amber
                                      : null,
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
                                      EntityType.bankCard,
                                      bankCard.id,
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
            isPinned: bankCard.isPinned,
            isFavorite: bankCard.isFavorite,
            isArchived: bankCard.isArchived,
          ).buildPositionedWidgets(),
        ],
      ),
    );
  }
}
