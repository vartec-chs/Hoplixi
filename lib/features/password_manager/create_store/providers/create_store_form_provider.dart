import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/password_manager/create_store/models/create_store_state.dart';

/// Провайдер для управления состоянием формы создания хранилища
final createStoreFormProvider =
    NotifierProvider<CreateStoreFormNotifier, CreateStoreFormState>(
      CreateStoreFormNotifier.new,
    );

/// Notifier для управления формой создания хранилища
class CreateStoreFormNotifier extends Notifier<CreateStoreFormState> {
  @override
  CreateStoreFormState build() {
    return const CreateStoreFormState();
  }

  /// Обновить имя
  void updateName(String name) {
    state = state.copyWith(name: name, nameError: _validateName(name));
  }

  /// Обновить описание
  void updateDescription(String description) {
    state = state.copyWith(description: description);
  }

  /// Установить тип пути
  void setPathType(PathType pathType) {
    state = state.copyWith(
      pathType: pathType,
      customPath: pathType == PathType.standard ? null : state.customPath,
      pathError: null,
    );
  }

  /// Установить кастомный путь
  void setCustomPath(String? path) {
    state = state.copyWith(customPath: path, pathError: _validatePath(path));
  }

  /// Обновить пароль
  void updatePassword(String password) {
    state = state.copyWith(
      password: password,
      passwordError: _validatePassword(password),
      passwordConfirmationError: _validatePasswordConfirmation(
        password,
        state.passwordConfirmation,
      ),
    );
  }

  /// Обновить подтверждение пароля
  void updatePasswordConfirmation(String confirmation) {
    state = state.copyWith(
      passwordConfirmation: confirmation,
      passwordConfirmationError: _validatePasswordConfirmation(
        state.password,
        confirmation,
      ),
    );
  }

  /// Установить использование ключа устройства
  void setUseDeviceKey(bool value) {
    state = state.copyWith(useDeviceKey: value);
  }

  /// Перейти к следующему шагу
  void nextStep() {
    if (!state.canProceed) return;

    final nextStep = CreateStoreStep.values[state.stepIndex + 1];
    state = state.copyWith(currentStep: nextStep);
  }

  /// Вернуться к предыдущему шагу
  void previousStep() {
    if (state.stepIndex == 0) return;

    final prevStep = CreateStoreStep.values[state.stepIndex - 1];
    state = state.copyWith(currentStep: prevStep);
  }

  /// Перейти к конкретному шагу
  void goToStep(CreateStoreStep step) {
    state = state.copyWith(currentStep: step);
  }

  /// Установить статус создания
  void setCreating(bool isCreating) {
    state = state.copyWith(isCreating: isCreating);
  }

  /// Установить ошибку создания
  void setCreationError(String? error) {
    state = state.copyWith(creationError: error);
  }

  /// Сбросить форму
  void reset() {
    state = const CreateStoreFormState();
  }

  // Валидация

  String? _validateName(String name) {
    if (name.trim().isEmpty) {
      return 'Имя хранилища не может быть пустым';
    }
    if (name.trim().length < 4) {
      return 'Имя должно содержать минимум 4 символа';
    }
    if (name.trim().length > 50) {
      return 'Имя не может быть длиннее 50 символов';
    }
    // Проверка на недопустимые символы
    final invalidChars = RegExp(r'[<>:"/\\|?*]');
    if (invalidChars.hasMatch(name)) {
      return 'Имя содержит недопустимые символы';
    }
    return null;
  }

  String? _validatePath(String? path) {
    if (state.pathType == PathType.standard) return null;
    if (path == null || path.isEmpty) {
      return 'Выберите путь для хранилища';
    }
    return null;
  }

  String? _validatePassword(String password) {
    bool isFullValidation = false;
    if (password.isEmpty) {
      return 'Введите мастер пароль';
    }

    if (password.length < 4) {
      return 'Пароль должен содержать минимум 4 символа';
    }

    if (isFullValidation) {
      if (password.length < 8) {
        return 'Пароль должен содержать минимум 8 символов';
      }
      if (password.length > 128) {
        return 'Пароль слишком длинный (макс. 128 символов)';
      }

      // Проверка сложности пароля
      bool hasUppercase = password.contains(RegExp(r'[A-Z]'));
      bool hasLowercase = password.contains(RegExp(r'[a-z]'));
      bool hasDigit = password.contains(RegExp(r'[0-9]'));
      bool hasSpecial = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

      int complexity = 0;
      if (hasUppercase) complexity++;
      if (hasLowercase) complexity++;
      if (hasDigit) complexity++;
      if (hasSpecial) complexity++;

      if (complexity < 3) {
        return 'Пароль должен содержать буквы, цифры и спецсимволы';
      }
    }

    return null;
  }

  String? _validatePasswordConfirmation(String password, String confirmation) {
    if (confirmation.isEmpty) {
      return 'Подтвердите пароль';
    }
    if (password != confirmation) {
      return 'Пароли не совпадают';
    }
    return null;
  }
}
