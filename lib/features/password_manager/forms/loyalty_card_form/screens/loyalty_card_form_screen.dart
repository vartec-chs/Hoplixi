import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/form_close_button.dart';
import 'package:hoplixi/features/password_manager/pickers/category_picker/category_picker.dart';
import 'package:hoplixi/features/password_manager/pickers/note_picker/note_picker_field.dart';
import 'package:hoplixi/features/password_manager/pickers/tags_picker/tags_picker.dart';
import 'package:hoplixi/features/qr_scanner/widgets/qr_scanner_widget.dart';
import 'package:hoplixi/main_store/models/enums/entity_types.dart';
import 'package:hoplixi/shared/ui/text_field.dart';

import '../providers/loyalty_card_form_provider.dart';

class LoyaltyCardFormScreen extends ConsumerStatefulWidget {
  const LoyaltyCardFormScreen({super.key, this.loyaltyCardId});

  final String? loyaltyCardId;

  @override
  ConsumerState<LoyaltyCardFormScreen> createState() =>
      _LoyaltyCardFormScreenState();
}

class _LoyaltyCardFormScreenState extends ConsumerState<LoyaltyCardFormScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _programNameController;
  late final TextEditingController _cardNumberController;
  late final TextEditingController _holderNameController;
  late final TextEditingController _passwordController;
  late final TextEditingController _barcodeValueController;
  late final TextEditingController _barcodeTypeController;
  late final TextEditingController _pointsBalanceController;
  late final TextEditingController _tierController;
  late final TextEditingController _expiryDateController;
  late final TextEditingController _websiteController;
  late final TextEditingController _phoneNumberController;
  late final TextEditingController _descriptionController;

  bool _passwordVisible = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _programNameController = TextEditingController();
    _cardNumberController = TextEditingController();
    _holderNameController = TextEditingController();
    _passwordController = TextEditingController();
    _barcodeValueController = TextEditingController();
    _barcodeTypeController = TextEditingController();
    _pointsBalanceController = TextEditingController();
    _tierController = TextEditingController();
    _expiryDateController = TextEditingController();
    _websiteController = TextEditingController();
    _phoneNumberController = TextEditingController();
    _descriptionController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(loyaltyCardFormProvider.notifier);
      if (widget.loyaltyCardId == null) {
        notifier.initForCreate();
      } else {
        notifier.initForEdit(widget.loyaltyCardId!);
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _programNameController.dispose();
    _cardNumberController.dispose();
    _holderNameController.dispose();
    _passwordController.dispose();
    _barcodeValueController.dispose();
    _barcodeTypeController.dispose();
    _pointsBalanceController.dispose();
    _tierController.dispose();
    _expiryDateController.dispose();
    _websiteController.dispose();
    _phoneNumberController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _formatExpiryForDisplay(String isoString) {
    final dt = DateTime.tryParse(isoString);
    if (dt == null) return '';
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year.toString();
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    if (dt.hour == 0 && dt.minute == 0) return '$day.$month.$year';
    return '$day.$month.$year $hour:$minute';
  }

  Future<void> _pickExpiryDate() async {
    final current =
        DateTime.tryParse(ref.read(loyaltyCardFormProvider).expiryDate) ??
        DateTime.now();

    final date = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current.hour, minute: current.minute),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (!mounted) return;

    final combined = DateTime(
      date.year,
      date.month,
      date.day,
      time?.hour ?? 0,
      time?.minute ?? 0,
    );
    ref
        .read(loyaltyCardFormProvider.notifier)
        .setExpiryDate(combined.toIso8601String());
  }

  Future<void> _scanBarcode() async {
    final result = await showQrScannerDialog(
      context: context,
      title: 'Сканировать код карты',
      subtitle: 'Отсканируйте QR-код или штрихкод карты лояльности',
      enableQrCode: true,
      enableBarcode: true,
    );
    if (result != null && mounted) {
      ref.read(loyaltyCardFormProvider.notifier).setBarcodeValue(result.text);
      ref
          .read(loyaltyCardFormProvider.notifier)
          .setBarcodeType(result.formatName);
    }
  }

  Future<void> _save() async {
    final success = await ref.read(loyaltyCardFormProvider.notifier).save();
    if (!mounted) return;

    if (!success) {
      Toaster.error(
        title: 'Не удалось сохранить карту лояльности',
        description: 'Проверьте поля формы и попробуйте снова',
      );
    }
  }

  void _syncControllers(state) {
    if (_nameController.text != state.name) _nameController.text = state.name;
    if (_programNameController.text != state.programName) {
      _programNameController.text = state.programName;
    }
    if (_cardNumberController.text != state.cardNumber) {
      _cardNumberController.text = state.cardNumber;
    }
    if (_holderNameController.text != state.holderName) {
      _holderNameController.text = state.holderName;
    }
    if (_passwordController.text != state.password) {
      _passwordController.text = state.password;
    }
    if (_barcodeValueController.text != state.barcodeValue) {
      _barcodeValueController.text = state.barcodeValue;
    }
    if (_barcodeTypeController.text != state.barcodeType) {
      _barcodeTypeController.text = state.barcodeType;
    }
    if (_pointsBalanceController.text != state.pointsBalance) {
      _pointsBalanceController.text = state.pointsBalance;
    }
    if (_tierController.text != state.tier) _tierController.text = state.tier;
    final formattedExpiry = _formatExpiryForDisplay(state.expiryDate);
    if (_expiryDateController.text != formattedExpiry) {
      _expiryDateController.text = formattedExpiry;
    }
    if (_websiteController.text != state.website) {
      _websiteController.text = state.website;
    }
    if (_phoneNumberController.text != state.phoneNumber) {
      _phoneNumberController.text = state.phoneNumber;
    }
    if (_descriptionController.text != state.description) {
      _descriptionController.text = state.description;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(loyaltyCardFormProvider);

    ref.listen(loyaltyCardFormProvider, (previous, next) {
      if ((previous?.isSaved ?? false) == false && next.isSaved) {
        Toaster.success(
          title: widget.loyaltyCardId == null
              ? 'Карта лояльности создана'
              : 'Карта лояльности обновлена',
        );
        ref.read(loyaltyCardFormProvider.notifier).resetSaved();
        if (context.mounted) context.pop(true);
      }
    });

    _syncControllers(state);

    return Scaffold(
      appBar: AppBar(
        leading: const FormCloseButton(),
        title: Text(
          state.isEditMode
              ? 'Редактирование карты лояльности'
              : 'Новая карта лояльности',
        ),
        actions: [
          if (state.isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(icon: const Icon(Icons.save_outlined), onPressed: _save),
        ],
      ),
      body: SafeArea(
        child: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: formPadding,
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: primaryInputDecoration(
                      context,
                      labelText: 'Название',
                      errorText: state.nameError,
                      prefixIcon: const Icon(Icons.badge_outlined),
                    ),
                    onChanged: ref
                        .read(loyaltyCardFormProvider.notifier)
                        .setName,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _programNameController,
                    decoration: primaryInputDecoration(
                      context,
                      labelText: 'Программа',
                      hintText: 'Например: Лента Club',
                      errorText: state.programNameError,
                      prefixIcon: const Icon(Icons.storefront_outlined),
                    ),
                    onChanged: ref
                        .read(loyaltyCardFormProvider.notifier)
                        .setProgramName,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _cardNumberController,
                    decoration: primaryInputDecoration(
                      context,
                      labelText: 'Номер карты',
                      hintText: 'Номер карты или штрихкод обязательны',
                      errorText: state.cardOrBarcodeError,
                      prefixIcon: const Icon(Icons.credit_card_outlined),
                    ),
                    onChanged: ref
                        .read(loyaltyCardFormProvider.notifier)
                        .setCardNumber,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _holderNameController,
                    decoration: primaryInputDecoration(
                      context,
                      labelText: 'Владелец',
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                    onChanged: ref
                        .read(loyaltyCardFormProvider.notifier)
                        .setHolderName,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordController,
                    obscureText: !_passwordVisible,
                    decoration:
                        primaryInputDecoration(
                          context,
                          labelText: 'PIN / Пароль',
                          prefixIcon: const Icon(Icons.lock_outline),
                        ).copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              _passwordVisible
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                            tooltip: _passwordVisible ? 'Скрыть' : 'Показать',
                            onPressed: () => setState(
                              () => _passwordVisible = !_passwordVisible,
                            ),
                          ),
                        ),
                    onChanged: ref
                        .read(loyaltyCardFormProvider.notifier)
                        .setPassword,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _barcodeValueController,
                          decoration:
                              primaryInputDecoration(
                                context,
                                labelText: 'Штрихкод',
                                errorText: state.cardOrBarcodeError != null
                                    ? ''
                                    : null,
                                prefixIcon: const Icon(Icons.qr_code),
                              ).copyWith(
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.qr_code_scanner),
                                  tooltip: 'Сканировать',
                                  onPressed: _scanBarcode,
                                ),
                              ),
                          onChanged: ref
                              .read(loyaltyCardFormProvider.notifier)
                              .setBarcodeValue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _barcodeTypeController,
                          decoration: primaryInputDecoration(
                            context,
                            labelText: 'Тип штрихкода',
                            hintText: 'EAN-13, QR',
                            prefixIcon: const Icon(
                              Icons.qr_code_scanner_outlined,
                            ),
                          ),
                          onChanged: ref
                              .read(loyaltyCardFormProvider.notifier)
                              .setBarcodeType,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _pointsBalanceController,
                          decoration: primaryInputDecoration(
                            context,
                            labelText: 'Баланс/бонусы',
                            prefixIcon: const Icon(Icons.stars_outlined),
                          ),
                          onChanged: ref
                              .read(loyaltyCardFormProvider.notifier)
                              .setPointsBalance,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _tierController,
                          decoration: primaryInputDecoration(
                            context,
                            labelText: 'Уровень',
                            prefixIcon: const Icon(
                              Icons.workspace_premium_outlined,
                            ),
                          ),
                          onChanged: ref
                              .read(loyaltyCardFormProvider.notifier)
                              .setTier,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _expiryDateController,
                    readOnly: true,
                    onTap: _pickExpiryDate,
                    decoration:
                        primaryInputDecoration(
                          context,
                          labelText: 'Срок действия',
                          errorText: state.expiryDateError,
                          prefixIcon: const Icon(Icons.event_outlined),
                        ).copyWith(
                          suffixIcon: state.expiryDate.isNotEmpty
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.clear),
                                      tooltip: 'Очистить',
                                      onPressed: () => ref
                                          .read(
                                            loyaltyCardFormProvider.notifier,
                                          )
                                          .setExpiryDate(''),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit_calendar_outlined,
                                      ),
                                      tooltip: 'Изменить дату',
                                      onPressed: _pickExpiryDate,
                                    ),
                                  ],
                                )
                              : IconButton(
                                  icon: const Icon(
                                    Icons.edit_calendar_outlined,
                                  ),
                                  tooltip: 'Выбрать дату',
                                  onPressed: _pickExpiryDate,
                                ),
                        ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _websiteController,
                          decoration: primaryInputDecoration(
                            context,
                            labelText: 'Сайт',
                            hintText: 'https://example.com',
                            errorText: state.websiteError,
                            prefixIcon: const Icon(Icons.public_outlined),
                          ),
                          onChanged: ref
                              .read(loyaltyCardFormProvider.notifier)
                              .setWebsite,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _phoneNumberController,
                          decoration: primaryInputDecoration(
                            context,
                            labelText: 'Телефон',
                            prefixIcon: const Icon(Icons.phone_outlined),
                          ),
                          onChanged: ref
                              .read(loyaltyCardFormProvider.notifier)
                              .setPhoneNumber,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  CategoryPickerField(
                    selectedCategoryId: state.categoryId,
                    selectedCategoryName: state.categoryName,
                    label: 'Категория',
                    hintText: 'Выберите категорию',
                    filterByType: const [
                      CategoryType.loyaltyCard,
                      CategoryType.mixed,
                    ],
                    onCategorySelected: ref
                        .read(loyaltyCardFormProvider.notifier)
                        .setCategory,
                  ),
                  const SizedBox(height: 12),
                  TagPickerField(
                    selectedTagIds: state.tagIds,
                    selectedTagNames: state.tagNames,
                    label: 'Теги',
                    hintText: 'Выберите теги',
                    filterByType: const [TagType.loyaltyCard, TagType.mixed],
                    onTagsSelected: ref
                        .read(loyaltyCardFormProvider.notifier)
                        .setTags,
                  ),
                  const SizedBox(height: 12),
                  NotePickerField(
                    selectedNoteId: state.noteId,
                    selectedNoteName: null,
                    label: 'Заметка',
                    hintText: 'Выберите заметку',
                    onNoteSelected: (noteId, _) {
                      ref
                          .read(loyaltyCardFormProvider.notifier)
                          .setNoteId(noteId);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descriptionController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: primaryInputDecoration(
                      context,
                      labelText: 'Описание',
                      prefixIcon: const Icon(Icons.notes_outlined),
                    ),
                    onChanged: ref
                        .read(loyaltyCardFormProvider.notifier)
                        .setDescription,
                  ),
                ],
              ),
      ),
    );
  }
}
