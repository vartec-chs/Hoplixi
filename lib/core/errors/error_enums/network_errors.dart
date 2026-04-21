import 'package:json_annotation/json_annotation.dart';

@JsonEnum(valueField: 'value')
enum NetworkErrorCode {
  timeout('NET_TIMEOUT'),
  unauthorized('NET_UNAUTHORIZED'),
  forbidden('NET_FORBIDDEN'),
  notFound('NET_NOT_FOUND'),
  badRequest('NET_BAD_REQUEST'),
  serverError('NET_SERVER_ERROR'),
  noConnection('NET_NO_CONNECTION'),
  cancelled('NET_CANCELLED'),
  unknown('NET_UNKNOWN_ERROR');

  final String value;
  const NetworkErrorCode(this.value);
}
