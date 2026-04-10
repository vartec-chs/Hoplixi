import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_zxing/flutter_zxing.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/db_core/main_store.dart';
import 'package:hoplixi/db_core/provider/dao_providers.dart';
import 'package:hoplixi/routing/paths.dart';
import 'package:hoplixi/shared/custom_fields/widgets/custom_fields_view_section.dart';
import 'package:image/image.dart' as imglib;
import 'package:lucide_icons_flutter/lucide_icons.dart';

class LoyaltyCardViewScreen extends ConsumerStatefulWidget {
  const LoyaltyCardViewScreen({super.key, required this.loyaltyCardId});

  final String loyaltyCardId;

  @override
  ConsumerState<LoyaltyCardViewScreen> createState() =>
      _LoyaltyCardViewScreenState();
}

class _LoyaltyCardViewScreenState extends ConsumerState<LoyaltyCardViewScreen> {
  (VaultItemsData, LoyaltyCardItemsData)? _loyaltyCard;
  bool _isLoading = true;
  String? _categoryName;
  List<String> _tagNames = [];
  bool _passwordVisible = false;
  Uint8List? _barcodeImageBytes;
  bool _isGeneratingBarcode = false;

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
        _generateBarcode(record);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadRelatedData(
    (VaultItemsData, LoyaltyCardItemsData) record,
  ) async {
    final vault = record.$1;
    if (vault.categoryId != null) {
      final categoryDao = await ref.read(categoryDaoProvider.future);
      final category = await categoryDao.getCategoryById(vault.categoryId!);
      if (mounted && category != null) {
        setState(() => _categoryName = category.name);
      }
    }

    final vaultItemDao = await ref.read(vaultItemDaoProvider.future);
    final tagIds = await vaultItemDao.getTagIds(widget.loyaltyCardId);
    if (tagIds.isNotEmpty) {
      final tagDao = await ref.read(tagDaoProvider.future);
      final tags = await tagDao.getTagsByIds(tagIds);
      if (mounted) {
        setState(() => _tagNames = tags.map((tag) => tag.name).toList());
      }
    }
  }

  Future<void> _generateBarcode(
    (VaultItemsData, LoyaltyCardItemsData) record,
  ) async {
    final value = record.$2.barcodeValue;
    if (value == null || value.isEmpty) return;
    if (!mounted) return;
    setState(() => _isGeneratingBarcode = true);
    try {
      final format = _zxingFormat(record.$2.barcodeType);
      final isSquare =
          format == Format.qrCode ||
          format == Format.aztec ||
          format == Format.dataMatrix ||
          format == Format.microQRCode;
      const fixedWidth = 512;
      final fixedHeight = isSquare ? 512 : 200;
      final result = zx.encodeBarcode(
        contents: value,
        params: EncodeParams(
          format: format,
          width: fixedWidth,
          height: fixedHeight,
          margin: 16,
          eccLevel: EccLevel.low,
        ),
      );
      if (result.isValid && result.data != null) {
        final img = imglib.Image.fromBytes(
          width: fixedWidth,
          height: fixedHeight,
          bytes: result.data!.buffer,
          numChannels: 1,
        );
        final bytes = Uint8List.fromList(imglib.encodePng(img));
        if (mounted) {
          setState(() {
            _barcodeImageBytes = bytes;
            _isGeneratingBarcode = false;
          });
        }
      } else {
        if (mounted) setState(() => _isGeneratingBarcode = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isGeneratingBarcode = false);
    }
  }

  int _zxingFormat(String? typeName) {
    switch (typeName) {
      case 'QR-код':
        return Format.qrCode;
      case 'Micro QR':
        return Format.microQRCode;
      case 'rMQR':
        return Format.rmqrCode;
      case 'Aztec':
        return Format.aztec;
      case 'Data Matrix':
        return Format.dataMatrix;
      case 'PDF417':
        return Format.pdf417;
      case 'Code 128':
        return Format.code128;
      case 'Code 93':
        return Format.code93;
      case 'Code 39':
        return Format.code39;
      case 'Codabar':
        return Format.codabar;
      case 'EAN-13':
        return Format.ean13;
      case 'EAN-8':
        return Format.ean8;
      case 'UPC-A':
        return Format.upca;
      case 'UPC-E':
        return Format.upce;
      case 'ITF':
        return Format.itf;
      default:
        return Format.qrCode;
    }
  }

  Future<void> _copy(String value, String field) async {
    await Clipboard.setData(ClipboardData(text: value));
    Toaster.success(title: 'Скопировано', description: '$field скопировано');
    final vaultItemDao = await ref.read(vaultItemDaoProvider.future);
    await vaultItemDao.incrementUsage(widget.loyaltyCardId);
  }

  void _edit() => context.go(
    AppRoutesPaths.dashboardEntityEdit(
      EntityType.loyaltyCard,
      widget.loyaltyCardId,
    ),
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
                              Icon(
                                LucideIcons.badgePercent,
                                color: theme.colorScheme.primary,
                              ),
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
                  if (_loyaltyCard!.$2.cardNumber?.isNotEmpty == true)
                    _info(
                      theme,
                      LucideIcons.creditCard,
                      'Номер карты',
                      _loyaltyCard!.$2.cardNumber!,
                      () => _copy(_loyaltyCard!.$2.cardNumber!, 'Номер карты'),
                    ),
                  if (_loyaltyCard!.$2.barcodeValue?.isNotEmpty == true)
                    _barcodeCard(theme),
                  if (_loyaltyCard!.$2.password?.isNotEmpty == true)
                    _passwordInfo(theme),
                  if (_loyaltyCard!.$2.holderName?.isNotEmpty == true)
                    _info(
                      theme,
                      LucideIcons.user,
                      'Владелец',
                      _loyaltyCard!.$2.holderName!,
                    ),
                  if (_loyaltyCard!.$2.tier?.isNotEmpty == true)
                    _info(
                      theme,
                      LucideIcons.crown,
                      'Уровень',
                      _loyaltyCard!.$2.tier!,
                    ),
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
                    _info(
                      theme,
                      LucideIcons.globe,
                      'Сайт',
                      _loyaltyCard!.$2.website!,
                    ),
                  if (_loyaltyCard!.$2.phoneNumber?.isNotEmpty == true)
                    _info(
                      theme,
                      LucideIcons.phone,
                      'Телефон',
                      _loyaltyCard!.$2.phoneNumber!,
                    ),
                  if (_categoryName != null)
                    _info(
                      theme,
                      LucideIcons.folder,
                      'Категория',
                      _categoryName!,
                    ),
                  if (_tagNames.isNotEmpty) _tags(theme),
                  if (_loyaltyCard!.$1.description?.isNotEmpty == true)
                    _info(
                      theme,
                      LucideIcons.fileText,
                      'Описание',
                      _loyaltyCard!.$1.description!,
                    ),
                  CustomFieldsViewSection(itemId: widget.loyaltyCardId),
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

  Widget _barcodeCard(ThemeData theme) {
    final value = _loyaltyCard!.$2.barcodeValue!;
    final typeName = _loyaltyCard!.$2.barcodeType;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  LucideIcons.qrCode,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text('Штрихкод', style: theme.textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 12),
            if (_isGeneratingBarcode)
              const SizedBox(
                height: 80,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_barcodeImageBytes != null)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(8),
                child: Image.memory(_barcodeImageBytes!, fit: BoxFit.contain),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(value, style: theme.textTheme.bodyLarge),
                      if (typeName?.isNotEmpty == true)
                        Text(typeName!, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.copy),
                  tooltip: 'Скопировать',
                  onPressed: () => _copy(value, 'Штрихкод'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _info(
    ThemeData theme,
    IconData icon,
    String label,
    String value, [
    VoidCallback? onCopy,
  ]) {
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

  Widget _passwordInfo(ThemeData theme) {
    final password = _loyaltyCard!.$2.password!;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(
          LucideIcons.lockKeyhole,
          color: theme.colorScheme.primary,
        ),
        title: Text('PIN / Пароль', style: theme.textTheme.bodySmall),
        subtitle: Text(
          _passwordVisible ? password : '••••••••',
          style: theme.textTheme.bodyLarge,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                _passwordVisible ? LucideIcons.eyeOff : LucideIcons.eye,
              ),
              tooltip: _passwordVisible ? 'Скрыть' : 'Показать',
              onPressed: () =>
                  setState(() => _passwordVisible = !_passwordVisible),
            ),
            IconButton(
              icon: const Icon(LucideIcons.copy),
              tooltip: 'Скопировать',
              onPressed: () => _copy(password, 'PIN / Пароль'),
            ),
          ],
        ),
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
