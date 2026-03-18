import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/local_send/models/session_state.dart';

enum LocalSendRouteState { discovery, transfer }

final localSendRouteStateProvider =
    NotifierProvider<LocalSendRouteStateNotifier, LocalSendRouteState>(
      LocalSendRouteStateNotifier.new,
    );

class LocalSendRouteStateNotifier extends Notifier<LocalSendRouteState> {
  @override
  LocalSendRouteState build() => LocalSendRouteState.discovery;

  void syncWithSession(SessionState sessionState) {
    state = switch (sessionState) {
      SessionDisconnected() => LocalSendRouteState.discovery,
      _ => LocalSendRouteState.transfer,
    };
  }

  void showDiscovery() {
    state = LocalSendRouteState.discovery;
  }
}
