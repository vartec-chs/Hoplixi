import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/password_manager/dashboard/dashboard.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/dashboard_list_refresh_trigger_provider.dart';
import 'package:hoplixi/features/password_manager/import/keepass/services/keepass_import_service.dart';
import 'package:hoplixi/main_db/providers/other/dao_providers.dart';
import 'package:hoplixi/rust/api/keepass_api.dart';
import 'package:hoplixi/rust/api/keepass_api/types.dart';

const _messageNotChanged = Object();

enum KeepassImportStep { source, options, preview }

class KeepassImportState {
  final KeepassImportStep currentStep;
  final String? databasePath;
  final String? keyfilePath;
  final String password;
  final bool includeHistory;
  final bool includeAttachments;
  final bool importOtps;
  final bool importNotes;
  final bool importCustomFields;
  final bool createCategories;
  final bool isLoadingPreview;
  final bool isImporting;
  final String? message;
  final bool isSuccess;
  final FrbKeepassDatabaseExport? preview;
  final KeepassImportSummary? lastImportSummary;

  const KeepassImportState({
    this.currentStep = KeepassImportStep.source,
    this.databasePath,
    this.keyfilePath,
    this.password = '',
    this.includeHistory = true,
    this.includeAttachments = false,
    this.importOtps = true,
    this.importNotes = true,
    this.importCustomFields = true,
    this.createCategories = true,
    this.isLoadingPreview = false,
    this.isImporting = false,
    this.message,
    this.isSuccess = false,
    this.preview,
    this.lastImportSummary,
  });

  bool get canLoadPreview =>
      !isLoadingPreview &&
      !isImporting &&
      (databasePath?.trim().isNotEmpty ?? false);

  bool get canImport => !isImporting && preview != null;

  int get stepIndex => currentStep.index;

  bool get isFirstStep => currentStep == KeepassImportStep.source;

  bool get isLastStep => currentStep == KeepassImportStep.preview;

  bool get canGoToNextStep {
    switch (currentStep) {
      case KeepassImportStep.source:
        return (databasePath?.trim().isNotEmpty ?? false);
      case KeepassImportStep.options:
        return true;
      case KeepassImportStep.preview:
        return false;
    }
  }

  bool canGoToStep(KeepassImportStep step) {
    if (step.index <= stepIndex) {
      return true;
    }

    if (step == KeepassImportStep.options) {
      return (databasePath?.trim().isNotEmpty ?? false);
    }

    return false;
  }

  KeepassImportState copyWith({
    KeepassImportStep? currentStep,
    String? databasePath,
    Object? keyfilePath = _messageNotChanged,
    String? password,
    bool? includeHistory,
    bool? includeAttachments,
    bool? importOtps,
    bool? importNotes,
    bool? importCustomFields,
    bool? createCategories,
    bool? isLoadingPreview,
    bool? isImporting,
    Object? message = _messageNotChanged,
    bool? isSuccess,
    Object? preview = _messageNotChanged,
    Object? lastImportSummary = _messageNotChanged,
  }) {
    return KeepassImportState(
      currentStep: currentStep ?? this.currentStep,
      databasePath: databasePath ?? this.databasePath,
      keyfilePath: identical(keyfilePath, _messageNotChanged)
          ? this.keyfilePath
          : keyfilePath as String?,
      password: password ?? this.password,
      includeHistory: includeHistory ?? this.includeHistory,
      includeAttachments: includeAttachments ?? this.includeAttachments,
      importOtps: importOtps ?? this.importOtps,
      importNotes: importNotes ?? this.importNotes,
      importCustomFields: importCustomFields ?? this.importCustomFields,
      createCategories: createCategories ?? this.createCategories,
      isLoadingPreview: isLoadingPreview ?? this.isLoadingPreview,
      isImporting: isImporting ?? this.isImporting,
      message: identical(message, _messageNotChanged)
          ? this.message
          : message as String?,
      isSuccess: isSuccess ?? this.isSuccess,
      preview: identical(preview, _messageNotChanged)
          ? this.preview
          : preview as FrbKeepassDatabaseExport?,
      lastImportSummary: identical(lastImportSummary, _messageNotChanged)
          ? this.lastImportSummary
          : lastImportSummary as KeepassImportSummary?,
    );
  }
}

class KeepassImportNotifier extends Notifier<KeepassImportState> {
  @override
  KeepassImportState build() => const KeepassImportState();

  void nextStep() {
    if (!state.canGoToNextStep || state.isLastStep) {
      return;
    }

    final next = KeepassImportStep.values[state.stepIndex + 1];
    state = state.copyWith(currentStep: next);
  }

  void previousStep() {
    if (state.isFirstStep) {
      return;
    }

    final previous = KeepassImportStep.values[state.stepIndex - 1];
    state = state.copyWith(currentStep: previous);
  }

  void goToStep(KeepassImportStep step) {
    if (!state.canGoToStep(step)) {
      return;
    }

    state = state.copyWith(currentStep: step);
  }

  void setPassword(String value) {
    state = state.copyWith(password: value);
  }

  void setIncludeHistory(bool value) {
    state = state.copyWith(includeHistory: value);
    _resetPreview();
  }

  void setIncludeAttachments(bool value) {
    state = state.copyWith(includeAttachments: value);
    _resetPreview();
  }

  void setImportOtps(bool value) {
    state = state.copyWith(importOtps: value);
  }

  void setImportNotes(bool value) {
    state = state.copyWith(importNotes: value);
  }

  void setImportCustomFields(bool value) {
    state = state.copyWith(importCustomFields: value);
  }

  void setCreateCategories(bool value) {
    state = state.copyWith(createCategories: value);
  }

  Future<void> pickDatabase() async {
    final result = await FilePicker.pickFiles(
      dialogTitle: 'Выберите KeePass базу',
      type: FileType.custom,
      allowedExtensions: const ['kdbx', 'kdb'],
    );

    final path = result?.files.single.path;
    if (path == null || path.trim().isEmpty) {
      return;
    }

    state = state.copyWith(databasePath: path, message: null, isSuccess: false);
    _resetPreview();
  }

  Future<void> pickKeyfile() async {
    final result = await FilePicker.pickFiles(
      dialogTitle: 'Выберите KeePass keyfile',
      type: FileType.any,
    );

    final path = result?.files.single.path;
    if (path == null || path.trim().isEmpty) {
      return;
    }

    state = state.copyWith(keyfilePath: path, message: null, isSuccess: false);
    _resetPreview();
  }

  void clearKeyfile() {
    state = state.copyWith(keyfilePath: null);
    _resetPreview();
  }

  Future<void> loadPreview() async {
    final databasePath = state.databasePath?.trim();
    if (databasePath == null || databasePath.isEmpty) {
      state = state.copyWith(
        message: 'Сначала выберите файл KeePass базы.',
        isSuccess: false,
      );
      return;
    }

    state = state.copyWith(
      isLoadingPreview: true,
      message: null,
      isSuccess: false,
      lastImportSummary: null,
    );

    try {
      final preview = await exportKeepassDatabase(
        opts: FrbKeepassExportOptions(
          inputPath: databasePath,
          password: state.password.trim().isEmpty ? null : state.password,
          keyfilePath: state.keyfilePath?.trim().isEmpty ?? true
              ? null
              : state.keyfilePath,
          includeHistory: state.includeHistory,
          includeAttachments: state.includeAttachments,
        ),
      );

      state = state.copyWith(
        isLoadingPreview: false,
        currentStep: KeepassImportStep.preview,
        preview: preview,
        message:
            'База прочитана: ${preview.entries.length} записей, ${preview.groups.length} групп.',
        isSuccess: true,
      );
    } catch (error) {
      state = state.copyWith(
        isLoadingPreview: false,
        preview: null,
        message: 'Не удалось прочитать KeePass базу: $error',
        isSuccess: false,
      );
    }
  }

  Future<bool> importPreview() async {
    final preview = state.preview;
    if (preview == null) {
      state = state.copyWith(
        message: 'Сначала прочитайте KeePass базу и проверьте preview.',
        isSuccess: false,
      );
      return false;
    }

    state = state.copyWith(
      isImporting: true,
      message: null,
      isSuccess: false,
      lastImportSummary: null,
    );

    try {
      final service = await _buildService();
      final summary = await service.importDatabase(
        preview,
        KeepassImportExecutionOptions(
          importOtps: state.importOtps,
          importNotes: state.importNotes,
          importCustomFields: state.importCustomFields,
          createCategories: state.createCategories,
        ),
      );

      final refresh = ref.read(dashboardListRefreshTriggerProvider.notifier);
      if (summary.importedPasswords > 0) {
        refresh.triggerEntityAdd(EntityType.password);
      }
      if (summary.importedOtps > 0) {
        refresh.triggerEntityAdd(EntityType.otp);
      }
      if (summary.importedNotes > 0) {
        refresh.triggerEntityAdd(EntityType.note);
      }
      if (summary.createdCategories > 0) {
        refresh.triggerCategoryAdd();
      }
      if (summary.createdTags > 0) {
        refresh.triggerTagAdd();
      }

      state = state.copyWith(
        isImporting: false,
        preview: null,
        lastImportSummary: summary,
        message: summary.toMessage(),
        isSuccess: true,
      );
      return true;
    } catch (error) {
      state = state.copyWith(
        isImporting: false,
        message: 'Импорт KeePass завершился с ошибкой: $error',
        isSuccess: false,
      );
      return false;
    }
  }

  void _resetPreview() {
    state = state.copyWith(
      preview: null,
      lastImportSummary: null,
      message: null,
      isSuccess: false,
    );
  }

  Future<KeepassImportService> _buildService() async {
    final passwordDao = await ref.read(passwordDaoProvider.future);
    final otpDao = await ref.read(otpDaoProvider.future);
    final noteDao = await ref.read(noteDaoProvider.future);
    final categoryDao = await ref.read(categoryDaoProvider.future);
    final tagDao = await ref.read(tagDaoProvider.future);
    final customFieldDao = await ref.read(customFieldDaoProvider.future);

    return KeepassImportService(
      passwordDao: passwordDao,
      otpDao: otpDao,
      noteDao: noteDao,
      categoryDao: categoryDao,
      tagDao: tagDao,
      customFieldDao: customFieldDao,
    );
  }
}

final keepassImportProvider =
    NotifierProvider.autoDispose<KeepassImportNotifier, KeepassImportState>(
      KeepassImportNotifier.new,
    );
