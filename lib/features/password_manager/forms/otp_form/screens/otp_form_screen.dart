import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/category_manager/features/category_picker/category_picker.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/form_close_button.dart';
import 'package:hoplixi/features/password_manager/note_picker/note_picker_field.dart';
import 'package:hoplixi/features/password_manager/tags_manager/features/tags_picker/tags_picker.dart';
import 'package:hoplixi/features/qr_scanner/widgets/qr_scanner_widget.dart';
import 'package:hoplixi/main_store/models/enums/entity_types.dart';
import 'package:hoplixi/main_store/provider/dao_providers.dart';
import 'package:hoplixi/shared/ui/text_field.dart';

import '../models/otp_form_state.dart';
import '../providers/otp_form_provider.dart';

/// Форма для создания и редактирования OTP/2FA
class OtpFormScreen extends ConsumerStatefulWidget {
  final String? otpId;

  const OtpFormScreen({super.key, this.otpId});

  @override
  ConsumerState<OtpFormScreen> createState() => _OtpFormScreenState();
}

class _OtpFormScreenState extends ConsumerState<OtpFormScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  late final TabController _tabController;
  late final TextEditingController _issuerController;
  late final TextEditingController _accountNameController;
  late final TextEditingController _secretController;
  late final TextEditingController _periodController;
  late final TextEditingController _counterController;

  bool _obscureSecret = true;
  bool _controllersInitialized = false;
  String? _noteName;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 2, vsync: this);
    _issuerController = TextEditingController();
    _accountNameController = TextEditingController();
    _secretController = TextEditingController();
    _periodController = TextEditingController(text: '30');
    _counterController = TextEditingController(text: '0');

    // Слушаем переключение табов
    _tabController.addListener(_onTabChanged);

    // Инициализация формы
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(otpFormProvider.notifier);
      if (widget.otpId != null) {
        notifier.initForEdit(widget.otpId!);
      } else {
        notifier.initForCreate();
      }
    });
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      final notifier = ref.read(otpFormProvider.notifier);
      if (_tabController.index == 0) {
        notifier.setOtpType(OtpType.totp);
      } else {
        notifier.setOtpType(OtpType.hotp);
      }
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
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
      title: 'Сканировать QR-код',
      subtitle: 'Отсканируйте QR-код из приложения или сервиса',
    );

    if (result != null && mounted) {
      final notifier = ref.read(otpFormProvider.notifier);
      notifier.applyFromQrCode(result);

      // Синхронизируем контроллеры с новым состоянием
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _syncControllersWithState();
      });

      Toaster.success(
        title: 'QR-код распознан',
        description: 'Данные успешно загружены',
      );
    }
  }

  void _syncControllersWithState() {
    final state = ref.read(otpFormProvider);

    if (_issuerController.text != state.issuer) {
      _issuerController.text = state.issuer;
    }
    if (_accountNameController.text != state.accountName) {
      _accountNameController.text = state.accountName;
    }
    if (_secretController.text != state.secret) {
      _secretController.text = state.secret;
    }
    if (_periodController.text != state.period.toString()) {
      _periodController.text = state.period.toString();
    }
    if (state.counter != null &&
        _counterController.text != state.counter.toString()) {
      _counterController.text = state.counter.toString();
    }

    // Синхронизируем таб
    if (state.otpType == OtpType.totp && _tabController.index != 0) {
      _tabController.animateTo(0);
    } else if (state.otpType == OtpType.hotp && _tabController.index != 1) {
      _tabController.animateTo(1);
    }

    _controllersInitialized = true;
  }

  Future<void> _loadNoteName(String noteId) async {
    final noteDao = ref.read(noteDaoProvider);
    final asyncValue = noteDao;

    // Ждём данные из AsyncValue
    if (!asyncValue.hasValue) return;

    final note = await asyncValue.value!.getNoteById(noteId);
    if (mounted) {
      setState(() {
        _noteName = note?.title;
      });
    }
  }

  void _handleSave() async {
    final notifier = ref.read(otpFormProvider.notifier);
    final success = await notifier.save();

    if (!mounted) return;

    if (success) {
      Toaster.success(
        title: widget.otpId != null ? 'OTP обновлён' : 'OTP создан',
        description: 'Изменения успешно сохранены',
      );
      context.pop(true);
    } else {
      Toaster.error(
        title: 'Ошибка сохранения',
        description: 'Не удалось сохранить OTP',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(otpFormProvider);

    // Синхронизация контроллеров с состоянием при загрузке данных
    if ((state.isEditMode || state.isFromQrCode) &&
        !state.isLoading &&
        !_controllersInitialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _syncControllersWithState();
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.otpId != null ? 'Редактировать OTP' : 'Новый OTP'),
        actions: [
          // Кнопка сканирования QR
          if (!state.isEditMode)
            IconButton(
              icon: const Icon(Icons.qr_code_scanner),
              tooltip: 'Сканировать QR-код',
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
        leading: FormCloseButton(),
        bottom: TabBar(
          tabAlignment: TabAlignment.fill,
          controller: _tabController,
          tabs: const [
            Tab(text: 'TOTP', icon: Icon(Icons.timer)),
            Tab(text: 'HOTP', icon: Icon(Icons.numbers)),
          ],
        ),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // TOTP форма
                      _buildTotpForm(context, state),
                      // HOTP форма (заглушка)
                      _buildHotpPlaceholder(context),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildTotpForm(BuildContext context, OtpFormState state) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // Кнопка сканирования QR (большая)
          if (!state.isEditMode) ...[
            _QrScanButton(onTap: _handleScanQr),
            const SizedBox(height: 24),
            _buildDividerWithText(context, 'или введите вручную'),
            const SizedBox(height: 16),
          ],

          // Индикатор загрузки из QR
          if (state.isFromQrCode) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Данные загружены из QR-кода',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Секретный ключ *
          TextField(
            controller: _secretController,
            obscureText: _obscureSecret,
            decoration: primaryInputDecoration(
              context,
              labelText: 'Секретный ключ (Base32) *',
              hintText: 'JBSWY3DPEHPK3PXP',
              errorText: state.secretError,
              helperText: 'Обычно находится в настройках 2FA сервиса',
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      _obscureSecret ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureSecret = !_obscureSecret;
                      });
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.content_paste),
                    tooltip: 'Вставить из буфера',
                    onPressed: () async {
                      final data = await Clipboard.getData('text/plain');
                      if (data?.text != null) {
                        _secretController.text = data!.text!;
                        ref
                            .read(otpFormProvider.notifier)
                            .setSecret(data.text!);
                      }
                    },
                  ),
                ],
              ),
            ),
            onChanged: (value) {
              ref.read(otpFormProvider.notifier).setSecret(value);
            },
          ),
          const SizedBox(height: 16),

          // Издатель (Issuer)
          TextField(
            controller: _issuerController,
            decoration: primaryInputDecoration(
              context,
              labelText: 'Сервис / Издатель',
              hintText: 'Google, GitHub, Steam...',
            ),
            onChanged: (value) {
              ref.read(otpFormProvider.notifier).setIssuer(value);
            },
          ),
          const SizedBox(height: 16),

          // Имя аккаунта
          TextField(
            controller: _accountNameController,
            decoration: primaryInputDecoration(
              context,
              labelText: 'Имя аккаунта',
              hintText: 'email@example.com',
            ),
            keyboardType: TextInputType.emailAddress,
            onChanged: (value) {
              ref.read(otpFormProvider.notifier).setAccountName(value);
            },
          ),
          const SizedBox(height: 24),

          // Расширенные настройки
          _buildExpandableSection(
            context: context,
            title: 'Расширенные настройки',
            initiallyExpanded:
                state.algorithm != AlgorithmOtp.SHA1 ||
                state.digits != 6 ||
                state.period != 30,
            children: [
              // Алгоритм
              _buildDropdownField<AlgorithmOtp>(
                context: context,
                label: 'Алгоритм',
                value: state.algorithm,
                items: AlgorithmOtp.values,
                itemLabel: (item) => item.name,
                onChanged: (value) {
                  if (value != null) {
                    ref.read(otpFormProvider.notifier).setAlgorithm(value);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Количество цифр
              _buildDropdownField<int>(
                context: context,
                label: 'Количество цифр',
                value: state.digits,
                items: [6, 7, 8],
                itemLabel: (item) => item.toString(),
                onChanged: (value) {
                  if (value != null) {
                    ref.read(otpFormProvider.notifier).setDigits(value);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Период
              TextField(
                controller: _periodController,
                decoration: primaryInputDecoration(
                  context,
                  labelText: 'Период (секунды)',
                  hintText: '30',
                  errorText: state.periodError,
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (value) {
                  final period = int.tryParse(value) ?? 30;
                  ref.read(otpFormProvider.notifier).setPeriod(period);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Категория
          CategoryPickerField(
            selectedCategoryId: state.categoryId,
            selectedCategoryName: state.categoryName,
            label: 'Категория',
            hintText: 'Выберите категорию',
            filterByType: [CategoryType.totp, CategoryType.mixed],
            onCategorySelected: (categoryId, categoryName) {
              ref
                  .read(otpFormProvider.notifier)
                  .setCategory(categoryId, categoryName);
            },
          ),
          const SizedBox(height: 16),

          // Теги
          TagPickerField(
            selectedTagIds: state.tagIds,
            selectedTagNames: state.tagNames,
            label: 'Теги',
            hintText: 'Выберите теги',
            filterByType: [TagType.totp, TagType.mixed],
            onTagsSelected: (tagIds, tagNames) {
              ref.read(otpFormProvider.notifier).setTags(tagIds, tagNames);
            },
          ),
          const SizedBox(height: 16),

          // Заметки
          NotePickerField(
            selectedNoteId: state.noteId,
            selectedNoteName: _noteName,
            onNoteSelected: (noteId, noteName) {
              ref.read(otpFormProvider.notifier).setNoteId(noteId);
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHotpPlaceholder(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.construction,
                size: 64,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'HOTP в разработке',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Поддержка HOTP (счётчик-based) будет добавлена в следующих версиях',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Используйте TOTP для большинства сервисов',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDividerWithText(BuildContext context, String text) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Expanded(child: Divider(color: colorScheme.outline.withOpacity(0.3))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(child: Divider(color: colorScheme.outline.withOpacity(0.3))),
      ],
    );
  }

  Widget _buildExpandableSection({
    required BuildContext context,
    required String title,
    required List<Widget> children,
    bool initiallyExpanded = false,
  }) {
    final theme = Theme.of(context);

    return Theme(
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        initiallyExpanded: initiallyExpanded,
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(top: 8),
        children: children,
      ),
    );
  }

  Widget _buildDropdownField<T>({
    required BuildContext context,
    required String label,
    required T value,
    required List<T> items,
    required String Function(T) itemLabel,
    required ValueChanged<T?> onChanged,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          value: value,
          decoration: primaryInputDecoration(context),
          items: items.map((item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Text(itemLabel(item)),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

/// Кнопка сканирования QR-кода
class _QrScanButton extends StatelessWidget {
  final VoidCallback onTap;

  const _QrScanButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.primaryContainer.withOpacity(0.3),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.primary.withOpacity(0.3),
              width: 2,
              strokeAlign: BorderSide.strokeAlignInside,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.qr_code_scanner,
                  size: 48,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Сканировать QR-код',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Быстро добавьте 2FA из приложения',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
