import 'package:json_annotation/json_annotation.dart';

@JsonEnum(fieldRename: FieldRename.snake)
enum AuthFlowStatus {
  idle,
  selectingProvider,
  selectingCredential,
  inProgress,
  success,
  cancelled,
  failure,
}
