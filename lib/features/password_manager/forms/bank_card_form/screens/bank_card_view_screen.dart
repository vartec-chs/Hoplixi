import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_credit_card/flutter_credit_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/provider/dao_providers.dart';
import 'package:hoplixi/routing/paths.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Экран просмотра банковской карты (только чтение)
class BankCardViewScreen extends ConsumerStatefulWidget {
  const BankCardViewScreen({super.key, required this.bankCardId});

  final String bankCardId;

  @override
  ConsumerState<BankCardViewScreen> createState() => _BankCardViewScreenState();
}

class _BankCardViewScreenState extends ConsumerState<BankCardViewScreen> {
  bool _showBackView = false;
  (VaultItemsData, BankCardItemsData)? _bankCard;
  bool _isLoading = true;
  String? _categoryName;
  List<String> _tagNames = [];

  @override
  void initState() {
    super.initState();
    _loadBankCard();
  }

  Future<void> _loadBankCard() async {
    try {
      final dao = await ref.read(bankCardDaoProvider.future);
      final record = await dao.getById(widget.bankCardId);

      if (record != null && mounted) {
        setState(() {
          _bankCard = record;
          _isLoading = false;
        });
        await _loadRelatedData(record);
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadRelatedData(
    (VaultItemsData, BankCardItemsData) record,
  ) async {
    final vault = record.$1;
    if (vault.categoryId != null) {
      final catDao = await ref.read(categoryDaoProvider.future);
      final cat = await catDao.getCategoryById(vault.categoryId!);
      if (mounted && cat != null) setState(() => _categoryName = cat.name);
    }

    final vaultItemDao = await ref.read(vaultItemDaoProvider.future);
    final tagIds = await vaultItemDao.getTagIds(widget.bankCardId);
    if (tagIds.isNotEmpty) {
      final tagDao = await ref.read(tagDaoProvider.future);
      final tags = await tagDao.getTagsByIds(tagIds);
      if (mounted) setState(() => _tagNames = tags.map((t) => t.name).toList());
    }
  }

  Future<void> _copy(String v, String f) async {
    Clipboard.setData(ClipboardData(text: v));
    Toaster.success(title: 'Скопировано', description: '$f скопирован');
    final vaultItemDao = await ref.read(vaultItemDaoProvider.future);
    await vaultItemDao.incrementUsage(widget.bankCardId);
  }

  void _edit() => context.go(
    AppRoutesPaths.dashboardEntityEdit(EntityType.bankCard, widget.bankCardId),
  );

  String _formatCardNumber(String number) {
    final clean = number.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (int i = 0; i < clean.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(clean[i]);
    }
    return buffer.toString();
  }

  String _getExpiryDate() {
    final month = _bankCard?.$2.expiryMonth ?? '';
    final year = _bankCard?.$2.expiryYear ?? '';
    if (month.isEmpty && year.isEmpty) return '';
    final shortYear = year.length >= 2 ? year.substring(year.length - 2) : year;
    return '$month/$shortYear';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_bankCard?.$1.name ?? 'Карта'),
        actions: [
          IconButton(icon: const Icon(LucideIcons.pencil), onPressed: _edit),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _bankCard == null
          ? const Center(child: Text('Не найдена'))
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                GestureDetector(
                  onTap: () => setState(() => _showBackView = !_showBackView),
                  child: CreditCardWidget(
                    cardNumber: _formatCardNumber(_bankCard!.$2.cardNumber),
                    expiryDate: _getExpiryDate(),
                    cardHolderName: _bankCard!.$2.cardholderName.toUpperCase(),
                    cvvCode: _bankCard?.$2.cvv ?? '',
                    showBackView: _showBackView,
                    onCreditCardWidgetChange: (_) {},
                    bankName: _bankCard!.$2.bankName,
                    cardBgColor: cs.primary,
                    obscureCardNumber: false,
                    obscureCardCvv: true,
                    isHolderNameVisible: true,
                    height: 200,
                    width: MediaQuery.of(context).size.width,
                    isChipVisible: true,
                    isSwipeGestureEnabled: true,
                    animationDuration: const Duration(milliseconds: 500),
                    padding: 8,
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Нажмите для переворота',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _info(
                  theme,
                  LucideIcons.tag,
                  'Название',
                  _bankCard!.$1.name,
                  () => _copy(_bankCard!.$1.name, 'Название'),
                ),
                _info(
                  theme,
                  LucideIcons.creditCard,
                  'Номер карты',
                  _formatCardNumber(_bankCard!.$2.cardNumber),
                  () => _copy(_bankCard!.$2.cardNumber, 'Номер'),
                ),
                _info(
                  theme,
                  LucideIcons.user,
                  'Владелец',
                  _bankCard!.$2.cardholderName,
                  () => _copy(_bankCard!.$2.cardholderName, 'Владелец'),
                ),
                if (_getExpiryDate().isNotEmpty)
                  _info(
                    theme,
                    LucideIcons.calendar,
                    'Срок',
                    _getExpiryDate(),
                    () => _copy(_getExpiryDate(), 'Срок'),
                  ),
                if (_bankCard!.$2.cvv?.isNotEmpty ?? false)
                  _info(
                    theme,
                    LucideIcons.shield,
                    'CVV',
                    '•••',
                    () => _copy(_bankCard!.$2.cvv!, 'CVV'),
                  ),
                if (_bankCard!.$2.bankName?.isNotEmpty ?? false)
                  _info(
                    theme,
                    LucideIcons.building,
                    'Банк',
                    _bankCard!.$2.bankName!,
                  ),
                if (_categoryName != null)
                  _info(theme, LucideIcons.folder, 'Категория', _categoryName!),
                if (_tagNames.isNotEmpty) _tags(theme),
                if (_bankCard!.$1.description?.isNotEmpty ?? false)
                  _info(
                    theme,
                    LucideIcons.fileText,
                    'Описание',
                    _bankCard!.$1.description!,
                  ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _edit,
                  icon: const Icon(LucideIcons.pencil),
                  label: const Text('Редактировать'),
                ),
              ],
            ),
    );
  }

  Widget _info(ThemeData t, IconData i, String l, String v, [VoidCallback? c]) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(i, color: t.colorScheme.primary),
        title: Text(l, style: t.textTheme.bodySmall),
        subtitle: Text(v, style: t.textTheme.bodyLarge),
        trailing: c != null
            ? IconButton(icon: const Icon(LucideIcons.copy), onPressed: c)
            : null,
      ),
    );
  }

  Widget _tags(ThemeData t) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.tags, color: t.colorScheme.primary),
                const SizedBox(width: 16),
                Text('Теги', style: t.textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _tagNames.map((e) => Chip(label: Text(e))).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
