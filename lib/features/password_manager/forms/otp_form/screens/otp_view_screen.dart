import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/models/enums/entity_types.dart';
import 'package:hoplixi/main_store/provider/dao_providers.dart';
import 'package:hoplixi/routing/paths.dart';
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
  OtpsData? _otp;
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
      final otp = await dao.getOtpById(widget.otpId);
      if (otp != null && mounted) {
        setState(() {
          _otp = otp;
          _isLoading = false;
        });
        _startCodeGeneration();
        await _loadRelatedData(otp);
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadRelatedData(OtpsData otp) async {
    if (otp.categoryId != null) {
      final catDao = await ref.read(categoryDaoProvider.future);
      final cat = await catDao.getCategoryById(otp.categoryId!);
      if (mounted && cat != null) setState(() => _categoryName = cat.name);
    }

    final dao = await ref.read(otpDaoProvider.future);
    final tagIds = await dao.getOtpTagIds(widget.otpId);
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

    final secretBytes = _otp!.secret;
    if (secretBytes.isEmpty) return;

    // Decode secret based on encoding
    String secretString;
    try {
      secretString = _decodeSecret(secretBytes, _otp!.secretEncoding);
    } catch (_) {
      return;
    }

    final period = _otp!.period;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final remaining = period - (now % period);

    final code = OTP.generateTOTPCodeString(
      secretString,
      DateTime.now().millisecondsSinceEpoch,
      length: _otp!.digits,
      interval: period,
      algorithm: _getAlgorithm(_otp!.algorithm),
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
    Clipboard.setData(ClipboardData(text: _currentCode));
    Toaster.success(title: 'Скопировано', description: 'OTP код скопирован');
    final dao = await ref.read(otpDaoProvider.future);
    await dao.incrementUsage(widget.otpId);
  }

  void _edit() => context.go(
    AppRoutesPaths.dashboardEntityEdit(EntityType.otp, widget.otpId),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_otp?.issuer ?? 'OTP'),
        actions: [
          IconButton(icon: const Icon(LucideIcons.pencil), onPressed: _edit),
        ],
      ),
      body: _isLoading
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
                                  value: _remainingSeconds / _otp!.period,
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
                  _otp!.issuer ?? '-',
                ),
                _info(
                  theme,
                  LucideIcons.user,
                  'Аккаунт',
                  _otp!.accountName ?? '-',
                ),
                _info(
                  theme,
                  LucideIcons.timer,
                  'Период',
                  '${_otp!.period} сек',
                ),
                _info(theme, LucideIcons.hash, 'Цифр', '${_otp!.digits}'),
                _info(theme, LucideIcons.cpu, 'Алгоритм', _otp!.algorithm.name),
                if (_categoryName != null)
                  _info(theme, LucideIcons.folder, 'Категория', _categoryName!),
                if (_tagNames.isNotEmpty) _tags(theme),
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
