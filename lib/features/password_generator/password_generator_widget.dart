import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_generator/models/password_generator_profile.dart';
import 'package:hoplixi/features/password_generator/services/password_generator_profile_service.dart';
import 'package:hoplixi/shared/ui/button.dart';
import 'package:hoplixi/shared/ui/password_strength_indicator.dart';
import 'package:hoplixi/shared/ui/text_field.dart';

/// Кастомизируемый генератор паролей.
///
/// Может использоваться как внутри экранов,
/// так и в модальных окнах (например, WoltModalSheet).
class PasswordGeneratorWidget extends StatefulWidget {
  const PasswordGeneratorWidget({
    super.key,
    this.padding = const EdgeInsets.all(12),
    this.initialLength = 16,
    this.minLength = 4,
    this.maxLength = 128,
    this.initialUseLowercase = true,
    this.initialUseUppercase = true,
    this.initialUseDigits = true,
    this.initialUseSpecial = true,
    this.emptyPlaceholder = 'Выберите параметры...',
    this.refreshLabel = 'Обновить',
    this.submitLabel = 'Использовать',
    this.showRefreshButton = true,
    this.showSubmitButton = true,
    this.canSubmit = true,
    this.onPasswordChanged,
    this.onPasswordSubmitted,
    this.profileService,
  });

  final EdgeInsetsGeometry padding;
  final double initialLength;
  final int minLength;
  final int maxLength;
  final bool initialUseLowercase;
  final bool initialUseUppercase;
  final bool initialUseDigits;
  final bool initialUseSpecial;
  final String emptyPlaceholder;
  final String refreshLabel;
  final String submitLabel;
  final bool showRefreshButton;
  final bool showSubmitButton;
  final bool canSubmit;
  final ValueChanged<String>? onPasswordChanged;
  final ValueChanged<String>? onPasswordSubmitted;
  final PasswordGeneratorProfileService? profileService;

  @override
  State<PasswordGeneratorWidget> createState() =>
      _PasswordGeneratorWidgetState();
}

class _PasswordGeneratorWidgetState extends State<PasswordGeneratorWidget> {
  static const String _lowercase = 'abcdefghijklmnopqrstuvwxyz';
  static const String _uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const String _digits = '0123456789';
  static const String _special = '!@#\$%^&*()_+-=[]{}|;:,.<>?';
  static const List<int> _batchCountOptions = [3, 5, 10, 20];

  late final PasswordGeneratorProfileService _profileService;
  late final TextEditingController _profileNameController;

  late double _length;
  late bool _useLowercase;
  late bool _useUppercase;
  late bool _useDigits;
  late bool _useSpecial;

  String _generatedPassword = '';
  List<String> _batchPasswords = const [];
  bool _copied = false;
  int? _copiedBatchIndex;
  bool _isLoadingProfiles = true;
  bool _isSavingProfile = false;
  bool _isDeletingProfile = false;
  int _batchSize = 5;
  List<PasswordGeneratorProfile> _profiles = const [];
  String? _selectedProfileId;

  @override
  void initState() {
    super.initState();
    _profileService =
        widget.profileService ?? PasswordGeneratorProfileService();
    _profileNameController = TextEditingController();
    _profileNameController.addListener(_handleProfileNameChanged);
    _length = widget.initialLength.clamp(
      widget.minLength.toDouble(),
      widget.maxLength.toDouble(),
    );
    _useLowercase = widget.initialUseLowercase;
    _useUppercase = widget.initialUseUppercase;
    _useDigits = widget.initialUseDigits;
    _useSpecial = widget.initialUseSpecial;
    _generate();
    unawaited(_loadProfiles());
  }

  @override
  void dispose() {
    _profileNameController.removeListener(_handleProfileNameChanged);
    _profileNameController.dispose();
    super.dispose();
  }

  void _handleProfileNameChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _generate() {
    final chars = _buildCharacterPool();
    if (chars.isEmpty) {
      setState(() {
        _generatedPassword = '';
        _copied = false;
      });
      widget.onPasswordChanged?.call('');
      return;
    }

    final password = _generatePasswordFromPool(chars, Random.secure());

    setState(() {
      _generatedPassword = password;
      _copied = false;
    });
    widget.onPasswordChanged?.call(password);
  }

  String _buildCharacterPool() {
    final buffer = StringBuffer();
    if (_useLowercase) {
      buffer.write(_lowercase);
    }
    if (_useUppercase) {
      buffer.write(_uppercase);
    }
    if (_useDigits) {
      buffer.write(_digits);
    }
    if (_useSpecial) {
      buffer.write(_special);
    }
    return buffer.toString();
  }

  String _generatePasswordFromPool(String chars, Random random) {
    return List.generate(
      _length.round(),
      (_) => chars[random.nextInt(chars.length)],
    ).join();
  }

  Future<void> _copyToClipboard() async {
    if (_generatedPassword.isEmpty) return;

    await Clipboard.setData(ClipboardData(text: _generatedPassword));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _copied = false);
      }
    });
  }

  void _generateBatchPasswords() {
    final chars = _buildCharacterPool();
    if (chars.isEmpty) {
      Toaster.warning(
        title: 'Генератор',
        description: 'Выберите хотя бы один набор символов.',
      );
      return;
    }

    final random = Random.secure();
    final passwords = List.generate(
      _batchSize,
      (_) => _generatePasswordFromPool(chars, random),
      growable: false,
    );

    setState(() {
      _batchPasswords = passwords;
      _copiedBatchIndex = null;
    });
  }

  Future<void> _copyBatchPassword(int index) async {
    if (index < 0 || index >= _batchPasswords.length) {
      return;
    }

    await Clipboard.setData(ClipboardData(text: _batchPasswords[index]));
    if (!mounted) {
      return;
    }

    setState(() => _copiedBatchIndex = index);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && _copiedBatchIndex == index) {
        setState(() => _copiedBatchIndex = null);
      }
    });
  }

  Future<void> _loadProfiles() async {
    setState(() => _isLoadingProfiles = true);
    final document = await _profileService.loadDocument();
    if (!mounted) {
      return;
    }

    setState(() {
      _profiles = document.profiles;
      _selectedProfileId = document.lastSelectedProfileId;
      _isLoadingProfiles = false;
    });

    final selectedProfile = _findProfileById(document.lastSelectedProfileId);
    if (selectedProfile != null) {
      _applyProfile(selectedProfile);
      return;
    }

    _profileNameController.text = '';
  }

  PasswordGeneratorProfile? _findProfileById(String? profileId) {
    if (profileId == null) {
      return null;
    }
    for (final profile in _profiles) {
      if (profile.id == profileId) {
        return profile;
      }
    }
    return null;
  }

  void _applyProfile(PasswordGeneratorProfile profile) {
    setState(() {
      _selectedProfileId = profile.id;
      _profileNameController.text = profile.name;
      _length = profile.length
          .clamp(widget.minLength, widget.maxLength)
          .toDouble();
      _useLowercase = profile.useLowercase;
      _useUppercase = profile.useUppercase;
      _useDigits = profile.useDigits;
      _useSpecial = profile.useSpecial;
    });
    unawaited(_profileService.rememberSelectedProfile(profile.id));
    _generate();
  }

  Future<void> _saveProfile() async {
    final profileName = _profileNameController.text.trim();
    if (profileName.isEmpty) {
      Toaster.warning(
        title: 'Профиль',
        description: 'Укажите имя профиля для сохранения.',
      );
      return;
    }

    setState(() => _isSavingProfile = true);
    try {
      final document = await _profileService.saveProfile(
        profileId: _selectedProfileId,
        name: profileName,
        length: _length.round(),
        useLowercase: _useLowercase,
        useUppercase: _useUppercase,
        useDigits: _useDigits,
        useSpecial: _useSpecial,
      );
      if (!mounted) {
        return;
      }

      setState(() {
        _profiles = document.profiles;
        _selectedProfileId = document.lastSelectedProfileId;
      });

      final savedProfile = _findProfileById(document.lastSelectedProfileId);
      _profileNameController.text = savedProfile?.name ?? profileName;
      Toaster.success(
        title: 'Профиль сохранён',
        description: 'Настройки генератора сохранены в профиль.',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      Toaster.error(
        title: 'Ошибка',
        description: 'Не удалось сохранить профиль: $error',
      );
    } finally {
      if (mounted) {
        setState(() => _isSavingProfile = false);
      }
    }
  }

  Future<void> _deleteProfile() async {
    final selectedProfile = _findProfileById(_selectedProfileId);
    if (selectedProfile == null) {
      return;
    }

    setState(() => _isDeletingProfile = true);
    try {
      final document = await _profileService.deleteProfile(selectedProfile.id);
      if (!mounted) {
        return;
      }

      setState(() {
        _profiles = document.profiles;
        _selectedProfileId = document.lastSelectedProfileId;
      });
      _profileNameController.clear();
      Toaster.success(
        title: 'Профиль удалён',
        description: 'Профиль "${selectedProfile.name}" удалён.',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      Toaster.error(
        title: 'Ошибка',
        description: 'Не удалось удалить профиль: $error',
      );
    } finally {
      if (mounted) {
        setState(() => _isDeletingProfile = false);
      }
    }
  }

  void _startNewProfile() {
    setState(() => _selectedProfileId = null);
    _profileNameController.clear();
    unawaited(_profileService.rememberSelectedProfile(null));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PasswordField(
            password: _generatedPassword,
            copied: _copied,
            placeholder: widget.emptyPlaceholder,
            onRegenerate: widget.showRefreshButton ? _generate : null,
            regenerateTooltip: widget.refreshLabel,
            onCopy: _copyToClipboard,
          ),

          const SizedBox(height: 16),

          PasswordStrengthIndicator(
            password: _generatedPassword,
            showNumericScore: true,
          ),

          const SizedBox(height: 24),

          _LengthSlider(
            length: _length,
            minLength: widget.minLength,
            maxLength: widget.maxLength,
            onChanged: (value) {
              setState(() => _length = value);
              _generate();
            },
          ),

          const SizedBox(height: 16),

          _BatchPasswordsSection(
            selectedCount: _batchSize,
            countOptions: _batchCountOptions,
            passwords: _batchPasswords,
            copiedIndex: _copiedBatchIndex,
            onCountChanged: (value) {
              setState(() => _batchSize = value);
            },
            onGeneratePressed: _generateBatchPasswords,
            onCopyPressed: _copyBatchPassword,
          ),

          const SizedBox(height: 24),

          _ProfilesSection(
            controller: _profileNameController,
            profiles: _profiles,
            selectedProfileId: _selectedProfileId,
            isLoading: _isLoadingProfiles,
            isSaving: _isSavingProfile,
            isDeleting: _isDeletingProfile,
            onProfileSelected: (profileId) {
              if (profileId == null) {
                _startNewProfile();
                return;
              }

              final profile = _findProfileById(profileId);
              if (profile == null) {
                return;
              }
              _applyProfile(profile);
            },
            onSavePressed: _saveProfile,
            onDeletePressed: _deleteProfile,
            onCreateNewPressed: _startNewProfile,
          ),

          const SizedBox(height: 8),

          _OptionTile(
            label: 'Строчные (a-z)',
            value: _useLowercase,
            onChanged: (value) {
              setState(() => _useLowercase = value);
              _generate();
            },
          ),
          _OptionTile(
            label: 'Прописные (A-Z)',
            value: _useUppercase,
            onChanged: (value) {
              setState(() => _useUppercase = value);
              _generate();
            },
          ),
          _OptionTile(
            label: 'Цифры (0-9)',
            value: _useDigits,
            onChanged: (value) {
              setState(() => _useDigits = value);
              _generate();
            },
          ),
          _OptionTile(
            label: 'Спецсимволы (!@#\$...)',
            value: _useSpecial,
            onChanged: (value) {
              setState(() => _useSpecial = value);
              _generate();
            },
          ),

          if (widget.showSubmitButton) ...[
            const SizedBox(height: 16),
            SmoothButton(
              onPressed:
                  widget.canSubmit &&
                      _generatedPassword.isNotEmpty &&
                      widget.onPasswordSubmitted != null
                  ? () => widget.onPasswordSubmitted!.call(_generatedPassword)
                  : null,
              icon: const Icon(Icons.check, size: 18),
              label: widget.submitLabel,
              type: SmoothButtonType.filled,
            ),
          ],
        ],
      ),
    );
  }
}

class _ProfilesSection extends StatelessWidget {
  const _ProfilesSection({
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

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.password,
    required this.copied,
    required this.placeholder,
    required this.regenerateTooltip,
    required this.onCopy,
    this.onRegenerate,
  });

  final String password;
  final bool copied;
  final String placeholder;
  final String regenerateTooltip;
  final VoidCallback onCopy;
  final VoidCallback? onRegenerate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          IconButton.filledTonal(
            onPressed: onRegenerate,
            icon: const Icon(Icons.refresh, size: 18),
            tooltip: regenerateTooltip,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SelectableText(
                password.isEmpty ? placeholder : password,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            onPressed: password.isEmpty ? null : onCopy,
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                copied ? Icons.check : Icons.copy,
                key: ValueKey(copied),
                size: 18,
              ),
            ),
            tooltip: copied ? 'Скопировано!' : 'Копировать',
          ),
        ],
      ),
    );
  }
}

class _BatchPasswordsSection extends StatelessWidget {
  const _BatchPasswordsSection({
    required this.selectedCount,
    required this.countOptions,
    required this.passwords,
    required this.copiedIndex,
    required this.onCountChanged,
    required this.onGeneratePressed,
    required this.onCopyPressed,
  });

  final int selectedCount;
  final List<int> countOptions;
  final List<String> passwords;
  final int? copiedIndex;
  final ValueChanged<int> onCountChanged;
  final VoidCallback onGeneratePressed;
  final ValueChanged<int> onCopyPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Пакетная генерация',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                value: selectedCount,
                decoration: primaryInputDecoration(
                  context,
                  labelText: 'Количество паролей',
                ),
                items: countOptions
                    .map(
                      (count) => DropdownMenuItem<int>(
                        value: count,
                        child: Text(count.toString()),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  if (value != null) {
                    onCountChanged(value);
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            SmoothButton(
              onPressed: onGeneratePressed,
              icon: const Icon(Icons.auto_awesome, size: 18),
              label: 'Сгенерировать',
              type: SmoothButtonType.outlined,
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (passwords.isEmpty)
          Text(
            'Нажмите "Сгенерировать", чтобы получить список паролей.',
            style: theme.textTheme.bodyMedium,
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: passwords.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final password = passwords[index];
              final copied = copiedIndex == index;
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SelectableText(
                        password,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: copied ? 'Скопировано!' : 'Копировать',
                      onPressed: () => onCopyPressed(index),
                      icon: Icon(copied ? Icons.check : Icons.copy_outlined),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}

class _LengthSlider extends StatelessWidget {
  const _LengthSlider({
    required this.length,
    required this.minLength,
    required this.maxLength,
    required this.onChanged,
  });

  final double length;
  final int minLength;
  final int maxLength;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalDivisions = maxLength - minLength;

    return Row(
      children: [
        Text('Длина: ${length.round()}', style: theme.textTheme.bodyMedium),
        Expanded(
          child: Slider(
            value: length,
            min: minLength.toDouble(),
            max: maxLength.toDouble(),
            divisions: totalDivisions > 0 ? totalDivisions : null,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      title: Text(label, style: Theme.of(context).textTheme.bodyMedium),
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }
}
