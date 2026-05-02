import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/onboarding/application/showcase_storage.dart';
import 'package:hoplixi/features/onboarding/domain/app_guide_id.dart';
import 'package:hoplixi/features/onboarding/domain/app_guide_progress.dart';

final showcaseStorageProvider = Provider<ShowcaseStorage>((ref) {
  return createShowcaseStorage();
});

final showcaseControllerProvider = NotifierProvider<ShowcaseController, void>(
  ShowcaseController.new,
);

class ShowcaseController extends Notifier<void> {
  @override
  void build() {}

  Future<bool> shouldAutoStart(AppGuideId id) async {
    final seenVersion = await ref
        .read(showcaseStorageProvider)
        .getSeenVersion(id);
    return seenVersion == null || seenVersion < currentAppGuideVersion(id);
  }

  Future<void> markSeen(AppGuideId id) async {
    await ref
        .read(showcaseStorageProvider)
        .markSeen(id, currentAppGuideVersion(id));
  }

  Future<void> resetGuide(AppGuideId id) async {
    await ref.read(showcaseStorageProvider).resetGuide(id);
  }

  Future<void> resetAllGuides() async {
    await ref.read(showcaseStorageProvider).resetAllGuides();
  }
}
