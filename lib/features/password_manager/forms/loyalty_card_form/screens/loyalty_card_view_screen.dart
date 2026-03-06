import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/provider/dao_providers.dart';
import 'package:hoplixi/routing/paths.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class LoyaltyCardViewScreen extends ConsumerStatefulWidget {
  const LoyaltyCardViewScreen({super.key, required this.loyaltyCardId});

  final String loyaltyCardId;

  @override
  ConsumerState<LoyaltyCardViewScreen> createState() => _LoyaltyCardViewScreenState();
}

class _LoyaltyCardViewScreenState extends ConsumerState<LoyaltyCardViewScreen> {
  (VaultItemsData, LoyaltyCardItemsData)? _loyaltyCard;
  bool _isLoading = true;
  String? _categoryName;
  List<String> _tagNames = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final dao = await ref.read(loyaltyCardDaoProvider.future);
      final record = await dao.getById(widget.loyaltyCardId);
      if (!mounted) return;
      setState(() {
        _loyaltyCard = record;
        _isLoading = false;
      });

      if (record != null) {
        await _loadRelatedData(record);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadRelatedData((VaultItemsData, LoyaltyCardItemsData) record) async {
    final vault = record.$1;
    if (vault.categoryId != null) {
      final categoryDao = await ref.read(categoryDaoProvider.future);
      final category = await categoryDao.getCategoryById(vault.categoryId!);
      if (mounted && category != null) setState(() => _categoryName = category.name);
    }

    final vaultItemDao = await ref.read(vaultItemDaoProvider.future);
    final tagIds = await vaultItemDao.getTagIds(widget.loyaltyCardId);
    if (tagIds.isNotEmpty) {
      final tagDao = await ref.read(tagDaoProvider.future);
      final tags = await tagDao.getTagsByIds(tagIds);
      if (mounted) setState(() => _tagNames = tags.map((tag) => tag.name).toList());
    }
  }

  Future<void> _copy(String value, String field) async {
    await Clipboard.setData(ClipboardData(text: value));
    Toaster.success(title: 'Скопировано', description: '$field скопировано');
    final vaultItemDao = await ref.read(vaultItemDaoProvider.future);
    await vaultItemDao.incrementUsage(widget.loyaltyCardId);
  }

  void _edit() => context.go(
        AppRoutesPaths.dashboardEntityEdit(EntityType.loyaltyCard, widget.loyaltyCardId),
      );

  String _formatDate(DateTime? value) {
    if (value == null) return '-';
    return '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}.${value.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_loyaltyCard?.$1.name ?? 'Карта лояльности'),
        actions: [
          IconButton(icon: const Icon(LucideIcons.pencil), onPressed: _edit),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _loyaltyCard == null
            ? const Center(child: Text('Не найдено'))
            : ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(LucideIcons.badgePercent, color: theme.colorScheme.primary),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _loyaltyCard!.$2.programName,
                                  style: theme.textTheme.titleLarge,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _loyaltyCard!.$1.name,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _info(
                    theme,
                    LucideIcons.creditCard,
                    'Номер карты',
                    _loyaltyCard!.$2.cardNumber,
                    () => _copy(_loyaltyCard!.$2.cardNumber, 'Номер карты'),
                  ),
                  if (_loyaltyCard!.$2.barcodeValue?.isNotEmpty == true)
                    _info(
                      theme,
                      LucideIcons.qrCode,
                      'Штрихкод',
                      _loyaltyCard!.$2.barcodeValue!,
                      () => _copy(_loyaltyCard!.$2.barcodeValue!, 'Штрихкод'),
                    ),
                  if (_loyaltyCard!.$2.holderName?.isNotEmpty == true)
                    _info(theme, LucideIcons.user, 'Владелец', _loyaltyCard!.$2.holderName!),
                  if (_loyaltyCard!.$2.tier?.isNotEmpty == true)
                    _info(theme, LucideIcons.crown, 'Уровень', _loyaltyCard!.$2.tier!),
                  if (_loyaltyCard!.$2.pointsBalance?.isNotEmpty == true)
                    _info(
                      theme,
                      LucideIcons.star,
                      'Баланс/бонусы',
                      _loyaltyCard!.$2.pointsBalance!,
                    ),
                  if (_loyaltyCard!.$2.expiryDate != null)
                    _info(
                      theme,
                      LucideIcons.calendar,
                      'Срок действия',
                      _formatDate(_loyaltyCard!.$2.expiryDate),
                    ),
                  if (_loyaltyCard!.$2.website?.isNotEmpty == true)
                    _info(theme, LucideIcons.globe, 'Сайт', _loyaltyCard!.$2.website!),
                  if (_loyaltyCard!.$2.phoneNumber?.isNotEmpty == true)
                    _info(theme, LucideIcons.phone, 'Телефон', _loyaltyCard!.$2.phoneNumber!),
                  if (_categoryName != null)
                    _info(theme, LucideIcons.folder, 'Категория', _categoryName!),
                  if (_tagNames.isNotEmpty) _tags(theme),
                  if (_loyaltyCard!.$1.description?.isNotEmpty == true)
                    _info(theme, LucideIcons.fileText, 'Описание', _loyaltyCard!.$1.description!),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _edit,
                    icon: const Icon(LucideIcons.pencil),
                    label: const Text('Редактировать'),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _info(ThemeData theme, IconData icon, String label, String value, [VoidCallback? onCopy]) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: theme.colorScheme.primary),
        title: Text(label, style: theme.textTheme.bodySmall),
        subtitle: Text(value, style: theme.textTheme.bodyLarge),
        trailing: onCopy != null
            ? IconButton(icon: const Icon(LucideIcons.copy), onPressed: onCopy)
            : null,
      ),
    );
  }

  Widget _tags(ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.tags, color: theme.colorScheme.primary),
                const SizedBox(width: 16),
                Text('Теги', style: theme.textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _tagNames.map((tag) => Chip(label: Text(tag))).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
