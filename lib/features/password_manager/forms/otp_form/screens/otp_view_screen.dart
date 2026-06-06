import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/utils/smart_converter_base.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/dashboard/dashboard.dart';
import 'package:hoplixi/features/password_manager/forms/shared/share/share_fields_helpers.dart';
import 'package:hoplixi/features/password_manager/forms/shared/share/shareable_field.dart';
import 'package:hoplixi/features/password_manager/shared/utils/copy_usage_utils.dart';
import 'package:hoplixi/features/password_manager/shared/widgets/custom_fields/widgets/custom_fields_view_section.dart';
import 'package:hoplixi/generated/l10n/translations.g.dart';
import 'package:hoplixi/routing/paths.dart';
import 'package:hoplixi/shared/ui/background_utils.dart';
import 'package:hoplixi/vault_db/core/models/dto/otp_dto.dart';
import 'package:hoplixi/vault_db/core/repositories/vault_repositories.dart';
import 'package:hoplixi/vault_db/core/scheme/tables/otp/otp_items.dart';
import 'package:hoplixi/vault_db/providers/providers.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:otp/otp.dart';

/// Экран просмотра OTP (только чтение, с генерацией кода)
class OtpViewScreen extends ConsumerStatefulWidget {
  const OtpViewScreen({super.key, required this.otpId});

  final String otpId;

  @override
  ConsumerState<OtpViewScreen> createState() => _OtpViewScreenState();
}

class _OtpViewScreenState extends ConsumerState<OtpViewScreen> {
  OtpViewDto? _otp;
  bool _isDeleted = false;
  bool _isLoading = true;
  String? _categoryName;
  List<String> _tagNames = [];
  String _currentCode = '';
  int _remainingSeconds = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadOtp();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadOtp() async {
    try {
      final repositories = await ref.read(vaultRepositories.future);
      final viewResult = await repositories.otp.getViewById(widget.otpId);
      final view = viewResult.getOrNull()?.getOrNull();
      if (view != null && mounted) {
        setState(() {
          _otp = view;
          _isDeleted = view.item.isDeleted;
          _isLoading = false;
        });
        _startCodeGeneration();
        await _loadRelatedData(view, repositories);
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadRelatedData(
    OtpViewDto view,
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
        (await relationsService.getTagIdsForItem(widget.otpId)).getOrNull() ??
        [];
    if (tagIds.isNotEmpty) {
      final tags =
          (await repositories.tag.getTagsByIds(tagIds)).getOrNull() ?? [];
      if (mounted) setState(() => _tagNames = tags.map((t) => t.name).toList());
    }
  }

  void _startCodeGeneration() {
    _generateCode();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _generateCode());
  }

  void _generateCode() {
    if (_otp == null) return;

    final secretBytes = _otp!.otp.secret;
    if (secretBytes.isEmpty) return;

    // Decode secret based on encoding
    String secretString;
    try {
      secretString =
          SmartConverter().toBase32(
            String.fromCharCodes(secretBytes),
          )['base32'] ??
          '';
    } catch (_) {
      return;
    }

    final period = _otp!.otp.period ?? 30;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final remaining = period - (now % period);

    final code = OTP.generateTOTPCodeString(
      secretString,
      DateTime.now().millisecondsSinceEpoch,
      length: _otp!.otp.digits,
      interval: period,
      algorithm: _getAlgorithm(_otp!.otp.algorithm),
    );

    if (mounted) {
      setState(() {
        _currentCode = code;
        _remainingSeconds = remaining;
      });
    }
  }

  Algorithm _getAlgorithm(OtpHashAlgorithm algo) {
    switch (algo) {
      case OtpHashAlgorithm.SHA256:
        return Algorithm.SHA256;
      case OtpHashAlgorithm.SHA512:
        return Algorithm.SHA512;
      case OtpHashAlgorithm.SHA1:
        return Algorithm.SHA1;
    }
  }

  Future<void> _copyCode() async {
    final copied = await copyCardValue(
      ref: ref,
      itemId: widget.otpId,
      text: _currentCode,
    );
    if (!copied) return;
    Toaster.success(title: 'Скопировано', description: 'OTP код скопирован');
  }

  void _edit() => context.go(
    AppRoutesPaths.dashboardEntityEdit(EntityType.otp, widget.otpId),
  );

  Future<void> _share() async {
    final record = _otp;
    if (record == null) return;

    final l10n = context.t.dashboard_forms;
    String? secret;
    try {
      secret = SmartConverter().toBase32(
        String.fromCharCodes(record.otp.secret),
      )['base32'];
    } catch (_) {
      secret = null;
    }

    final commonFields = buildCommonShareFields(
      context,
      name: record.item.name,
      categoryName: _categoryName,
      tagNames: _tagNames,
      description: record.item.description,
    );
    final customFields = await loadCustomShareableFields(ref, widget.otpId);
    if (!mounted) return;
    final fields = [
      ...commonFields,
      ...compactShareableFields([
        shareableField(
          id: 'current_code',
          label: l10n.share_current_code_label,
          value: _currentCode,
          isSensitive: true,
        ),
        shareableField(
          id: 'secret',
          label: l10n.otp_secret_key_label,
          value: secret,
          isSensitive: true,
        ),
        shareableField(
          id: 'issuer',
          label: l10n.otp_issuer_label,
          value: record.otp.issuer,
        ),
        shareableField(
          id: 'account',
          label: l10n.otp_account_name_label,
          value: record.otp.accountName,
        ),
        shareableField(
          id: 'period',
          label: l10n.period_seconds_label,
          value: record.otp.period,
        ),
        shareableField(
          id: 'digits',
          label: l10n.digits_count_label,
          value: record.otp.digits,
        ),
        shareableField(
          id: 'algorithm',
          label: l10n.algorithm_label,
          value: record.otp.algorithm.name,
        ),
      ]),
      ...customFields,
    ];

    await shareEntityFields(
      context: context,
      entity: ShareableEntity(
        title: record.item.name,
        entityTypeLabel: EntityType.otp.label,
        fields: fields,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: getScreenBackgroundColor(context, ref),
      appBar: AppBar(
        title: Text(_otp?.item.name ?? 'OTP'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.share2),
            tooltip: context.t.dashboard_forms.share_action,
            onPressed: _isLoading || _isDeleted || _otp == null ? null : _share,
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
            : _otp == null
            ? const Center(child: Text('Не найден'))
            : ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  Card(
                    child: InkWell(
                      onTap: _copyCode,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Text(
                              _currentCode,
                              style: theme.textTheme.displayMedium?.copyWith(
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.bold,
                                letterSpacing: 8,
                                color: cs.primary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    value:
                                        _remainingSeconds /
                                        (_otp!.otp.period ?? 30),
                                    strokeWidth: 3,
                                    color: _remainingSeconds <= 5
                                        ? cs.error
                                        : cs.primary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text('$_remainingSeconds сек'),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Нажмите для копирования',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _info(
                    theme,
                    LucideIcons.building,
                    'Издатель',
                    _otp!.otp.issuer ?? '-',
                  ),
                  _info(
                    theme,
                    LucideIcons.user,
                    'Аккаунт',
                    _otp!.otp.accountName ?? '-',
                  ),
                  _info(
                    theme,
                    LucideIcons.timer,
                    'Период',
                    '${_otp!.otp.period} сек',
                  ),
                  _info(theme, LucideIcons.hash, 'Цифр', '${_otp!.otp.digits}'),
                  _info(
                    theme,
                    LucideIcons.cpu,
                    'Алгоритм',
                    _otp!.otp.algorithm.name,
                  ),
                  if (_categoryName != null)
                    _info(
                      theme,
                      LucideIcons.folder,
                      'Категория',
                      _categoryName!,
                    ),
                  if (_tagNames.isNotEmpty) _tags(theme),
                  CustomFieldsViewSection(itemId: widget.otpId),
                  const SizedBox(height: 24),
                ],
              ),
      ),
    );
  }

  Widget _info(ThemeData t, IconData i, String l, String v) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(i, color: t.colorScheme.primary),
        title: Text(l, style: t.textTheme.bodySmall),
        subtitle: Text(v, style: t.textTheme.bodyLarge),
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
