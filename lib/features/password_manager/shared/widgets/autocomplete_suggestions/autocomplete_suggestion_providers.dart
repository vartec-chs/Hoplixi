import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/errors/errors.dart';
import 'package:hoplixi/main_db/core/main_store.dart';
import 'package:hoplixi/main_db/providers/main_store_manager_provider.dart';

/// State for login and email autocomplete suggestions.
class AutocompleteSuggestionsState {
  const AutocompleteSuggestionsState({
    this.loginQuery = '',
    this.loginSuggestions = const [],
    this.isLoginLoading = false,
    this.emailQuery = '',
    this.emailSuggestions = const [],
    this.isEmailLoading = false,
  });

  final String loginQuery;
  final List<String> loginSuggestions;
  final bool isLoginLoading;
  final String emailQuery;
  final List<String> emailSuggestions;
  final bool isEmailLoading;

  AutocompleteSuggestionsState copyWith({
    String? loginQuery,
    List<String>? loginSuggestions,
    bool? isLoginLoading,
    String? emailQuery,
    List<String>? emailSuggestions,
    bool? isEmailLoading,
  }) {
    return AutocompleteSuggestionsState(
      loginQuery: loginQuery ?? this.loginQuery,
      loginSuggestions: loginSuggestions ?? this.loginSuggestions,
      isLoginLoading: isLoginLoading ?? this.isLoginLoading,
      emailQuery: emailQuery ?? this.emailQuery,
      emailSuggestions: emailSuggestions ?? this.emailSuggestions,
      isEmailLoading: isEmailLoading ?? this.isEmailLoading,
    );
  }
}

/// SQL-backed autocomplete suggestions for the current opened store.
final currentStoreAutocompleteSuggestionsProvider =
    AsyncNotifierProvider.autoDispose<
      CurrentStoreAutocompleteSuggestionsNotifier,
      AutocompleteSuggestionsState
    >(CurrentStoreAutocompleteSuggestionsNotifier.new);

class CurrentStoreAutocompleteSuggestionsNotifier
    extends AsyncNotifier<AutocompleteSuggestionsState> {
  @override
  Future<AutocompleteSuggestionsState> build() async {
    ref.watch(mainStoreManagerStateProvider);
    return const AutocompleteSuggestionsState();
  }

  Future<List<String>> searchLogins(String query) async {
    final normalizedQuery = query.trim();
    final current = state.value ?? const AutocompleteSuggestionsState();

    if (normalizedQuery.isEmpty) {
      final next = current.copyWith(
        loginQuery: query,
        loginSuggestions: const [],
        isLoginLoading: false,
      );
      state = AsyncData(next);
      return next.loginSuggestions;
    }

    state = AsyncData(
      current.copyWith(loginQuery: query, isLoginLoading: true),
    );

    final List<String> suggestions;
    try {
      final store = await _requireOpenStore();
      suggestions = await _selectSuggestions(
        store,
        _loginSuggestionsSql,
        normalizedQuery,
      );
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return const [];
    }

    final latest = state.value ?? current;
    if (latest.loginQuery != query) return suggestions;

    state = AsyncData(
      latest.copyWith(loginSuggestions: suggestions, isLoginLoading: false),
    );
    return suggestions;
  }

  Future<List<String>> searchEmails(String query) async {
    final normalizedQuery = query.trim();
    final current = state.value ?? const AutocompleteSuggestionsState();

    if (normalizedQuery.isEmpty) {
      final next = current.copyWith(
        emailQuery: query,
        emailSuggestions: const [],
        isEmailLoading: false,
      );
      state = AsyncData(next);
      return next.emailSuggestions;
    }

    state = AsyncData(
      current.copyWith(emailQuery: query, isEmailLoading: true),
    );

    final List<String> suggestions;
    try {
      final store = await _requireOpenStore();
      suggestions = await _selectSuggestions(
        store,
        _emailSuggestionsSql,
        normalizedQuery,
      );
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return const [];
    }

    final latest = state.value ?? current;
    if (latest.emailQuery != query) return suggestions;

    state = AsyncData(
      latest.copyWith(emailSuggestions: suggestions, isEmailLoading: false),
    );
    return suggestions;
  }

  Future<MainStore> _requireOpenStore() async {
    await ref.read(mainStoreManagerStateProvider.future);
    final store = ref.read(mainStoreManagerStateProvider.notifier).currentStore;

    if (store == null) {
      throw AppError.mainDatabase(
        code: MainDatabaseErrorCode.notInitialized,
        message: 'Хранилище не открыто',
        timestamp: DateTime.now(),
      );
    }

    return store;
  }

  Future<List<String>> _selectSuggestions(
    MainStore store,
    String sql,
    String query,
  ) async {
    final normalizedQuery = query.toLowerCase();
    final rows = await store
        .customSelect(
          sql,
          variables: [
            Variable.withString('%${_escapeLike(normalizedQuery)}%'),
            Variable.withString('${_escapeLike(normalizedQuery)}%'),
            Variable.withString(normalizedQuery),
          ],
          readsFrom: {
            store.vaultItems,
            store.passwordItems,
            store.otpItems,
            store.wifiItems,
            store.contactItems,
          },
        )
        .get();

    return rows
        .map((row) => row.read<String>('value'))
        .where((value) => value.trim().isNotEmpty)
        .take(10)
        .toList(growable: false);
  }
}

String _escapeLike(String value) {
  return value
      .replaceAll(r'\', r'\\')
      .replaceAll('%', r'\%')
      .replaceAll('_', r'\_');
}

const _loginSuggestionsSql = '''
WITH candidate_values(value) AS (
  SELECT trim(pi.login)
  FROM password_items pi
  INNER JOIN vault_items vi ON vi.id = pi.item_id
  WHERE vi.is_deleted = 0
    AND pi.login IS NOT NULL
    AND trim(pi.login) <> ''
  UNION
  SELECT trim(oi.account_name)
  FROM otp_items oi
  INNER JOIN vault_items vi ON vi.id = oi.item_id
  WHERE vi.is_deleted = 0
    AND oi.account_name IS NOT NULL
    AND trim(oi.account_name) <> ''
  UNION
  SELECT trim(wi.username)
  FROM wifi_items wi
  INNER JOIN vault_items vi ON vi.id = wi.item_id
  WHERE vi.is_deleted = 0
    AND wi.username IS NOT NULL
    AND trim(wi.username) <> ''
  UNION
  SELECT trim(wi.identity)
  FROM wifi_items wi
  INNER JOIN vault_items vi ON vi.id = wi.item_id
  WHERE vi.is_deleted = 0
    AND wi.identity IS NOT NULL
    AND trim(wi.identity) <> ''
)
SELECT value
FROM candidate_values
WHERE lower(value) LIKE ? ESCAPE '\\'
ORDER BY
  CASE WHEN lower(value) LIKE ? ESCAPE '\\' THEN 0 ELSE 1 END,
  instr(lower(value), ?),
  length(value),
  lower(value)
LIMIT 10;
''';

const _emailSuggestionsSql = '''
WITH candidate_values(value) AS (
  SELECT trim(pi.email)
  FROM password_items pi
  INNER JOIN vault_items vi ON vi.id = pi.item_id
  WHERE vi.is_deleted = 0
    AND pi.email IS NOT NULL
    AND trim(pi.email) <> ''
  UNION
  SELECT trim(pi.login)
  FROM password_items pi
  INNER JOIN vault_items vi ON vi.id = pi.item_id
  WHERE vi.is_deleted = 0
    AND pi.login IS NOT NULL
    AND trim(pi.login) <> ''
  UNION
  SELECT trim(ci.email)
  FROM contact_items ci
  INNER JOIN vault_items vi ON vi.id = ci.item_id
  WHERE vi.is_deleted = 0
    AND ci.email IS NOT NULL
    AND trim(ci.email) <> ''
  UNION
  SELECT trim(oi.account_name)
  FROM otp_items oi
  INNER JOIN vault_items vi ON vi.id = oi.item_id
  WHERE vi.is_deleted = 0
    AND oi.account_name IS NOT NULL
    AND trim(oi.account_name) <> ''
  UNION
  SELECT trim(wi.username)
  FROM wifi_items wi
  INNER JOIN vault_items vi ON vi.id = wi.item_id
  WHERE vi.is_deleted = 0
    AND wi.username IS NOT NULL
    AND trim(wi.username) <> ''
  UNION
  SELECT trim(wi.identity)
  FROM wifi_items wi
  INNER JOIN vault_items vi ON vi.id = wi.item_id
  WHERE vi.is_deleted = 0
    AND wi.identity IS NOT NULL
    AND trim(wi.identity) <> ''
)
SELECT value
FROM candidate_values
WHERE lower(value) LIKE ? ESCAPE '\\'
  AND instr(value, '@') > 1
  AND instr(substr(value, instr(value, '@') + 1), '.') > 1
ORDER BY
  CASE WHEN lower(value) LIKE ? ESCAPE '\\' THEN 0 ELSE 1 END,
  instr(lower(value), ?),
  length(value),
  lower(value)
LIMIT 10;
''';
