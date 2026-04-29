import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_generator/models/password_generator_profile.dart';
import 'package:hoplixi/features/password_generator/services/password_generator_profile_service.dart';
import 'package:hoplixi/shared/ui/button.dart';
import 'package:hoplixi/shared/ui/password_strength_indicator.dart';
import 'package:hoplixi/shared/ui/text_field.dart' hide PasswordField;

import 'widgets/batch_passwords_section.dart';
import 'widgets/length_slider.dart';
import 'widgets/option_tile.dart';
import 'widgets/password_field.dart';
import 'widgets/profiles_section.dart';

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
  late String _lowercaseCharacters;
  late String _uppercaseCharacters;
  late String _digitCharacters;
  late String _specialCharacters;

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
    _lowercaseCharacters = _lowercase;
    _uppercaseCharacters = _uppercase;
    _digitCharacters = _digits;
    _specialCharacters = _special;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _generatedPassword.isNotEmpty) {
        return;
      }
      _generate();
    });
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
      buffer.write(_lowercaseCharacters);
    }
    if (_useUppercase) {
      buffer.write(_uppercaseCharacters);
    }
    if (_useDigits) {
      buffer.write(_digitCharacters);
    }
    if (_useSpecial) {
      buffer.write(_specialCharacters);
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
      _lowercaseCharacters = profile.lowercaseCharacters ?? _lowercase;
      _uppercaseCharacters = profile.uppercaseCharacters ?? _uppercase;
      _digitCharacters = profile.digitCharacters ?? _digits;
      _specialCharacters = profile.specialCharacters ?? _special;
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
        lowercaseCharacters: _lowercaseCharacters,
        uppercaseCharacters: _uppercaseCharacters,
        digitCharacters: _digitCharacters,
        specialCharacters: _specialCharacters,
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

  Future<void> _showCharacterSetEditor({
    required String title,
    required String currentValue,
    required String defaultValue,
    required ValueChanged<String> onSaved,
  }) async {
    final controller = TextEditingController(text: currentValue);
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: 4,
            minLines: 2,
            decoration: primaryInputDecoration(
              dialogContext,
              labelText: 'Набор символов',
              helperText: 'Дубликаты будут удалены при сохранении',
            ),
          ),
          actions: [
            SmoothButton(
              onPressed: () => controller.text = defaultValue,
              label: 'Сбросить',
              type: .text,
            ),
            SmoothButton(
              onPressed: () => Navigator.pop(dialogContext),
              label: 'Отмена',
              type: .text,
            ),
            SmoothButton(
              onPressed: () => Navigator.pop(dialogContext, controller.text),
              label: 'Сохранить',
            ),
          ],
        );
      },
    );
    controller.dispose();

    if (result == null) {
      return;
    }

    final normalizedValue = _deduplicateCharacters(result);
    if (normalizedValue.isEmpty) {
      Toaster.warning(
        title: 'Генератор',
        description: 'Набор символов не может быть пустым.',
      );
      return;
    }

    onSaved(normalizedValue);
    _generate();
  }

  String _deduplicateCharacters(String value) {
    final seen = <int>{};
    final buffer = StringBuffer();
    for (final codeUnit in value.codeUnits) {
      if (seen.add(codeUnit)) {
        buffer.writeCharCode(codeUnit);
      }
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PasswordField(
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

          LengthSlider(
            length: _length,
            minLength: widget.minLength,
            maxLength: widget.maxLength,
            onChanged: (value) {
              setState(() => _length = value);
              _generate();
            },
          ),

          const SizedBox(height: 16),

          BatchPasswordsSection(
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

          ProfilesSection(
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

          OptionTile(
            label: 'Строчные (a-z)',
            characterSet: _lowercaseCharacters,
            value: _useLowercase,
            onChanged: (value) {
              setState(() => _useLowercase = value);
              _generate();
            },
            onEditCharacters: () => _showCharacterSetEditor(
              title: 'Строчные символы',
              currentValue: _lowercaseCharacters,
              defaultValue: _lowercase,
              onSaved: (value) {
                setState(() => _lowercaseCharacters = value);
              },
            ),
          ),
          OptionTile(
            label: 'Прописные (A-Z)',
            characterSet: _uppercaseCharacters,
            value: _useUppercase,
            onChanged: (value) {
              setState(() => _useUppercase = value);
              _generate();
            },
            onEditCharacters: () => _showCharacterSetEditor(
              title: 'Прописные символы',
              currentValue: _uppercaseCharacters,
              defaultValue: _uppercase,
              onSaved: (value) {
                setState(() => _uppercaseCharacters = value);
              },
            ),
          ),
          OptionTile(
            label: 'Цифры (0-9)',
            characterSet: _digitCharacters,
            value: _useDigits,
            onChanged: (value) {
              setState(() => _useDigits = value);
              _generate();
            },
            onEditCharacters: () => _showCharacterSetEditor(
              title: 'Цифры',
              currentValue: _digitCharacters,
              defaultValue: _digits,
              onSaved: (value) {
                setState(() => _digitCharacters = value);
              },
            ),
          ),
          OptionTile(
            label: 'Спецсимволы (!@#\$...)',
            characterSet: _specialCharacters,
            value: _useSpecial,
            onChanged: (value) {
              setState(() => _useSpecial = value);
              _generate();
            },
            onEditCharacters: () => _showCharacterSetEditor(
              title: 'Спецсимволы',
              currentValue: _specialCharacters,
              defaultValue: _special,
              onSaved: (value) {
                setState(() => _specialCharacters = value);
              },
            ),
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
