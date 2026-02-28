import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/theme/constants.dart';
import 'package:hoplixi/features/password_manager/create_store/providers/create_store_form_provider.dart';
import 'package:hoplixi/shared/ui/text_field.dart';

/// Шаг 1: Имя и описание хранилища
class Step1NameAndDescription extends ConsumerStatefulWidget {
  const Step1NameAndDescription({super.key});

  @override
  ConsumerState<Step1NameAndDescription> createState() =>
      _Step1NameAndDescriptionState();
}

class _Step1NameAndDescriptionState
    extends ConsumerState<Step1NameAndDescription> {
  late final TextEditingController _nameController;
  late final FocusNode _nameFocusNode;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    final state = ref.read(createStoreFormProvider);
    _nameController = TextEditingController(text: state.name);
    _descriptionController = TextEditingController(text: state.description);
    _nameFocusNode = FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _nameFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createStoreFormProvider);
    final notifier = ref.read(createStoreFormProvider.notifier);

    return SingleChildScrollView(
      padding: screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Text(
            'Создание хранилища',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Введите имя и опционально описание вашего нового хранилища',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),

          // Поле имени
          TextField(
            controller: _nameController,
            focusNode: _nameFocusNode,

            decoration: primaryInputDecoration(
              context,
              labelText: 'Имя хранилища *',
              hintText: 'Например: Личное, Рабочее',
              errorText: state.nameError,
              prefixIcon: const Icon(Icons.storage),
            ),
            onChanged: notifier.updateName,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 24),

          // Поле описания
          TextField(
            controller: _descriptionController,
            decoration: primaryInputDecoration(
              context,
              labelText: 'Описание (необязательно)',
              hintText: 'Добавьте описание для хранилища',
              prefixIcon: const Icon(Icons.description),
            ),
            onChanged: notifier.updateDescription,
            maxLines: 3,
            maxLength: 500,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 16),

          // Подсказка
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primaryContainer.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Имя должно быть уникальным и содержать от 3 до 50 символов',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
