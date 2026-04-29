import 'package:flutter/material.dart';
import 'package:hoplixi/features/password_generator/models/password_generator_profile.dart';
import 'package:hoplixi/shared/ui/button.dart';
import 'package:hoplixi/shared/ui/text_field.dart';

class ProfilesSection extends StatelessWidget {
  const ProfilesSection({
    required this.controller,
    required this.profiles,
    required this.selectedProfileId,
    required this.isLoading,
    required this.isSaving,
    required this.isDeleting,
    required this.onProfileSelected,
    required this.onSavePressed,
    required this.onDeletePressed,
    required this.onCreateNewPressed,
    super.key,
  });

  final TextEditingController controller;
  final List<PasswordGeneratorProfile> profiles;
  final String? selectedProfileId;
  final bool isLoading;
  final bool isSaving;
  final bool isDeleting;
  final ValueChanged<String?> onProfileSelected;
  final VoidCallback onSavePressed;
  final VoidCallback onDeletePressed;
  final VoidCallback onCreateNewPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canSave =
        !isLoading && !isSaving && controller.text.trim().isNotEmpty;
    final canDelete = !isLoading && !isDeleting && selectedProfileId != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Профили генератора',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String?>(
          value: selectedProfileId,
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('Новый профиль'),
            ),
            ...profiles.map(
              (profile) => DropdownMenuItem<String?>(
                value: profile.id,
                child: Text(profile.name),
              ),
            ),
          ],
          onChanged: isLoading ? null : onProfileSelected,
          decoration: primaryInputDecoration(
            context,
            labelText: 'Сохранённый профиль',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: controller,
          decoration: primaryInputDecoration(
            context,
            labelText: 'Имя профиля',
            suffixIcon: selectedProfileId == null
                ? null
                : IconButton(
                    tooltip: 'Создать новый профиль',
                    onPressed: onCreateNewPressed,
                    icon: const Icon(Icons.add_circle_outline),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: SmoothButton(
                onPressed: canSave ? onSavePressed : null,
                loading: isSaving,
                icon: const Icon(Icons.save_outlined, size: 18),
                label: selectedProfileId == null
                    ? 'Сохранить профиль'
                    : 'Обновить профиль',
                type: SmoothButtonType.outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SmoothButton(
                onPressed: canDelete ? onDeletePressed : null,
                loading: isDeleting,
                icon: const Icon(Icons.delete_outline, size: 18),
                label: 'Удалить',
                variant: SmoothButtonVariant.error,
                type: SmoothButtonType.outlined,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
