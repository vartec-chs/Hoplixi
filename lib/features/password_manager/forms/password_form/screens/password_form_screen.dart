import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/category_manager/features/category_picker/category_picker.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/form_close_button.dart';
import 'package:hoplixi/features/password_manager/tags_manager/features/tags_picker/tags_picker.dart';
import 'package:hoplixi/main_store/models/enums/entity_types.dart';
import 'package:hoplixi/shared/ui/text_field.dart';

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
  late final TextEditingController _notesController;

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
    _notesController = TextEditingController();

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
    _notesController.dispose();
    super.dispose();
  }

  void _handleSave() async {
    final notifier = ref.read(passwordFormProvider.notifier);
    final success = await notifier.save();

    if (!mounted) return;

    if (success) {
      Toaster.success(
        title: widget.passwordId != null ? 'Пароль обновлен' : 'Пароль создан',
        description: 'Изменения успешно сохранены',
      );
      context.pop(true);
    } else {
      Toaster.error(
        title: 'Ошибка сохранения',
        description: 'Не удалось сохранить пароль',
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
      if (_passwordController.text != state.password)
        _passwordController.text = state.password;
      if (_loginController.text != state.login)
        _loginController.text = state.login;
      if (_emailController.text != state.email)
        _emailController.text = state.email;
      if (_urlController.text != state.url) _urlController.text = state.url;
      if (_descriptionController.text != state.description)
        _descriptionController.text = state.description;
      if (_notesController.text != state.notes)
        _notesController.text = state.notes;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.passwordId != null ? 'Редактировать пароль' : 'Новый пароль',
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

      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.all(12),
                      children: [
                        // Название *
                        TextField(
                          controller: _nameController,
                          decoration: primaryInputDecoration(
                            context,
                            labelText: 'Название *',
                            hintText: 'Введите название',
                            errorText: state.nameError,
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
                            labelText: 'Пароль *',
                            hintText: 'Введите пароль',
                            errorText: state.passwordError,
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
                            labelText: 'Логин',
                            hintText: 'Введите логин',
                            errorText: state.loginError,
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
                            labelText: 'Email',
                            hintText: 'Введите email',
                            errorText: state.emailError,
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
                          '* Заполните хотя бы одно поле: Логин или Email',
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
                            labelText: 'URL',
                            hintText: 'https://example.com',
                            errorText: state.urlError,
                          ),
                          keyboardType: TextInputType.url,
                          onChanged: (value) {
                            ref
                                .read(passwordFormProvider.notifier)
                                .setUrl(value);
                          },
                        ),
                        const SizedBox(height: 16),

                        // Категория
                        CategoryPickerField(
                          selectedCategoryId: state.categoryId,
                          selectedCategoryName: state.categoryName,
                          label: 'Категория',
                          hintText: 'Выберите категорию',
                          filterByType: [CategoryType.password],
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
                          label: 'Теги',
                          hintText: 'Выберите теги',
                          filterByType: TagType.password,
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
                            labelText: 'Описание',
                            hintText: 'Краткое описание',
                          ),
                          maxLines: 2,
                          onChanged: (value) {
                            ref
                                .read(passwordFormProvider.notifier)
                                .setDescription(value);
                          },
                        ),
                        const SizedBox(height: 16),

                        // Заметки
                        TextField(
                          controller: _notesController,
                          decoration: primaryInputDecoration(
                            context,
                            labelText: 'Заметки',
                            hintText: 'Дополнительные заметки',
                          ),
                          maxLines: 4,
                          onChanged: (value) {
                            ref
                                .read(passwordFormProvider.notifier)
                                .setNotes(value);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
