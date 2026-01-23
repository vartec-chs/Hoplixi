import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/cards/shared/index.dart';
import 'package:hoplixi/main_store/models/dto/index.dart';
import 'package:hoplixi/main_store/provider/dao_providers.dart';

/// Карточка банковской карты для режима списка (переписана с shared компонентами)
class BankCardListCard extends ConsumerStatefulWidget {
  final BankCardCardDto bankCard;
  final VoidCallback? onTap;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onTogglePin;
  final VoidCallback? onToggleArchive;
  final VoidCallback? onDelete;
  final VoidCallback? onRestore;
  final VoidCallback? onOpenHistory;

  const BankCardListCard({
    super.key,
    required this.bankCard,
    this.onTap,
    this.onToggleFavorite,
    this.onTogglePin,
    this.onToggleArchive,
    this.onDelete,
    this.onRestore,
    this.onOpenHistory,
  });

  @override
  ConsumerState<BankCardListCard> createState() => _BankCardListCardState();
}

class _BankCardListCardState extends ConsumerState<BankCardListCard>
    with TickerProviderStateMixin {
  bool _isExpanded = false;
  bool _isHovered = false;
  bool _cardNumberCopied = false;
  bool _holderNameCopied = false;
  bool _expiryCopied = false;

  late final AnimationController _expandController;
  late final Animation<double> _expandAnimation;
  late final AnimationController _iconsController;
  late final Animation<double> _iconsAnimation;

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
    _expandController.dispose();
    _iconsController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() => _isExpanded = !_isExpanded);
    if (_isExpanded) {
      _expandController.forward();
      _iconsController.forward();
    } else {
      _expandController.reverse();
      if (!_isHovered) {
        _iconsController.reverse();
      }
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

  /// Маскирует номер карты, показывая только последние 4 цифры
  String _maskCardNumber(String cardNumber) {
    final digitsOnly = cardNumber.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length < 4) return '•••• ••••';
    final lastFour = digitsOnly.substring(digitsOnly.length - 4);
    // return '•••• •••• •••• $lastFour';
    return '$lastFour';
  }

  /// Возвращает цвет для типа карты
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

  /// Возвращает название типа карты на русском
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

  /// Проверяет, истек ли срок карты
  bool _isExpired() {
    final now = DateTime.now();
    final expiryYear = int.tryParse(widget.bankCard.expiryYear) ?? 0;
    final expiryMonth = int.tryParse(widget.bankCard.expiryMonth) ?? 0;

    if (expiryYear < now.year) return true;
    if (expiryYear == now.year && expiryMonth < now.month) return true;
    return false;
  }

  /// Проверяет, истекает ли срок карты скоро (в течение 3 месяцев)
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

  Future<void> _copyHolderName() async {
    await Clipboard.setData(
      ClipboardData(text: widget.bankCard.cardholderName),
    );
    setState(() => _holderNameCopied = true);
    Toaster.success(title: 'Имя держателя скопировано');

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _holderNameCopied = false);
    });

    final bankCardDao = await ref.read(bankCardDaoProvider.future);
    await bankCardDao.incrementUsage(widget.bankCard.id);
  }

  Future<void> _copyExpiry() async {
    final expiry =
        '${widget.bankCard.expiryMonth}/${widget.bankCard.expiryYear}';
    await Clipboard.setData(ClipboardData(text: expiry));
    setState(() => _expiryCopied = true);
    Toaster.success(title: 'Срок действия скопирован');

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _expiryCopied = false);
    });

    final bankCardDao = await ref.read(bankCardDaoProvider.future);
    await bankCardDao.incrementUsage(widget.bankCard.id);
  }

  List<CardActionItem> _buildCopyActions() {
    return [
      CardActionItem(
        label: 'Номер',
        onPressed: _copyCardNumber,
        icon: Icons.credit_card,
        successIcon: Icons.check,
        isSuccess: _cardNumberCopied,
      ),
      CardActionItem(
        label: 'Держатель',
        onPressed: _copyHolderName,
        icon: Icons.person,
        successIcon: Icons.check,
        isSuccess: _holderNameCopied,
      ),
      CardActionItem(
        label: 'Срок',
        onPressed: _copyExpiry,
        icon: Icons.calendar_today,
        successIcon: Icons.check,
        isSuccess: _expiryCopied,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bankCard = widget.bankCard;
    final maskedNumber = _maskCardNumber(bankCard.cardNumber);
    final isExpired = _isExpired();
    final isExpiringSoon = _isExpiringSoon();

    return Stack(
      children: [
        Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.hardEdge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isExpired
                ? const BorderSide(color: Colors.red, width: 1.5)
                : isExpiringSoon
                ? const BorderSide(color: Colors.orange, width: 1.5)
                : BorderSide.none,
          ),

          child: Column(
            children: [
              // Основная часть карточки
              _buildHeader(theme, maskedNumber, isExpired, isExpiringSoon),
              // Развернутый контент
              _buildExpandedContent(theme),
            ],
          ),
        ),
        // Индикаторы статуса
        ...CardStatusIndicators(
          isPinned: bankCard.isPinned,
          isFavorite: bankCard.isFavorite,
          isArchived: bankCard.isArchived,
        ).buildPositionedWidgets(),
      ],
    );
  }

  Widget _buildHeader(
    ThemeData theme,
    String maskedNumber,
    bool isExpired,
    bool isExpiringSoon,
  ) {
    final bankCard = widget.bankCard;
    final cardTypeColor = _getCardTypeColor(bankCard.cardType);

    return MouseRegion(
      onEnter: (_) => _onHoverChanged(true),
      onExit: (_) => _onHoverChanged(false),
      child: InkWell(
        onTap: _toggleExpanded,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              // Иконка карты
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: cardTypeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.credit_card, color: cardTypeColor),
              ),
              const SizedBox(width: 6),
              // Основная информация
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Категория и тип карты
                    Row(
                      children: [
                        if (bankCard.category != null) ...[
                          CardCategoryBadge(
                            name: bankCard.category!.name,
                            color: bankCard.category!.color,
                          ),
                          const SizedBox(width: 4),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: cardTypeColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _getCardTypeLabel(bankCard.cardType),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cardTypeColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Название
                    Text(
                      bankCard.name,
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    // Маскированный номер и срок
                    Row(
                      children: [
                        Text(
                          maskedNumber,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${bankCard.expiryMonth}/${bankCard.expiryYear.substring(2)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isExpired
                                ? Colors.red
                                : isExpiringSoon
                                ? Colors.orange
                                : Colors.grey,
                            fontWeight: isExpired || isExpiringSoon
                                ? FontWeight.bold
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Действия
              _buildHeaderActions(theme, isExpired, isExpiringSoon),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderActions(
    ThemeData theme,
    bool isExpired,
    bool isExpiringSoon,
  ) {
    final bankCard = widget.bankCard;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!bankCard.isDeleted) ...[
          AnimatedBuilder(
            animation: _iconsAnimation,
            builder: (context, child) {
              return Opacity(opacity: _iconsAnimation.value, child: child);
            },
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    bankCard.isFavorite ? Icons.star : Icons.star_border,
                    color: bankCard.isFavorite ? Colors.amber : null,
                  ),
                  onPressed: widget.onToggleFavorite,
                  tooltip: bankCard.isFavorite
                      ? 'Убрать из избранного'
                      : 'В избранное',
                ),
              ],
            ),
          ),
          AnimatedBuilder(
            animation: _iconsAnimation,
            builder: (context, child) {
              return SizeTransition(
                sizeFactor: _iconsAnimation,
                axis: Axis.horizontal,
                child: child,
              );
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    bankCard.isPinned
                        ? Icons.push_pin
                        : Icons.push_pin_outlined,
                    color: bankCard.isPinned ? Colors.orange : null,
                  ),
                  onPressed: widget.onTogglePin,
                  tooltip: bankCard.isPinned ? 'Открепить' : 'Закрепить',
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
    final bankCard = widget.bankCard;

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

            // Держатель карты
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 8),
                Text(
                  bankCard.cardholderName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Банк
            if (bankCard.bankName != null && bankCard.bankName!.isNotEmpty) ...[
              Row(
                children: [
                  Icon(
                    Icons.account_balance,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 8),
                  Text(bankCard.bankName!, style: theme.textTheme.bodyMedium),
                ],
              ),
              const SizedBox(height: 8),
            ],

            // Платёжная система
            if (bankCard.cardNetwork != null) ...[
              Row(
                children: [
                  Icon(
                    Icons.credit_card,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    bankCard.cardNetwork!.toUpperCase(),
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // Кнопки копирования (горизонтальный скролл)
            HorizontalScrollableActions(actions: _buildCopyActions()),

            // Теги
            if (bankCard.tags != null && bankCard.tags!.isNotEmpty) ...[
              const SizedBox(height: 12),
              CardTagsList(tags: bankCard.tags),
            ],

            // Метаинформация
            const SizedBox(height: 12),
            CardMetaInfo(
              usedCount: bankCard.usedCount,
              modifiedAt: bankCard.modifiedAt,
              usedLabel: 'Использована',
              modifiedLabel: 'Изменена',
            ),

            // Кнопки удаления/восстановления/архивации
            const SizedBox(height: 12),
            CardActionButtons(
              isDeleted: bankCard.isDeleted,
              isArchived: bankCard.isArchived,
              onRestore: widget.onRestore,
              onDelete: widget.onDelete,
              onToggleArchive: widget.onToggleArchive,
            ),
          ],
        ),
      ),
    );
  }
}
