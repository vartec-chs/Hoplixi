import 'package:card_scanner/card_scanner.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_credit_card/flutter_credit_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/pickers/category_picker/category_picker.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/form_close_button.dart';
import 'package:hoplixi/features/password_manager/pickers/note_picker/note_picker_field.dart';
import 'package:hoplixi/features/password_manager/pickers/tags_picker/tags_picker.dart';
import 'package:hoplixi/main_store/models/enums/entity_types.dart';
import 'package:hoplixi/main_store/provider/dao_providers.dart';
import 'package:hoplixi/shared/ui/text_field.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:universal_platform/universal_platform.dart';

import '../providers/bank_card_form_provider.dart';

/// Экран формы создания/редактирования банковской карты
class BankCardFormScreen extends ConsumerStatefulWidget {
  const BankCardFormScreen({super.key, this.bankCardId});

  /// ID банковской карты для редактирования (null = режим создания)
  final String? bankCardId;

  @override
  ConsumerState<BankCardFormScreen> createState() => _BankCardFormScreenState();
}

class _BankCardFormScreenState extends ConsumerState<BankCardFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _cardholderNameController;
  late final TextEditingController _cardNumberController;
  late final TextEditingController _expiryMonthController;
  late final TextEditingController _expiryYearController;
  late final TextEditingController _cvvController;
  late final TextEditingController _bankNameController;
  late final TextEditingController _accountNumberController;
  late final TextEditingController _routingNumberController;
  late final TextEditingController _descriptionController;

  late final FocusNode _cvvFocusNode;
  String? _noteName;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController();
    _cardholderNameController = TextEditingController();
    _cardNumberController = TextEditingController();
    _expiryMonthController = TextEditingController();
    _expiryYearController = TextEditingController();
    _cvvController = TextEditingController();
    _bankNameController = TextEditingController();
    _accountNumberController = TextEditingController();
    _routingNumberController = TextEditingController();
    _descriptionController = TextEditingController();

    _cvvFocusNode = FocusNode();
    _cvvFocusNode.addListener(_onCvvFocusChange);

    // Инициализация формы
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(bankCardFormProvider.notifier);
      if (widget.bankCardId != null) {
        notifier.initForEdit(widget.bankCardId!);
      } else {
        notifier.initForCreate();
      }
    });
  }

  void _onCvvFocusChange() {
    ref
        .read(bankCardFormProvider.notifier)
        .setCvvFocused(_cvvFocusNode.hasFocus);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cardholderNameController.dispose();
    _cardNumberController.dispose();
    _expiryMonthController.dispose();
    _expiryYearController.dispose();
    _cvvController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _routingNumberController.dispose();
    _descriptionController.dispose();

    _cvvFocusNode.removeListener(_onCvvFocusChange);
    _cvvFocusNode.dispose();

    super.dispose();
  }

  Future<void> _scanCard() async {
    if (!UniversalPlatform.isMobile) return;

    try {
      final cardDetails = await CardScanner.scanCard(
        scanOptions: const CardScanOptions(scanCardHolderName: true),
      );

      if (cardDetails == null || !mounted) return;

      final notifier = ref.read(bankCardFormProvider.notifier);

      if (cardDetails.cardNumber.isNotEmpty) {
        notifier.setCardNumber(cardDetails.cardNumber);
      }

      if (cardDetails.cardHolderName.isNotEmpty) {
        notifier.setCardholderName(cardDetails.cardHolderName);
      }

      if (cardDetails.expiryDate.isNotEmpty) {
        final parts = cardDetails.expiryDate.split('/');
        if (parts.length == 2) {
          notifier.setExpiryMonth(parts[0]);
          final year = parts[1].length == 2 ? '20${parts[1]}' : parts[1];
          notifier.setExpiryYear(year);
        }
      }
    } catch (e) {
      Toaster.error(
        title: 'Ошибка сканирования',
        description: 'Не удалось просканировать карту: $e',
      );
    }
  }

  void _handleSave() async {
    final notifier = ref.read(bankCardFormProvider.notifier);
    final success = await notifier.save();

    if (!mounted) return;

    if (success) {
      Toaster.success(
        title: widget.bankCardId != null ? 'Карта обновлена' : 'Карта создана',
        description: 'Изменения успешно сохранены',
      );
      context.pop(true);
    } else {
      Toaster.error(
        title: 'Ошибка сохранения',
        description: 'Не удалось сохранить карту',
      );
    }
  }

  /// Форматирование номера карты для отображения
  String _formatCardNumber(String number) {
    final cleanNumber = number.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (int i = 0; i < cleanNumber.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(cleanNumber[i]);
    }
    return buffer.toString();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final state = ref.watch(bankCardFormProvider);

    // Загрузка имени заметки
    ref.listen(bankCardFormProvider, (prev, next) {
      if (next.noteId != null && next.noteId != prev?.noteId) {
        _loadNoteName(next.noteId!);
      } else if (next.noteId == null) {
        setState(() => _noteName = null);
      }
    });

    // Синхронизация контроллеров с состоянием при загрузке данных
    if (state.isEditMode && !state.isLoading) {
      if (_nameController.text != state.name) {
        _nameController.text = state.name;
      }
      if (_cardholderNameController.text != state.cardholderName) {
        _cardholderNameController.text = state.cardholderName;
      }
      if (_cardNumberController.text != state.cardNumber) {
        _cardNumberController.text = state.cardNumber;
      }
      if (_expiryMonthController.text != state.expiryMonth) {
        _expiryMonthController.text = state.expiryMonth;
      }
      if (_expiryYearController.text != state.expiryYear) {
        _expiryYearController.text = state.expiryYear;
      }
      if (_cvvController.text != state.cvv) {
        _cvvController.text = state.cvv;
      }
      if (_bankNameController.text != state.bankName) {
        _bankNameController.text = state.bankName;
      }
      if (_accountNumberController.text != state.accountNumber) {
        _accountNumberController.text = state.accountNumber;
      }
      if (_routingNumberController.text != state.routingNumber) {
        _routingNumberController.text = state.routingNumber;
      }
      if (_descriptionController.text != state.description) {
        _descriptionController.text = state.description;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.bankCardId != null
              ? 'Редактировать карту'
              : 'Новая банковская карта',
        ),
        actions: [
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
      ),
      body: SafeArea(
        child: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Expanded(
                    child: Form(
                      key: _formKey,
                      child: ListView(
                        padding: const EdgeInsets.all(12),
                        children: [
                          // Визуализация кредитной карты
                          CreditCardWidget(
                            cardNumber: _formatCardNumber(state.cardNumber),
                            expiryDate: state.formattedExpiryDate,
                            cardHolderName: state.cardholderName.isEmpty
                                ? 'CARD HOLDER'
                                : state.cardholderName.toUpperCase(),
                            cvvCode: state.cvv,
                            showBackView: state.isCvvFocused,
                            onCreditCardWidgetChange: (brand) {},
                            bankName: state.bankName.isEmpty
                                ? null
                                : state.bankName,
                            cardBgColor: colorScheme.primary,
                            obscureCardNumber: false,
                            obscureCardCvv: false,
                            labelCardHolder: 'CARD HOLDER',
                            labelValidThru: 'VALID\nTHRU',
                            isHolderNameVisible: true,
                            height: 200,
                            width: MediaQuery.of(context).size.width,
                            isChipVisible: true,
                            isSwipeGestureEnabled: true,
                            animationDuration: const Duration(
                              milliseconds: 500,
                            ),
                            frontCardBorder: Border.all(
                              color: colorScheme.outline.withOpacity(0.3),
                            ),
                            backCardBorder: Border.all(
                              color: colorScheme.outline.withOpacity(0.3),
                            ),
                            padding: 8,
                          ),

                          const SizedBox(height: 24),

                          // Название карты *
                          TextField(
                            controller: _nameController,
                            decoration: primaryInputDecoration(
                              context,
                              labelText: 'Название карты *',
                              hintText: 'Например: Основная карта',
                              errorText: state.nameError,
                              prefixIcon: Icon(LucideIcons.tag),
                            ),
                            onChanged: (value) {
                              ref
                                  .read(bankCardFormProvider.notifier)
                                  .setName(value);
                            },
                          ),
                          const SizedBox(height: 8),

                          // Имя владельца *
                          TextField(
                            controller: _cardholderNameController,
                            decoration: primaryInputDecoration(
                              context,
                              labelText: 'Имя владельца *',
                              hintText: 'Как на карте',
                              errorText: state.cardholderNameError,
                              prefixIcon: Icon(LucideIcons.user),
                            ),
                            textCapitalization: TextCapitalization.characters,
                            onChanged: (value) {
                              ref
                                  .read(bankCardFormProvider.notifier)
                                  .setCardholderName(value);
                            },
                          ),
                          const SizedBox(height: 8),

                          // Номер карты *
                          TextField(
                            controller: _cardNumberController,
                            decoration: primaryInputDecoration(
                              context,
                              labelText: 'Номер карты *',
                              hintText: '0000 0000 0000 0000',
                              errorText: state.cardNumberError,
                              prefixIcon: Icon(LucideIcons.creditCard),
                              suffixIcon: UniversalPlatform.isMobile
                                  ? IconButton(
                                      icon: const Icon(Icons.camera_alt),
                                      onPressed: _scanCard,
                                      tooltip: 'Сканировать карту',
                                    )
                                  : null,
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(19),
                              _CardNumberInputFormatter(),
                            ],
                            onChanged: (value) {
                              ref
                                  .read(bankCardFormProvider.notifier)
                                  .setCardNumber(value);
                            },
                          ),
                          const SizedBox(height: 8),

                          // Срок действия
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _expiryMonthController,
                                  decoration: primaryInputDecoration(
                                    context,
                                    labelText: 'Месяц *',
                                    hintText: 'MM',
                                    errorText: state.expiryMonthError,
                                    prefixIcon: Icon(LucideIcons.calendar),
                                  ),
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(2),
                                  ],
                                  onChanged: (value) {
                                    ref
                                        .read(bankCardFormProvider.notifier)
                                        .setExpiryMonth(value);
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _expiryYearController,
                                  decoration: primaryInputDecoration(
                                    context,
                                    labelText: 'Год *',
                                    hintText: 'YYYY',
                                    errorText: state.expiryYearError,
                                    prefixIcon: Icon(LucideIcons.calendar),
                                  ),
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(4),
                                  ],
                                  onChanged: (value) {
                                    ref
                                        .read(bankCardFormProvider.notifier)
                                        .setExpiryYear(value);
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _cvvController,
                                  focusNode: _cvvFocusNode,
                                  decoration: primaryInputDecoration(
                                    context,
                                    labelText: 'CVV',
                                    hintText: '***',
                                    errorText: state.cvvError,
                                    prefixIcon: Icon(LucideIcons.shield),
                                  ),
                                  keyboardType: TextInputType.number,
                                  obscureText: true,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(4),
                                  ],
                                  onChanged: (value) {
                                    ref
                                        .read(bankCardFormProvider.notifier)
                                        .setCvv(value);
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          _CardTypeDropdown(
                            value: state.cardType,
                            onChanged: (value) {
                              ref
                                  .read(bankCardFormProvider.notifier)
                                  .setCardType(value);
                            },
                          ),
                          const SizedBox(height: 8),
                          _CardNetworkDropdown(
                            value: state.cardNetwork,
                            onChanged: (value) {
                              ref
                                  .read(bankCardFormProvider.notifier)
                                  .setCardNetwork(value);
                            },
                          ),

                          const SizedBox(height: 8),

                          // Название банка
                          TextField(
                            controller: _bankNameController,
                            decoration: primaryInputDecoration(
                              context,
                              labelText: 'Название банка',
                              hintText: 'Например: Сбербанк',
                              prefixIcon: Icon(LucideIcons.building),
                            ),
                            onChanged: (value) {
                              ref
                                  .read(bankCardFormProvider.notifier)
                                  .setBankName(value);
                            },
                          ),
                          const Divider(height: 32),

                          // Номер счета и Routing number
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _accountNumberController,
                                  decoration: primaryInputDecoration(
                                    context,
                                    labelText: 'Номер счета',
                                    hintText: 'Опционально',
                                    prefixIcon: Icon(LucideIcons.hash),
                                  ),
                                  keyboardType: TextInputType.number,
                                  onChanged: (value) {
                                    ref
                                        .read(bankCardFormProvider.notifier)
                                        .setAccountNumber(value);
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _routingNumberController,
                                  decoration: primaryInputDecoration(
                                    context,
                                    labelText: 'Routing Number',
                                    hintText: 'Опционально',
                                    prefixIcon: Icon(LucideIcons.hash),
                                  ),
                                  keyboardType: TextInputType.number,
                                  onChanged: (value) {
                                    ref
                                        .read(bankCardFormProvider.notifier)
                                        .setRoutingNumber(value);
                                  },
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 32),

                          // Категория
                          CategoryPickerField(
                            selectedCategoryId: state.categoryId,
                            selectedCategoryName: state.categoryName,
                            label: 'Категория',
                            hintText: 'Выберите категорию',
                            filterByType: [
                              CategoryType.bankCard,
                              CategoryType.mixed,
                            ],
                            onCategorySelected: (categoryId, categoryName) {
                              ref
                                  .read(bankCardFormProvider.notifier)
                                  .setCategory(categoryId, categoryName);
                            },
                          ),
                          const SizedBox(height: 8),

                          // Теги
                          TagPickerField(
                            selectedTagIds: state.tagIds,
                            selectedTagNames: state.tagNames,
                            label: 'Теги',
                            hintText: 'Выберите теги',
                            filterByType: [TagType.bankCard, TagType.mixed],
                            onTagsSelected: (tagIds, tagNames) {
                              ref
                                  .read(bankCardFormProvider.notifier)
                                  .setTags(tagIds, tagNames);
                            },
                          ),
                          const SizedBox(height: 8),

                          // Описание
                          TextField(
                            controller: _descriptionController,
                            decoration: primaryInputDecoration(
                              context,
                              labelText: 'Описание',
                              hintText: 'Краткое описание',
                              prefixIcon: Icon(LucideIcons.fileText),
                            ),
                            maxLines: 2,
                            onChanged: (value) {
                              ref
                                  .read(bankCardFormProvider.notifier)
                                  .setDescription(value);
                            },
                          ),
                          const SizedBox(height: 8),

                          // Заметки
                          NotePickerField(
                            selectedNoteId: state.noteId,
                            selectedNoteName: _noteName,
                            onNoteSelected: (noteId, noteName) {
                              ref
                                  .read(bankCardFormProvider.notifier)
                                  .setNoteId(noteId);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Форматтер для ввода номера карты
class _CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(text[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Выпадающий список типа карты
class _CardTypeDropdown extends StatelessWidget {
  const _CardTypeDropdown({required this.value, required this.onChanged});

  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: primaryInputDecoration(context, labelText: 'Тип карты'),
      items: const [
        DropdownMenuItem(value: null, child: Text('Не выбрано')),
        DropdownMenuItem(value: 'debit', child: Text('Дебетовая')),
        DropdownMenuItem(value: 'credit', child: Text('Кредитная')),
        DropdownMenuItem(value: 'prepaid', child: Text('Предоплаченная')),
        DropdownMenuItem(value: 'virtual', child: Text('Виртуальная')),
      ],
      onChanged: onChanged,
    );
  }
}

/// Выпадающий список платежной сети
class _CardNetworkDropdown extends StatelessWidget {
  const _CardNetworkDropdown({required this.value, required this.onChanged});

  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: primaryInputDecoration(context, labelText: 'Платежная сеть'),
      items: const [
        DropdownMenuItem(value: null, child: Text('Не выбрано')),
        DropdownMenuItem(value: 'visa', child: Text('Visa')),
        DropdownMenuItem(value: 'mastercard', child: Text('Mastercard')),
        DropdownMenuItem(value: 'amex', child: Text('American Express')),
        DropdownMenuItem(value: 'discover', child: Text('Discover')),
        DropdownMenuItem(value: 'dinersclub', child: Text('Diners Club')),
        DropdownMenuItem(value: 'jcb', child: Text('JCB')),
        DropdownMenuItem(value: 'unionpay', child: Text('UnionPay')),
        DropdownMenuItem(value: 'other', child: Text('Другое')),
      ],
      onChanged: onChanged,
    );
  }
}
