import 'package:hoplixi/shared/ui/background_utils.dart';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_zxing/flutter_zxing.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/dashboard/dashboard.dart';
import 'package:hoplixi/features/password_manager/forms/shared/share/share_fields_helpers.dart';
import 'package:hoplixi/features/password_manager/forms/shared/share/shareable_field.dart';
import 'package:hoplixi/features/password_manager/shared/utils/copy_usage_utils.dart';
import 'package:hoplixi/features/password_manager/shared/widgets/custom_fields/widgets/custom_fields_view_section.dart';
import 'package:hoplixi/generated/l10n/translations.g.dart';
import 'package:hoplixi/vault_db/core/models/dto/dto.dart';
import 'package:hoplixi/vault_db/core/repositories/vault_repositories.dart';
import 'package:hoplixi/vault_db/core/scheme/tables/tables.dart';
import 'package:hoplixi/vault_db/providers/repository_providers.dart';
import 'package:hoplixi/vault_db/providers/service_providers.dart';
import 'package:hoplixi/routing/paths.dart';
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
  LoyaltyCardViewDto? _loyaltyCard;
  bool _isLoading = true;
  bool _isDeleted = false;
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
      final repositories = await ref.read(vaultRepositories.future);
      final viewResult = await repositories.loyaltyCard.getViewById(
        widget.loyaltyCardId,
      );
      final view = viewResult.getOrNull()?.getOrNull();
      if (!mounted) return;
      setState(() {
        _loyaltyCard = view;
        _isDeleted = view?.item.isDeleted ?? false;
        _isLoading = false;
      });

      if (view != null) {
        await _loadRelatedData(view, repositories);
        _generateBarcode(view);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadRelatedData(
    LoyaltyCardViewDto view,
    VaultRepositories repositories,
  ) async {
    if (view.item.categoryId != null) {
      final cat = (await repositories.category.getCategory(
        view.item.categoryId!,
      )).getOrNull()?.getOrNull();
      if (mounted && cat != null) {
        setState(() => _categoryName = cat.name);
      }
    }

    final relationsService = await ref.read(
      vaultItemRelationsServiceProvider.future,
    );
    final tagIds =
        (await relationsService.getTagIdsForItem(
          widget.loyaltyCardId,
        )).getOrNull() ??
        [];
    if (tagIds.isNotEmpty) {
      final tags =
          (await repositories.tag.getTagsByIds(tagIds)).getOrNull() ?? [];
      if (mounted) {
        setState(() => _tagNames = tags.map((t) => t.name).toList());
      }
    }
  }

  Future<void> _generateBarcode(LoyaltyCardViewDto view) async {
    final value = view.loyaltyCard.barcodeValue;
    if (value == null || value.isEmpty) return;
    if (!mounted) return;
    setState(() => _isGeneratingBarcode = true);
    try {
      final format = _zxingFormat(view.loyaltyCard.barcodeType);
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

  int _zxingFormat(LoyaltyBarcodeType? type) {
    if (type == null) return Format.qrCode;
    switch (type) {
      case LoyaltyBarcodeType.qr:
        return Format.qrCode;
      case LoyaltyBarcodeType.aztec:
        return Format.aztec;
      case LoyaltyBarcodeType.dataMatrix:
        return Format.dataMatrix;
      case LoyaltyBarcodeType.pdf417:
        return Format.pdf417;
      case LoyaltyBarcodeType.code128:
        return Format.code128;
      case LoyaltyBarcodeType.code39:
        return Format.code39;
      case LoyaltyBarcodeType.ean13:
        return Format.ean13;
      case LoyaltyBarcodeType.ean8:
        return Format.ean8;
      case LoyaltyBarcodeType.upcA:
        return Format.upca;
      case LoyaltyBarcodeType.upcE:
        return Format.upce;
      default:
        return Format.qrCode;
    }
  }

  Future<void> _copy(String value, String field) async {
    final copied = await copyCardValue(
      ref: ref,
      itemId: widget.loyaltyCardId,
      text: value,
    );
    if (!copied) return;
    Toaster.success(title: 'Скопировано', description: '$field скопировано');
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

  Future<void> _share() async {
    final record = _loyaltyCard;
    if (record == null) return;

    final l10n = context.t.dashboard_forms;
    final customFields = await loadCustomShareableFields(
      ref,
      widget.loyaltyCardId,
    );
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
          id: 'program',
          label: l10n.program_name_label,
          value: record.loyaltyCard.programName,
        ),
        shareableField(
          id: 'card_number',
          label: l10n.loyalty_card_number_label,
          value: record.loyaltyCard.cardNumber,
          isSensitive: true,
        ),
        shareableField(
          id: 'barcode',
          label: l10n.barcode_value_label,
          value: record.loyaltyCard.barcodeValue,
          isSensitive: true,
        ),
        shareableField(
          id: 'password',
          label: l10n.pin_password_label,
          value: record.loyaltyCard.password,
          isSensitive: true,
        ),
        shareableField(
          id: 'issuer',
          label: 'Издатель / Эмитент',
          value: record.loyaltyCard.issuer,
        ),
        shareableField(
          id: 'valid_from',
          label: 'Действует с',
          value: record.loyaltyCard.validFrom == null
              ? null
              : _formatDate(record.loyaltyCard.validFrom),
        ),
        shareableField(
          id: 'valid_to',
          label: 'Действует по',
          value: record.loyaltyCard.validTo == null
              ? null
              : _formatDate(record.loyaltyCard.validTo),
        ),
        shareableField(
          id: 'website',
          label: l10n.website_label,
          value: record.loyaltyCard.website,
        ),
        shareableField(
          id: 'phone',
          label: l10n.phone_label,
          value: record.loyaltyCard.phone,
        ),
        shareableField(
          id: 'email',
          label: 'Email',
          value: record.loyaltyCard.email,
        ),
      ]),
      ...customFields,
    ];

    if (!mounted) return;

    await shareEntityFields(
      context: context,
      entity: ShareableEntity(
        title: record.item.name,
        entityTypeLabel: EntityType.loyaltyCard.label,
        fields: fields,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: getScreenBackgroundColor(context, ref),
      appBar: AppBar(
        title: Text(_loyaltyCard?.item.name ?? 'Карта лояльности'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.share2),
            tooltip: context.t.dashboard_forms.share_action,
            onPressed: _isLoading || _isDeleted || _loyaltyCard == null
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
                                  _loyaltyCard!.loyaltyCard.programName,
                                  style: theme.textTheme.titleLarge,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _loyaltyCard!.item.name,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_loyaltyCard!.loyaltyCard.cardNumber?.isNotEmpty == true)
                    _info(
                      theme,
                      LucideIcons.creditCard,
                      'Номер карты',
                      _loyaltyCard!.loyaltyCard.cardNumber!,
                      () => _copy(
                        _loyaltyCard!.loyaltyCard.cardNumber!,
                        'Номер карты',
                      ),
                    ),
                  if (_loyaltyCard!.loyaltyCard.barcodeValue?.isNotEmpty ==
                      true)
                    _barcodeCard(theme),
                  if (_loyaltyCard!.loyaltyCard.password?.isNotEmpty == true)
                    _passwordInfo(theme),
                  if (_loyaltyCard!.loyaltyCard.issuer?.isNotEmpty == true)
                    _info(
                      theme,
                      LucideIcons.tag,
                      'Эмитент / Издатель',
                      _loyaltyCard!.loyaltyCard.issuer!,
                    ),
                  if (_loyaltyCard!.loyaltyCard.validFrom != null)
                    _info(
                      theme,
                      LucideIcons.calendar,
                      'Действует с',
                      _formatDate(_loyaltyCard!.loyaltyCard.validFrom),
                    ),
                  if (_loyaltyCard!.loyaltyCard.validTo != null)
                    _info(
                      theme,
                      LucideIcons.calendar,
                      'Действует по / Истекает',
                      _formatDate(_loyaltyCard!.loyaltyCard.validTo),
                    ),
                  if (_loyaltyCard!.loyaltyCard.website?.isNotEmpty == true)
                    _info(
                      theme,
                      LucideIcons.globe,
                      'Сайт',
                      _loyaltyCard!.loyaltyCard.website!,
                    ),
                  if (_loyaltyCard!.loyaltyCard.phone?.isNotEmpty == true)
                    _info(
                      theme,
                      LucideIcons.phone,
                      'Телефон',
                      _loyaltyCard!.loyaltyCard.phone!,
                    ),
                  if (_loyaltyCard!.loyaltyCard.email?.isNotEmpty == true)
                    _info(
                      theme,
                      LucideIcons.mail,
                      'Email',
                      _loyaltyCard!.loyaltyCard.email!,
                    ),
                  if (_categoryName != null)
                    _info(
                      theme,
                      LucideIcons.folder,
                      'Категория',
                      _categoryName!,
                    ),
                  if (_tagNames.isNotEmpty) _tags(theme),
                  if (_loyaltyCard!.item.description?.isNotEmpty == true)
                    _info(
                      theme,
                      LucideIcons.fileText,
                      'Описание',
                      _loyaltyCard!.item.description!,
                    ),
                  CustomFieldsViewSection(itemId: widget.loyaltyCardId),
                  const SizedBox(height: 24),
                ],
              ),
      ),
    );
  }

  Widget _barcodeCard(ThemeData theme) {
    final value = _loyaltyCard!.loyaltyCard.barcodeValue!;
    final barcodeType = _loyaltyCard!.loyaltyCard.barcodeType;
    final typeName = barcodeType == LoyaltyBarcodeType.other
        ? _loyaltyCard!.loyaltyCard.barcodeTypeOther
        : barcodeType?.name;
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
                      if (typeName != null && typeName.isNotEmpty)
                        Text(typeName, style: theme.textTheme.bodySmall),
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
    final password = _loyaltyCard!.loyaltyCard.password!;
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
