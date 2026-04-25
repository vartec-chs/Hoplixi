import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/form_close_button.dart';
import 'package:hoplixi/features/qr_scanner/widgets/qr_scanner_widget.dart';
import 'package:hoplixi/generated/l10n/translations.g.dart';
import 'package:hoplixi/main_db/core/models/enums/index.dart';
import 'package:hoplixi/main_db/old/provider/dao_providers.dart';
import 'package:hoplixi/routing/paths.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../models/otp_form_state.dart';
import '../providers/otp_form_provider.dart';
import '../widgets/otp_hotp_placeholder_widget.dart';
import '../widgets/otp_totp_form_widget.dart';

class OtpFormScreen extends ConsumerStatefulWidget {
  final String? otpId;

  const OtpFormScreen({super.key, this.otpId});

  @override
  ConsumerState<OtpFormScreen> createState() => _OtpFormScreenState();
}

class _OtpFormScreenState extends ConsumerState<OtpFormScreen>
    with SingleTickerProviderStateMixin {
  ProviderSubscription<OtpFormState>? _otpFormSubscription;
  late final TabController _tabController;
  late final TextEditingController _issuerController;
  late final TextEditingController _accountNameController;
  late final TextEditingController _secretController;
  late final TextEditingController _periodController;
  late final TextEditingController _counterController;

  String? _noteName;
  bool _isDisposing = false;
  OtpFormState? _pendingStateSync;
  OtpFormState? _pendingPreviousStateSync;
  bool _isStateSyncScheduled = false;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 2, vsync: this);
    _issuerController = TextEditingController();
    _accountNameController = TextEditingController();
    _secretController = TextEditingController();
    _periodController = TextEditingController(text: '30');
    _counterController = TextEditingController();

    _tabController.addListener(_onTabChanged);
    _issuerController.addListener(_onIssuerChanged);
    _accountNameController.addListener(_onAccountNameChanged);
    _secretController.addListener(_onSecretChanged);
    _periodController.addListener(_onPeriodChanged);
    _counterController.addListener(_onCounterChanged);
    _otpFormSubscription = ref.listenManual<OtpFormState>(
      otpFormProvider,
      _onOtpFormStateChanged,
      fireImmediately: true,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _isDisposing) return;

      final notifier = ref.read(otpFormProvider.notifier);
      if (widget.otpId != null) {
        notifier.initForEdit(widget.otpId!);
      } else {
        notifier.initForCreate();
      }
    });
  }

  void _onTabChanged() {
    if (_isDisposing) return;
    if (_tabController.indexIsChanging) return;

    final notifier = ref.read(otpFormProvider.notifier);
    if (_tabController.index == 0) {
      notifier.setOtpType(OtpType.totp);
    } else {
      notifier.setOtpType(OtpType.hotp);
    }
  }

  void _onIssuerChanged() {
    if (_isDisposing) return;
    final value = _issuerController.text;
    if (ref.read(otpFormProvider).issuer == value) return;
    ref.read(otpFormProvider.notifier).setIssuer(value);
  }

  void _onAccountNameChanged() {
    if (_isDisposing) return;
    final value = _accountNameController.text;
    if (ref.read(otpFormProvider).accountName == value) return;
    ref.read(otpFormProvider.notifier).setAccountName(value);
  }

  void _onSecretChanged() {
    if (_isDisposing) return;
    final value = _secretController.text;
    if (ref.read(otpFormProvider).secret == value) return;
    ref.read(otpFormProvider.notifier).setSecret(value);
  }

  void _onPeriodChanged() {
    if (_isDisposing) return;
    final value = int.tryParse(_periodController.text) ?? 30;
    if (ref.read(otpFormProvider).period == value) return;
    ref.read(otpFormProvider.notifier).setPeriod(value);
  }

  void _onCounterChanged() {
    if (_isDisposing) return;
    final value = int.tryParse(_counterController.text);
    if (ref.read(otpFormProvider).counter == value) return;
    ref.read(otpFormProvider.notifier).setCounter(value);
  }

  void _onOtpFormStateChanged(OtpFormState? previous, OtpFormState next) {
    if (!mounted || _isDisposing) return;

    _pendingPreviousStateSync = previous;
    _pendingStateSync = next;

    if (_isStateSyncScheduled) return;
    _isStateSyncScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _isStateSyncScheduled = false;
      if (!mounted || _isDisposing) return;

      final queuedState = _pendingStateSync;
      final queuedPreviousState = _pendingPreviousStateSync;
      _pendingStateSync = null;
      _pendingPreviousStateSync = null;

      if (queuedState == null) return;

      _syncTextController(_issuerController, queuedState.issuer);
      _syncTextController(_accountNameController, queuedState.accountName);
      _syncTextController(_secretController, queuedState.secret);
      _syncTextController(_periodController, queuedState.period.toString());
      _syncTextController(
        _counterController,
        queuedState.counter?.toString() ?? '',
      );
      _syncTabController(queuedState.otpType);

      if (queuedPreviousState?.noteId != queuedState.noteId) {
        _handleNoteIdChanged(queuedState.noteId);
      }
    });
  }

  void _syncTextController(TextEditingController controller, String value) {
    if (_isDisposing) return;
    if (controller.text == value) return;

    controller.value = controller.value.copyWith(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
      composing: TextRange.empty,
    );
  }

  void _syncTabController(OtpType otpType) {
    final targetIndex = otpType == OtpType.totp ? 0 : 1;
    if (_isDisposing || _tabController.index == targetIndex) return;
    _tabController.index = targetIndex;
  }

  void _handleNoteIdChanged(String? noteId) {
    if (_isDisposing) return;
    if (noteId == null) {
      if (_noteName == null) return;
      setState(() => _noteName = null);
      return;
    }

    _loadNoteName(noteId);
  }

  @override
  void dispose() {
    _isDisposing = true;
    _otpFormSubscription?.close();
    _tabController.removeListener(_onTabChanged);
    _issuerController.removeListener(_onIssuerChanged);
    _accountNameController.removeListener(_onAccountNameChanged);
    _secretController.removeListener(_onSecretChanged);
    _periodController.removeListener(_onPeriodChanged);
    _counterController.removeListener(_onCounterChanged);
    _tabController.dispose();
    _issuerController.dispose();
    _accountNameController.dispose();
    _secretController.dispose();
    _periodController.dispose();
    _counterController.dispose();
    super.dispose();
  }

  Future<void> _handleScanQr() async {
    final result = await showQrScannerDialog(
      context: context,
      title: context.t.dashboard_forms.scan_qr_code_title,
      subtitle: context.t.dashboard_forms.scan_qr_code_subtitle,
    );

    if (result != null && mounted && !_isDisposing) {
      ref.read(otpFormProvider.notifier).applyFromQrCode(result.text);

      Toaster.success(
        title: context.t.dashboard_forms.qr_code_recognized,
        description: context.t.dashboard_forms.data_loaded_successfully,
      );
    }
  }

  Future<void> _loadNoteName(String noteId) async {
    final noteDao = await ref.read(noteDaoProvider.future);
    final record = await noteDao.getById(noteId);
    if (!mounted ||
        _isDisposing ||
        ref.read(otpFormProvider).noteId != noteId) {
      return;
    }

    setState(() {
      _noteName = record?.$1.name;
    });
  }

  void _handleSave() async {
    final notifier = ref.read(otpFormProvider.notifier);
    final success = await notifier.save();

    if (!mounted || _isDisposing) return;

    if (success) {
      Toaster.success(
        title: widget.otpId != null
            ? context.t.dashboard_forms.otp_updated
            : context.t.dashboard_forms.otp_created,
        description: context.t.dashboard_forms.changes_saved_successfully,
      );
      context.pop(true);
    } else {
      Toaster.error(
        title: context.t.dashboard_forms.save_error,
        description: context.t.dashboard_forms.failed_to_save_otp,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(otpFormProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.otpId != null
              ? context.t.dashboard_forms.edit_otp
              : context.t.dashboard_forms.new_otp,
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.import),
            tooltip: context.t.dashboard_forms.import_otp_tooltip,
            onPressed: () => context.go(AppRoutesPaths.otpImport),
          ),
          if (!state.isEditMode)
            IconButton(
              icon: const Icon(Icons.qr_code_scanner),
              tooltip: context.t.dashboard_forms.scan_qr_code_tooltip,
              onPressed: _handleScanQr,
            ),
          if (state.isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(icon: const Icon(Icons.save), onPressed: _handleSave),
        ],
        leading: const FormCloseButton(),
        bottom: TabBar(
          tabAlignment: TabAlignment.fill,
          controller: _tabController,
          tabs: const [
            Tab(text: 'TOTP', icon: Icon(Icons.timer)),
            Tab(text: 'HOTP', icon: Icon(Icons.numbers)),
          ],
        ),
      ),
      body: SafeArea(
        child: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        OtpTotpFormWidget(
                          state: state,
                          secretController: _secretController,
                          issuerController: _issuerController,
                          accountNameController: _accountNameController,
                          periodController: _periodController,
                          noteName: _noteName,
                          onScanQr: _handleScanQr,
                        ),
                        const OtpHotpPlaceholderWidget(),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
