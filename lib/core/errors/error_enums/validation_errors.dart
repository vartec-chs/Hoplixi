import 'package:json_annotation/json_annotation.dart';

@JsonEnum(valueField: 'value')
enum ValidationErrorCode {
  invalidInput('VALIDATION_INVALID_INPUT'),
  emptyField('VALIDATION_EMPTY_FIELD'),
  tooShort('VALIDATION_TOO_SHORT'),
  tooLong('VALIDATION_TOO_LONG'),
  invalidFormat('VALIDATION_INVALID_FORMAT'),
  outOfRange('VALIDATION_OUT_OF_RANGE'),
  unknown('VALIDATION_UNKNOWN');

  final String value;
  const ValidationErrorCode(this.value);
}
