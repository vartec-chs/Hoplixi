import 'package:freezed_annotation/freezed_annotation.dart';

part 'create_store_state.freezed.dart';

/// Шаги создания хранилища
enum CreateStoreStep {
  nameAndDescription, // Шаг 1: Имя и описание
  selectPath, // Шаг 2: Выбор пути
  masterPassword, // Шаг 3: Мастер пароль
  confirmation, // Шаг 4: Подтверждение
}

/// Тип пути хранилища
enum PathType {
  standard, // Стандартный путь (null)
  custom, // Кастомный путь
}

/// Состояние формы создания хранилища
@freezed
sealed class CreateStoreFormState with _$CreateStoreFormState {
  const factory CreateStoreFormState({
    // Текущий шаг
    @Default(CreateStoreStep.nameAndDescription) CreateStoreStep currentStep,

    // Шаг 1: Имя и описание
    @Default('') String name,
    @Default('') String description,

    // Шаг 2: Путь
    @Default(PathType.standard) PathType pathType,
    String? customPath,

    // Шаг 3: Пароль
    @Default('') String password,
    @Default('') String passwordConfirmation,
    @Default(false) bool useDeviceKey,

    // Валидация
    String? nameError,
    String? passwordError,
    String? passwordConfirmationError,
    String? pathError,

    // Статус создания
    @Default(false) bool isCreating,
    String? creationError,
  }) = _CreateStoreFormState;

  const CreateStoreFormState._();

  /// Проверка валидности имени
  bool get isNameValid => name.trim().isNotEmpty && nameError == null;

  /// Проверка валидности пути
  bool get isPathValid {
    if (pathType == PathType.standard) return true;
    return customPath != null && customPath!.isNotEmpty && pathError == null;
  }

  /// Проверка валидности пароля
  bool get isPasswordValid {
    return password.isNotEmpty &&
        passwordError == null &&
        password == passwordConfirmation &&
        passwordConfirmationError == null;
  }

  /// Можно ли перейти на следующий шаг
  bool get canProceed {
    switch (currentStep) {
      case CreateStoreStep.nameAndDescription:
        return isNameValid;
      case CreateStoreStep.selectPath:
        return isPathValid;
      case CreateStoreStep.masterPassword:
        return isPasswordValid;
      case CreateStoreStep.confirmation:
        return true;
    }
  }

  /// Номер текущего шага (0-3)
  int get stepIndex => currentStep.index;

  /// Прогресс в процентах
  double get progress => (stepIndex + 1) / 4;

  /// Путь для создания (null = стандартный)
  String? get finalPath {
    return pathType == PathType.standard ? null : customPath;
  }
}
