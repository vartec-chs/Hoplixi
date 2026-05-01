import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/main_db/core/models/dto/index.dart';
import 'package:hoplixi/main_db/providers/other/dao_providers.dart';

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
      final dao = await ref.read(passwordFilterDaoProvider.future);
      return dao.getDuplicatePasswordGroups();
    });
  }
}
