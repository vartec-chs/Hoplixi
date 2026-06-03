import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/vault_db/core/models/dto/password_dto.dart';
import 'package:hoplixi/vault_db/providers/providers.dart';

class DuplicatePasswordGroupDto {
  const DuplicatePasswordGroupDto({required this.items});

  final List<PasswordCardDto> items;

  int get count => items.length;
}

final duplicatePasswordsAnalysisProvider =
    AsyncNotifierProvider.autoDispose<
      DuplicatePasswordsAnalysisNotifier,
      List<DuplicatePasswordGroupDto>
    >(DuplicatePasswordsAnalysisNotifier.new);

class DuplicatePasswordsAnalysisNotifier
    extends AsyncNotifier<List<DuplicatePasswordGroupDto>> {
  @override
  Future<List<DuplicatePasswordGroupDto>> build() async {
    return const <DuplicatePasswordGroupDto>[];
  }

  Future<void> analyze() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repositories = await ref.read(vaultRepositories.future);
      final groups = (await repositories.password.getDuplicatePasswordGroups())
          .getOrThrow();

      return groups
          .map((items) => DuplicatePasswordGroupDto(items: items))
          .toList(growable: false);
    });
  }
}
