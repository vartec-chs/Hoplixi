import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/main_db/core/models/dto/icon_ref_dto.dart';
import 'package:hoplixi/main_db/core/models/enums/entity_types.dart';
import 'package:hoplixi/main_db/old/provider/dao_providers.dart';
import 'package:hoplixi/features/password_generator/password_generator_widget.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/form_close_button.dart';
import 'package:hoplixi/features/password_manager/pickers/category_picker/category_picker.dart';
import 'package:hoplixi/features/password_manager/pickers/note_picker/note_picker_field.dart';
import 'package:hoplixi/features/password_manager/pickers/otp_picker/otp_picker_field.dart';
import 'package:hoplixi/features/password_manager/pickers/tags_picker/tags_picker.dart';
import 'package:hoplixi/generated/l10n/translations.g.dart';
import 'package:hoplixi/routing/paths.dart';
import 'package:hoplixi/shared/custom_fields/widgets/custom_fields_editor.dart';
import 'package:hoplixi/shared/ui/button.dart';
import 'package:hoplixi/shared/ui/text_field.dart';
import 'package:hoplixi/shared/widgets/icon_source_picker_button.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

import '../providers/password_form_provider.dart';

enum _MigrationMenuAction { passwordImport, keepassImport }

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
        title: context.t.dashboard_forms.password_updated,
        description: context.t.dashboard_forms.changes_saved_successfully,
      );
      context.pop(true);
    } else {
      Toaster.error(
        title: context.t.dashboard_forms.save_error,
        description: context.t.dashboard_forms.failed_to_save_password,
      );
    }
  }

  Future<void> _openPasswordGeneratorModal() async {
    final generatedPassword = await WoltModalSheet.show<String>(
      context: context,
      useSafeArea: true,
      useRootNavigator: true,
      pageListBuilder: (modalContext) => [
        WoltModalSheetPage(
          surfaceTintColor: Colors.transparent,
          hasTopBarLayer: true,
          isTopBarLayerAlwaysVisible: true,
          topBarTitle: Text(
            context.t.dashboard_forms.password_generator_title,
            style: Theme.of(
              modalContext,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          leadingNavBarWidget: Padding(
            padding: const EdgeInsets.only(left: 8),
            child: IconButton(
              icon: const Icon(Icons.close),
              tooltip: MaterialLocalizations.of(
                modalContext,
              ).closeButtonTooltip,
              onPressed: () => Navigator.of(modalContext).pop(),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: PasswordGeneratorWidget(
              showRefreshButton: true,
              showSubmitButton: true,
              submitLabel: context.t.dashboard_forms.use_generated_password,
              onPasswordSubmitted: (password) {
                Navigator.of(modalContext).pop(password);
              },
            ),
          ),
        ),
      ],
    );

    if (!mounted || generatedPassword == null || generatedPassword.isEmpty) {
      return;
    }

    _passwordController.text = generatedPassword;
    ref.read(passwordFormProvider.notifier).setPassword(generatedPassword);
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
              ? context.t.dashboard_forms.edit_password
              : context.t.dashboard_forms.new_password,
        ),
        actions: [
          // Выпадающее меню миграции
          PopupMenuButton<_MigrationMenuAction>(
            icon: const Icon(LucideIcons.import),
            tooltip: context.t.dashboard_forms.password_migration,
            onSelected: (action) {
              switch (action) {
                case _MigrationMenuAction.passwordImport:
                  context.go(AppRoutesPaths.passwordImport);
                case _MigrationMenuAction.keepassImport:
                  context.go(AppRoutesPaths.keepassImport);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: _MigrationMenuAction.passwordImport,
                child: Text(context.t.dashboard_forms.password_migration),
              ),
              PopupMenuItem(
                value: _MigrationMenuAction.keepassImport,
                child: Text(context.t.dashboard_forms.keepass_import),
              ),
            ],
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
                              labelText: context.t.dashboard_forms.name_label,
                              hintText:
                                  context.t.dashboard_forms.enter_name_hint,
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
                              labelText:
                                  context.t.dashboard_forms.password_label,
                              hintText:
                                  context.t.dashboard_forms.enter_password_hint,
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
                          const SizedBox(height: 8),

                          Align(
                            alignment: Alignment.centerRight,
                            child: SmoothButton(
                              onPressed: state.isSaving
                                  ? null
                                  : _openPasswordGeneratorModal,
                              icon: const Icon(Icons.password, size: 18),
                              label: context
                                  .t
                                  .dashboard_forms
                                  .generate_password_action,
                              type: SmoothButtonType.text,
                              size: SmoothButtonSize.small,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Логин
                          TextField(
                            controller: _loginController,
                            decoration: primaryInputDecoration(
                              context,
                              labelText: context.t.dashboard_forms.login_label,
                              hintText:
                                  context.t.dashboard_forms.enter_login_hint,
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
                              labelText: context.t.dashboard_forms.email_label,
                              hintText:
                                  context.t.dashboard_forms.enter_email_hint,
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
                            context.t.dashboard_forms.fill_at_least_one_field,
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
                              labelText: context.t.dashboard_forms.url_label,
                              hintText: context.t.dashboard_forms.url_hint,
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
                              labelText: context
                                  .t
                                  .dashboard_forms
                                  .expiration_date_label,
                              hintText: context
                                  .t
                                  .dashboard_forms
                                  .select_date_time_hint,
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
                            label: context.t.dashboard_forms.category_label,
                            hintText:
                                context.t.dashboard_forms.select_category_hint,
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

                          IconSourcePickerButton(
                            iconRef: IconRefDto.fromFields(
                              iconSource: state.iconSource,
                              iconValue: state.iconValue,
                            ),
                            fallbackIcon: Icons.lock,
                            title: 'Иконка записи',
                            onChanged: ref
                                .read(passwordFormProvider.notifier)
                                .setIconRef,
                          ),
                          const SizedBox(height: 16),

                          // Теги
                          TagPickerField(
                            selectedTagIds: state.tagIds,
                            selectedTagNames: state.tagNames,
                            label: context.t.dashboard_forms.tags_label,
                            hintText:
                                context.t.dashboard_forms.select_tags_hint,
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
                              labelText:
                                  context.t.dashboard_forms.description_label,
                              hintText: context
                                  .t
                                  .dashboard_forms
                                  .brief_description_hint,
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
                            hintText:
                                context.t.dashboard_forms.select_note_hint,
                            onNoteSelected: (noteId, noteName) {
                              ref
                                  .read(passwordFormProvider.notifier)
                                  .setNoteId(noteId);
                            },
                          ),
                          const SizedBox(height: 16),

                          // Кастомные поля
                          CustomFieldsEditor(
                            fields: state.customFields,
                            onChanged: (fields) => ref
                                .read(passwordFormProvider.notifier)
                                .setCustomFields(fields),
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
