import 'package:flutter/material.dart';
import 'package:flutter_credit_card/flutter_credit_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/dashboard/dashboard.dart';
import 'package:hoplixi/features/password_manager/forms/shared/share/share_fields_helpers.dart';
import 'package:hoplixi/features/password_manager/forms/shared/share/shareable_field.dart';
import 'package:hoplixi/features/password_manager/shared/utils/copy_usage_utils.dart';
import 'package:hoplixi/features/password_manager/shared/widgets/custom_fields/widgets/custom_fields_view_section.dart';
import 'package:hoplixi/generated/l10n/translations.g.dart';
import 'package:hoplixi/routing/paths.dart';
import 'package:hoplixi/shared/ui/background_utils.dart';
import 'package:hoplixi/vault_db/core/models/dto/dto.dart';
import 'package:hoplixi/vault_db/core/repositories/vault_repositories.dart';
import 'package:hoplixi/vault_db/providers/repository_providers.dart';
import 'package:hoplixi/vault_db/providers/service_providers.dart';
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
  BankCardViewDto? _bankCard;
  bool _isDeleted = false;
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
      final repositories = await ref.read(vaultRepositories.future);
      final viewResult = await repositories.bankCard.getViewById(
        widget.bankCardId,
      );
      final view = viewResult.getOrNull()?.getOrNull();

      if (view != null && mounted) {
        setState(() {
          _bankCard = view;
          _isDeleted = view.item.isDeleted;
          _isLoading = false;
        });
        await _loadRelatedData(view, repositories);
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadRelatedData(
    BankCardViewDto view,
    VaultRepositories repositories,
  ) async {
    if (view.item.categoryId != null) {
      final cat = (await repositories.category.getCategory(
        view.item.categoryId!,
      )).getOrNull()?.getOrNull();
      if (mounted && cat != null) setState(() => _categoryName = cat.name);
    }

    final relationsService = await ref.read(
      vaultItemRelationsServiceProvider.future,
    );
    final tagIds =
        (await relationsService.getTagIdsForItem(
          widget.bankCardId,
        )).getOrNull() ??
        [];
    if (tagIds.isNotEmpty) {
      final tags =
          (await repositories.tag.getTagsByIds(tagIds)).getOrNull() ?? [];
      if (mounted) setState(() => _tagNames = tags.map((t) => t.name).toList());
    }
  }

  Future<void> _copy(String v, String f) async {
    final copied = await copyCardValue(
      ref: ref,
      itemId: widget.bankCardId,
      text: v,
    );
    if (!copied) return;
    Toaster.success(title: 'Скопировано', description: '$f скопирован');
  }

  void _edit() => context.go(
    AppRoutesPaths.dashboardEntityEdit(EntityType.bankCard, widget.bankCardId),
  );

  Future<void> _share() async {
    final record = _bankCard;
    if (record == null) return;

    final customFields = await loadCustomShareableFields(
      ref,
      widget.bankCardId,
    );
    if (!mounted) return;

    final l10n = context.t.dashboard_forms;
    final fields = [
      ...buildCommonShareFields(
        context,
        name: record.item.name,
        categoryName: _categoryName,
        tagNames: _tagNames,
        description: record.item.description,
      ),
      ...compactShareableFields([
        shareableField(
          id: 'card_number',
          label: l10n.card_number_label,
          value: record.bankCard.cardNumber,
          isSensitive: true,
        ),
        shareableField(
          id: 'cardholder',
          label: l10n.cardholder_name_label,
          value: record.bankCard.cardholderName,
        ),
        shareableField(
          id: 'expiry',
          label: l10n.expiration_date_label,
          value: _getExpiryDate(),
        ),
        shareableField(
          id: 'cvv',
          label: 'CVV',
          value: record.bankCard.cvv,
          isSensitive: true,
        ),
        shareableField(
          id: 'bank',
          label: l10n.bank_name_label,
          value: record.bankCard.bankName,
        ),
      ]),
      ...customFields,
    ];

    await shareEntityFields(
      context: context,
      entity: ShareableEntity(
        title: record.item.name,
        entityTypeLabel: EntityType.bankCard.label,
        fields: fields,
      ),
    );
  }

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
    final month = _bankCard?.bankCard.expiryMonth ?? '';
    final year = _bankCard?.bankCard.expiryYear ?? '';
    if (month.isEmpty && year.isEmpty) return '';
    final shortYear = year.length >= 2 ? year.substring(year.length - 2) : year;
    return '$month/$shortYear';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: getScreenBackgroundColor(context, ref),
      appBar: AppBar(
        title: Text(_bankCard?.item.name ?? 'Карта'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.share2),
            tooltip: context.t.dashboard_forms.share_action,
            onPressed: _isLoading || _isDeleted || _bankCard == null
                ? null
                : _share,
          ),
          IconButton(
            icon: const Icon(LucideIcons.pencil),
            onPressed: _isDeleted ? null : _edit,
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _bankCard == null
            ? const Center(child: Text('Не найдена'))
            : ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _showBackView = !_showBackView),
                    child: CreditCardWidget(
                      cardNumber: _formatCardNumber(
                        _bankCard!.bankCard.cardNumber,
                      ),
                      expiryDate: _getExpiryDate(),
                      cardHolderName: _bankCard!.bankCard.cardholderName!
                          .toUpperCase(),
                      cvvCode: _bankCard?.bankCard.cvv ?? '',
                      showBackView: _showBackView,
                      onCreditCardWidgetChange: (_) {},
                      bankName: _bankCard!.bankCard.bankName,
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
                    _bankCard!.item.name,
                    () => _copy(_bankCard!.item.name, 'Название'),
                  ),
                  _info(
                    theme,
                    LucideIcons.creditCard,
                    'Номер карты',
                    _formatCardNumber(_bankCard!.bankCard.cardNumber),
                    () => _copy(_bankCard!.bankCard.cardNumber, 'Номер'),
                  ),
                  _info(
                    theme,
                    LucideIcons.user,
                    'Владелец',
                    _bankCard!.bankCard.cardholderName ?? '',
                    () => _copy(
                      _bankCard!.bankCard.cardholderName ?? '',
                      'Владелец',
                    ),
                  ),
                  if (_getExpiryDate().isNotEmpty)
                    _info(
                      theme,
                      LucideIcons.calendar,
                      'Срок',
                      _getExpiryDate(),
                      () => _copy(_getExpiryDate(), 'Срок'),
                    ),
                  if (_bankCard!.bankCard.cvv?.isNotEmpty ?? false)
                    _info(
                      theme,
                      LucideIcons.shield,
                      'CVV',
                      '•••',
                      () => _copy(_bankCard!.bankCard.cvv!, 'CVV'),
                    ),
                  if (_bankCard!.bankCard.bankName?.isNotEmpty ?? false)
                    _info(
                      theme,
                      LucideIcons.building,
                      'Банк',
                      _bankCard!.bankCard.bankName!,
                    ),
                  if (_categoryName != null)
                    _info(
                      theme,
                      LucideIcons.folder,
                      'Категория',
                      _categoryName!,
                    ),
                  if (_tagNames.isNotEmpty) _tags(theme),
                  if (_bankCard!.item.description?.isNotEmpty ?? false)
                    _info(
                      theme,
                      LucideIcons.fileText,
                      'Описание',
                      _bankCard!.item.description!,
                    ),
                  CustomFieldsViewSection(itemId: widget.bankCardId),
                  const SizedBox(height: 24),
                ],
              ),
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
