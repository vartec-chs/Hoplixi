import 'package:hoplixi/db_core/models/db_state.dart';

class MainStoreSessionBridge {
  const MainStoreSessionBridge({
    required this.readState,
    required this.setState,
    required this.setErrorState,
  });

  final DatabaseState Function() readState;
  final void Function(DatabaseState) setState;
  final void Function(DatabaseState) setErrorState;
}
