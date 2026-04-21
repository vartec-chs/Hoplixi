import 'package:json_annotation/json_annotation.dart';

@JsonEnum(valueField: 'value')
enum AuthErrorCode {
  unauthorized('AUTH_UNAUTHORIZED'),
  tokenExpired('AUTH_TOKEN_EXPIRED'),
  invalidCredentials('AUTH_INVALID_CREDENTIALS'),
  accessDenied('AUTH_ACCESS_DENIED'),
  unknown('AUTH_UNKNOWN_ERROR');

  final String value;
  const AuthErrorCode(this.value);
}
