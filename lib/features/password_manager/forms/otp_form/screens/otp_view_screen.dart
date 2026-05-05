import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/features/password_manager/forms/shared/share/share_fields_helpers.dart';
import 'package:hoplixi/features/password_manager/forms/shared/share/shareable_field.dart';
import 'package:hoplixi/features/password_manager/shared/utils/copy_usage_utils.dart';
import 'package:hoplixi/generated/l10n/translations.g.dart';
import 'package:hoplixi/main_db/core/main_store.dart';
import 'package:hoplixi/main_db/core/models/enums/entity_types.dart';
import 'package:hoplixi/main_db/providers/other/dao_providers.dart';
import 'package:hoplixi/routing/paths.dart';
import 'package:hoplixi/features/password_manager/shared/widgets/custom_fields/widgets/custom_fields_view_section.dart';
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
  (VaultItemsData, OtpItemsData)? _otp;
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
      final dao = await ref.read(otpDaoProvider.future);
      final record = await dao.getById(widget.otpId);
      if (record != null && mounted) {
        setState(() {
          _otp = record;
          _isDeleted = record.$1.isDeleted;
          _isLoading = false;
        });
        _startCodeGeneration();
        await _loadRelatedData(record);
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadRelatedData((VaultItemsData, OtpItemsData) record) async {
    final vault = record.$1;
    if (vault.categoryId != null) {
      final catDao = await ref.read(categoryDaoProvider.future);
      final cat = await catDao.getCategoryById(vault.categoryId!);
      if (mounted && cat != null) setState(() => _categoryName = cat.name);
    }

    final vaultItemDao = await ref.read(vaultItemDaoProvider.future);
    final tagIds = await vaultItemDao.getTagIds(widget.otpId);
    if (tagIds.isNotEmpty) {
      final tagDao = await ref.read(tagDaoProvider.future);
      final tags = await tagDao.getTagsByIds(tagIds);
      if (mounted) setState(() => _tagNames = tags.map((t) => t.name).toList());
    }
  }

  void _startCodeGeneration() {
    _generateCode();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _generateCode());
  }

  void _generateCode() {
    if (_otp == null) return;

    final secretBytes = _otp!.$2.secret;
    if (secretBytes.isEmpty) return;

    // Decode secret based on encoding
    String secretString;
    try {
      secretString = _decodeSecret(secretBytes, _otp!.$2.secretEncoding);
    } catch (_) {
      return;
    }

    final period = _otp!.$2.period;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final remaining = period - (now % period);

    final code = OTP.generateTOTPCodeString(
      secretString,
      DateTime.now().millisecondsSinceEpoch,
      length: _otp!.$2.digits,
      interval: period,
      algorithm: _getAlgorithm(_otp!.$2.algorithm),
    );

    if (mounted) {
      setState(() {
        _currentCode = code;
        _remainingSeconds = remaining;
      });
    }
  }

  String _decodeSecret(Uint8List bytes, SecretEncoding encoding) {
    switch (encoding) {
      case SecretEncoding.BASE32:
        return utf8.decode(bytes);
      case SecretEncoding.HEX:
        return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
      case SecretEncoding.BINARY:
        return base64.encode(bytes);
    }
  }

  Algorithm _getAlgorithm(AlgorithmOtp algo) {
    switch (algo) {
      case AlgorithmOtp.SHA256:
        return Algorithm.SHA256;
      case AlgorithmOtp.SHA512:
        return Algorithm.SHA512;
      case AlgorithmOtp.SHA1:
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
      secret = _decodeSecret(record.$2.secret, record.$2.secretEncoding);
    } catch (_) {
      secret = null;
    }

    final customFields = await loadCustomShareableFields(ref, widget.otpId);
    final fields = [
      ...buildCommonShareFields(
        context,
        name: record.$1.name,
        categoryName: _categoryName,
        tagNames: _tagNames,
        description: record.$1.description,
      ),
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
          value: record.$2.issuer,
        ),
        shareableField(
          id: 'account',
          label: l10n.otp_account_name_label,
          value: record.$2.accountName,
        ),
        shareableField(
          id: 'period',
          label: l10n.period_seconds_label,
          value: record.$2.period,
        ),
        shareableField(
          id: 'digits',
          label: l10n.digits_count_label,
          value: record.$2.digits,
        ),
        shareableField(
          id: 'algorithm',
          label: l10n.algorithm_label,
          value: record.$2.algorithm.name,
        ),
      ]),
      ...customFields,
    ];

    await shareEntityFields(
      context: context,
      entity: ShareableEntity(
        title: record.$1.name,
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
      appBar: AppBar(
        title: Text(_otp?.$1.name ?? 'OTP'),
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
                                    value: _remainingSeconds / _otp!.$2.period,
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
                    _otp!.$2.issuer ?? '-',
                  ),
                  _info(
                    theme,
                    LucideIcons.user,
                    'Аккаунт',
                    _otp!.$2.accountName ?? '-',
                  ),
                  _info(
                    theme,
                    LucideIcons.timer,
                    'Период',
                    '${_otp!.$2.period} сек',
                  ),
                  _info(theme, LucideIcons.hash, 'Цифр', '${_otp!.$2.digits}'),
                  _info(
                    theme,
                    LucideIcons.cpu,
                    'Алгоритм',
                    _otp!.$2.algorithm.name,
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
