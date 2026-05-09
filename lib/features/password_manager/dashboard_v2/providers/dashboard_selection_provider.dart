import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/dashboard_entity_type.dart';

final dashboardSelectionProvider = NotifierProvider.autoDispose
    .family<DashboardSelectionNotifier, Set<String>, DashboardEntityType>(
      DashboardSelectionNotifier.new,
    );

final class DashboardSelectionNotifier extends Notifier<Set<String>> {
  DashboardSelectionNotifier(this.entityType);

  final DashboardEntityType entityType;

  @override
  Set<String> build() => <String>{};

  bool get isSelecting => state.isNotEmpty;

  void toggle(String id) {
    final next = {...state};
    if (!next.add(id)) {
      next.remove(id);
    }
    state = next;
  }

  void selectOnly(String id) {
    state = {id};
  }

  void clear() {
    state = <String>{};
  }
}
