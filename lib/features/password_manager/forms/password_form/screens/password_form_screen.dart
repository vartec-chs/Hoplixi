import 'package:hoplixi/shared/ui/background_utils.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/onboarding/application/showcase_controller.dart';
import 'package:hoplixi/features/onboarding/domain/app_guide_id.dart';
import 'package:hoplixi/features/onboarding/domain/guide_start_mode.dart';
import 'package:hoplixi/features/onboarding/presentation/showcase_help_button.dart';
import 'package:hoplixi/features/onboarding/presentation/showcase_registration.dart';
import 'package:hoplixi/features/password_generator/password_generator_widget.dart';
import 'package:hoplixi/features/password_manager/forms/form_close_button.dart';
import 'package:hoplixi/features/password_manager/forms/password_form/models/password_form_state.dart';
import 'package:hoplixi/features/password_manager/pickers/category_picker/category_picker.dart';
import 'package:hoplixi/features/password_manager/pickers/note_picker/note_picker_field.dart';
import 'package:hoplixi/features/password_manager/pickers/otp_picker/otp_picker_field.dart';
import 'package:hoplixi/features/password_manager/pickers/tags_picker/tags_picker.dart';
import 'package:hoplixi/features/password_manager/shared/widgets/custom_fields/widgets/custom_fields_editor.dart';
import 'package:hoplixi/features/password_manager/shared/widgets/email_autocomplete_field/email_autocomplete_field.dart';
import 'package:hoplixi/features/password_manager/shared/widgets/login_autocomplete_field/login_autocomplete_field.dart';
import 'package:hoplixi/generated/l10n/translations.g.dart';
import 'package:hoplixi/main_db/core/old/models/dto/icon_ref_dto.dart';
import 'package:hoplixi/main_db/core/models/enums/entity_types.dart';
import 'package:hoplixi/main_db/providers/other/dao_providers.dart';
import 'package:hoplixi/routing/paths.dart';
import 'package:hoplixi/shared/ui/button.dart';
import 'package:hoplixi/shared/ui/text_field.dart';
import 'package:hoplixi/shared/widgets/icon_source_picker_button.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:showcaseview/showcaseview.dart';
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

const _passwordAddShowcaseScope = 'password_add_guide';

class _PasswordFormScreenState extends ConsumerState<PasswordFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _passwordController;
  late final TextEditingController _loginController;
  late final TextEditingController _emailController;
  late final TextEditingController _urlController;
  late final TextEditingController _descriptionController;
  late final PasswordAddGuideKeys _guideKeys;

  String? _noteName;
  String? _otpName;

  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();

    _guideKeys = PasswordAddGuideKeys();
    registerAppGuideShowcase(
      scope: _passwordAddShowcaseScope,
      enableAutoScroll: true,
      semanticEnable: true,
      autoPlay: false,
      onFinish: _markPasswordAddGuideSeen,
      onDismiss: (_) => _markPasswordAddGuideSeen(),
    );
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

  void _schedulePasswordAddGuideStart(PasswordFormState state) {
    if (widget.passwordId != null || state.isLoading || _guideKeys.scheduled) {
      return;
    }

    _guideKeys.scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(_startPasswordAddGuide(GuideStartMode.auto));
    });
  }

  Future<void> _startPasswordAddGuide(GuideStartMode mode) async {
    final controller = ref.read(showcaseControllerProvider.notifier);
    if (mode == GuideStartMode.auto &&
        !await controller.shouldAutoStart(AppGuideId.passwordAdd)) {
      return;
    }
    if (!mounted) {
      return;
    }

    final keys = _guideKeys.sequence
        .where((key) => key.currentContext != null)
        .toList(growable: false);
    if (keys.isEmpty) {
      return;
    }

    final showcaseView = ShowcaseView.getNamed(_passwordAddShowcaseScope);
    if (showcaseView.isShowcaseRunning) {
      return;
    }

    showcaseView.startShowCase(keys, delay: const Duration(milliseconds: 250));
  }

  void _markPasswordAddGuideSeen() {
    if (!mounted) {
      return;
    }
    unawaited(
      ref
          .read(showcaseControllerProvider.notifier)
          .markSeen(AppGuideId.passwordAdd),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _loginController.dispose();
    _emailController.dispose();
    _urlController.dispose();
    _descriptionController.dispose();
    ShowcaseView.getNamed(_passwordAddShowcaseScope).unregister();
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
    _schedulePasswordAddGuideStart(state);

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
      backgroundColor: getScreenBackgroundColor(context, ref),
      appBar: AppBar(
        title: Text(
          widget.passwordId != null
              ? context.t.dashboard_forms.edit_password
              : context.t.dashboard_forms.new_password,
        ),
        actions: [
          if (widget.passwordId == null)
            ShowcaseHelpButton(
              keys: _guideKeys.sequence,
              scope: _passwordAddShowcaseScope,
            ),
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
            Showcase(
              key: _guideKeys.saveButton,
              scope: _passwordAddShowcaseScope,
              title: 'Сохранить пароль',
              description:
                  'После заполнения обязательных данных нажмите эту кнопку, чтобы сохранить запись.',
              child: IconButton(
                icon: const Icon(Icons.save),
                onPressed: _handleSave,
              ),
            ),
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
                          Showcase(
                            key: _guideKeys.title,
                            scope: _passwordAddShowcaseScope,
                            title: 'Название записи',
                            description:
                                'Укажите название сервиса или сайта, чтобы запись было легко найти.',
                            child: TextField(
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
                          ),
                          const SizedBox(height: 16),

                          // Пароль *
                          Showcase(
                            key: _guideKeys.password,
                            scope: _passwordAddShowcaseScope,
                            title: 'Пароль',
                            description:
                                'Введите пароль вручную или сгенерируйте новый безопасный пароль.',
                            child: TextField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: primaryInputDecoration(
                                context,
                                labelText:
                                    context.t.dashboard_forms.password_label,
                                hintText: context
                                    .t
                                    .dashboard_forms
                                    .enter_password_hint,
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
                          ),
                          const SizedBox(height: 8),

                          Align(
                            alignment: Alignment.centerRight,
                            child: Showcase(
                              key: _guideKeys.generator,
                              scope: _passwordAddShowcaseScope,
                              title: 'Генератор пароля',
                              description:
                                  'Откройте генератор, чтобы создать пароль и сразу подставить его в поле.',
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
                          ),
                          const SizedBox(height: 16),

                          // Логин
                          Showcase(
                            key: _guideKeys.username,
                            scope: _passwordAddShowcaseScope,
                            title: 'Логин',
                            description:
                                'Добавьте имя пользователя или логин для этой записи.',
                            child: LoginAutocompleteField(
                              controller: _loginController,
                              labelText: context.t.dashboard_forms.login_label,
                              hintText:
                                  context.t.dashboard_forms.enter_login_hint,
                              errorText: state.loginError,
                              prefixIcon: const Icon(LucideIcons.user),
                              onChanged: (value) {
                                ref
                                    .read(passwordFormProvider.notifier)
                                    .setLogin(value);
                              },
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Email
                          EmailAutocompleteField(
                            controller: _emailController,
                            labelText: context.t.dashboard_forms.email_label,
                            hintText:
                                context.t.dashboard_forms.enter_email_hint,
                            errorText: state.emailError,
                            prefixIcon: const Icon(LucideIcons.mail),
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

class PasswordAddGuideKeys {
  final title = GlobalKey();
  final username = GlobalKey();
  final password = GlobalKey();
  final generator = GlobalKey();
  final saveButton = GlobalKey();

  bool scheduled = false;

  List<GlobalKey> get sequence => [
    title,
    username,
    password,
    generator,
    saveButton,
  ];
}
