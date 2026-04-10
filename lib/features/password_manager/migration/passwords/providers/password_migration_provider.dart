import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/password_manager/migration/passwords/services/password_migration_service.dart';
import 'package:hoplixi/db_core/models/dto/password_dto.dart';
import 'package:hoplixi/db_core/provider/main_store_provider.dart';

const _messageNotChanged = Object();

class PasswordMigrationState {
  final bool isLoading;
  final String? message;
  final bool isSuccess;

  const PasswordMigrationState({
    this.isLoading = false,
    this.message,
    this.isSuccess = false,
  });

  PasswordMigrationState copyWith({
    bool? isLoading,
    Object? message = _messageNotChanged,
    bool? isSuccess,
  }) {
    return PasswordMigrationState(
      isLoading: isLoading ?? this.isLoading,
      message: identical(message, _messageNotChanged)
          ? this.message
          : message as String?,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

class PasswordMigrationNotifier extends AsyncNotifier<PasswordMigrationState> {
  late final PasswordMigrationService _service;

  @override
  Future<PasswordMigrationState> build() async {
    final manager = await ref.watch(mainStoreManagerProvider.future);
    if (manager == null || manager.currentStore == null) {
      throw Exception('Database is not initialized');
    }

    _service = PasswordMigrationService(manager.currentStore!.passwordDao);
    return const PasswordMigrationState();
  }

  Future<bool> savePasswords(List<CreatePasswordDto> passwords) async {
    final currentState = state.value;
    if (currentState == null) {
      return false;
    }

    if (passwords.isEmpty) {
      state = AsyncData(
        currentState.copyWith(
          message: 'Добавьте хотя бы одну карточку для импорта.',
          isSuccess: false,
        ),
      );
      return false;
    }

    state = AsyncData(
      currentState.copyWith(isLoading: true, message: null, isSuccess: false),
    );

    final result = await _service.savePasswords(passwords);

    return result.fold(
      (count) {
        state = AsyncData(
          PasswordMigrationState(
            isLoading: false,
            message: 'Импортировано паролей: $count.',
            isSuccess: true,
          ),
        );
        return true;
      },
      (error) {
        state = AsyncData(
          PasswordMigrationState(
            isLoading: false,
            message: error.toString(),
            isSuccess: false,
          ),
        );
        return false;
      },
    );
  }

  void clearMessage() {
    final currentState = state.value;
    if (currentState == null) {
      return;
    }

    state = AsyncData(currentState.copyWith(message: null, isSuccess: false));
  }

  void setError(String message) {
    final currentState = state.value;
    if (currentState == null) {
      return;
    }

    state = AsyncData(
      currentState.copyWith(message: message, isSuccess: false),
    );
  }
}

final passwordMigrationProvider =
    AsyncNotifierProvider.autoDispose<
      PasswordMigrationNotifier,
      PasswordMigrationState
    >(PasswordMigrationNotifier.new);
