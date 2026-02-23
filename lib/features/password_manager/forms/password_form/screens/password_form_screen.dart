import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/form_close_button.dart';
import 'package:hoplixi/features/password_manager/pickers/category_picker/category_picker.dart';
import 'package:hoplixi/features/password_manager/pickers/note_picker/note_picker_field.dart';
import 'package:hoplixi/features/password_manager/pickers/otp_picker/otp_picker_field.dart';
import 'package:hoplixi/features/password_manager/pickers/tags_picker/tags_picker.dart';
import 'package:hoplixi/generated/l10n.dart';
import 'package:hoplixi/main_store/models/enums/entity_types.dart';
import 'package:hoplixi/main_store/provider/dao_providers.dart';
import 'package:hoplixi/routing/paths.dart';
import 'package:hoplixi/shared/ui/text_field.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../providers/password_form_provider.dart';

/// Экран формы создания/редактирования пароля
class PasswordFormScreen extends ConsumerStatefulWidget {
  const PasswordFormScreen({super.key, this.passwordId});

  /// ID пароля для редактирования (null = режим создания)
  final String? passwordId;

  @override
  ConsumerState<PasswordFormScreen> createState() => _PasswordFormScreenState();
}

class _PasswordFormScreenState extends ConsumerState<PasswordFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _passwordController;
  late final TextEditingController _loginController;
  late final TextEditingController _emailController;
  late final TextEditingController _urlController;
  late final TextEditingController _descriptionController;

  String? _noteName;
  String? _otpName;

  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController();
    _passwordController = TextEditingController();
    _loginController = TextEditingController();
    _emailController = TextEditingController();
    _urlController = TextEditingController();
    _descriptionController = TextEditingController();

    // Инициализация формы
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(passwordFormProvider.notifier);
      if (widget.passwordId != null) {
        notifier.initForEdit(widget.passwordId!);
      } else {
        notifier.initForCreate();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _loginController.dispose();
    _emailController.dispose();
    _urlController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadNoteName(String noteId) async {
    final dao = await ref.read(noteDaoProvider.future);
    final record = await dao.getById(noteId);
    if (mounted) {
      setState(() => _noteName = record?.$1.name);
    }
  }

  Future<void> _loadOtpName(String otpId) async {
    final dao = await ref.read(otpDaoProvider.future);
    final record = await dao.getById(otpId);
    if (mounted && record != null) {
      final (vault, otp) = record;
      setState(() => _otpName = otp.issuer ?? otp.accountName ?? vault.name);
    }
  }

  void _handleSave() async {
    final notifier = ref.read(passwordFormProvider.notifier);
    final success = await notifier.save();

    if (!mounted) return;

    if (success) {
      Toaster.success(
        title: S.of(context).passwordUpdated,
        description: S.of(context).changesSavedSuccessfully,
      );
      context.pop(true);
    } else {
      Toaster.error(
        title: S.of(context).saveError,
        description: S.of(context).failedToSavePassword,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(passwordFormProvider);

    // Синхронизация контроллеров с состоянием при загрузке данных
    if (state.isEditMode && !state.isLoading) {
      if (_nameController.text != state.name) _nameController.text = state.name;
      if (_passwordController.text != state.password) {
        _passwordController.text = state.password;
      }
      if (_loginController.text != state.login) {
        _loginController.text = state.login;
      }
      if (_emailController.text != state.email) {
        _emailController.text = state.email;
      }
      if (_urlController.text != state.url) _urlController.text = state.url;
      if (_descriptionController.text != state.description) {
        _descriptionController.text = state.description;
      }
    }

    // Загрузка имени заметки
    ref.listen(passwordFormProvider, (prev, next) {
      if (next.noteId != null && next.noteId != prev?.noteId) {
        _loadNoteName(next.noteId!);
      } else if (next.noteId == null) {
        setState(() => _noteName = null);
      }
    });

    // Загрузка имени OTP
    ref.listen(passwordFormProvider, (prev, next) {
      if (next.otpId != null && next.otpId != prev?.otpId) {
        _loadOtpName(next.otpId!);
      } else if (next.otpId == null) {
        setState(() => _otpName = null);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.passwordId != null
              ? S.of(context).editPassword
              : S.of(context).newPassword,
        ),
        actions: [
          // Кнопка миграции паролей
          IconButton(
            icon: const Icon(LucideIcons.import),
            tooltip: S.of(context).passwordMigration,
            onPressed: () => context.go(AppRoutesPaths.passwordMigrate),
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
                        padding: formPadding,
                        children: [
                          // Название *
                          TextField(
                            controller: _nameController,
                            decoration: primaryInputDecoration(
                              context,
                              labelText: S.of(context).nameLabel,
                              hintText: S.of(context).enterNameHint,
                              errorText: state.nameError,
                              prefixIcon: const Icon(LucideIcons.tag),
                            ),
                            onChanged: (value) {
                              ref
                                  .read(passwordFormProvider.notifier)
                                  .setName(value);
                            },
                          ),
                          const SizedBox(height: 16),

                          // Пароль *
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: primaryInputDecoration(
                              context,
                              labelText: S.of(context).passwordLabel,
                              hintText: S.of(context).enterPasswordHint,
                              errorText: state.passwordError,
                              prefixIcon: const Icon(LucideIcons.lock),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            onChanged: (value) {
                              ref
                                  .read(passwordFormProvider.notifier)
                                  .setPassword(value);
                            },
                          ),
                          const SizedBox(height: 16),

                          // Логин
                          TextField(
                            controller: _loginController,
                            decoration: primaryInputDecoration(
                              context,
                              labelText: S.of(context).loginLabel,
                              hintText: S.of(context).enterLoginHint,
                              errorText: state.loginError,
                              prefixIcon: const Icon(LucideIcons.user),
                            ),
                            onChanged: (value) {
                              ref
                                  .read(passwordFormProvider.notifier)
                                  .setLogin(value);
                            },
                          ),
                          const SizedBox(height: 16),

                          // Email
                          TextField(
                            controller: _emailController,
                            decoration: primaryInputDecoration(
                              context,
                              labelText: S.of(context).emailLabel,
                              hintText: S.of(context).enterEmailHint,
                              errorText: state.emailError,
                              prefixIcon: const Icon(LucideIcons.mail),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            onChanged: (value) {
                              ref
                                  .read(passwordFormProvider.notifier)
                                  .setEmail(value);
                            },
                          ),
                          const SizedBox(height: 8),

                          // Подсказка
                          Text(
                            S.of(context).fillAtLeastOneField,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // URL
                          TextField(
                            controller: _urlController,
                            decoration: primaryInputDecoration(
                              context,
                              labelText: S.of(context).urlLabel,
                              hintText: S.of(context).urlHint,
                              errorText: state.urlError,
                              prefixIcon: const Icon(LucideIcons.globe),
                            ),
                            keyboardType: TextInputType.url,
                            onChanged: (value) {
                              ref
                                  .read(passwordFormProvider.notifier)
                                  .setUrl(value);
                            },
                          ),
                          const SizedBox(height: 16),

                          // Срок действия
                          TextField(
                            controller: TextEditingController(
                              text: state.expireAt != null
                                  ? DateFormat(
                                      'dd.MM.yyyy HH:mm',
                                    ).format(state.expireAt!)
                                  : '',
                            ),
                            readOnly: true,
                            decoration: primaryInputDecoration(
                              context,
                              labelText: S.of(context).expirationDateLabel,
                              hintText: S.of(context).selectDateTimeHint,
                              prefixIcon: const Icon(LucideIcons.calendar),
                              suffixIcon: state.expireAt != null
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 20),
                                      onPressed: () {
                                        ref
                                            .read(passwordFormProvider.notifier)
                                            .setExpireAt(null);
                                      },
                                    )
                                  : null,
                            ),
                            onTap: () async {
                              final initialDate =
                                  state.expireAt ?? DateTime.now();
                              final date = await showDatePicker(
                                context: context,
                                initialDate: initialDate,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(DateTime.now().year + 150),
                              );
                              if (date != null && context.mounted) {
                                final time = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.fromDateTime(
                                    initialDate,
                                  ),
                                );
                                if (time != null) {
                                  final finalDateTime = DateTime(
                                    date.year,
                                    date.month,
                                    date.day,
                                    time.hour,
                                    time.minute,
                                  );
                                  ref
                                      .read(passwordFormProvider.notifier)
                                      .setExpireAt(finalDateTime);
                                }
                              }
                            },
                          ),
                          const SizedBox(height: 16),

                          // Категория
                          CategoryPickerField(
                            selectedCategoryId: state.categoryId,
                            selectedCategoryName: state.categoryName,
                            label: S.of(context).categoryLabel,
                            hintText: S.of(context).selectCategoryHint,
                            filterByType: [
                              CategoryType.password,
                              CategoryType.mixed,
                            ],
                            onCategorySelected: (categoryId, categoryName) {
                              ref
                                  .read(passwordFormProvider.notifier)
                                  .setCategory(categoryId, categoryName);
                            },
                          ),
                          const SizedBox(height: 16),

                          // Теги
                          TagPickerField(
                            selectedTagIds: state.tagIds,
                            selectedTagNames: state.tagNames,
                            label: S.of(context).tagsLabel,
                            hintText: S.of(context).selectTagsHint,
                            filterByType: [TagType.password, TagType.mixed],
                            onTagsSelected: (tagIds, tagNames) {
                              ref
                                  .read(passwordFormProvider.notifier)
                                  .setTags(tagIds, tagNames);
                            },
                          ),
                          const SizedBox(height: 16),

                          // Описание
                          TextField(
                            controller: _descriptionController,
                            decoration: primaryInputDecoration(
                              context,
                              labelText: S.of(context).descriptionLabel,
                              hintText: S.of(context).briefDescriptionHint,
                              prefixIcon: const Icon(LucideIcons.fileText),
                            ),
                            maxLines: 2,
                            onChanged: (value) {
                              ref
                                  .read(passwordFormProvider.notifier)
                                  .setDescription(value);
                            },
                          ),
                          const SizedBox(height: 16),

                          // OTP
                          OtpPickerField(
                            selectedOtpId: state.otpId,
                            selectedOtpName: _otpName,
                            onOtpSelected: (otpId, otpName) {
                              ref
                                  .read(passwordFormProvider.notifier)
                                  .setOtp(otpId, otpName);
                            },
                          ),
                          const SizedBox(height: 16),

                          // Заметка
                          NotePickerField(
                            selectedNoteId: state.noteId,
                            selectedNoteName: _noteName,
                            hintText: S.of(context).selectNoteHint,
                            onNoteSelected: (noteId, noteName) {
                              ref
                                  .read(passwordFormProvider.notifier)
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
