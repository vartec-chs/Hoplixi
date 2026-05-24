import 'package:json_annotation/json_annotation.dart';

@JsonEnum(fieldRename: FieldRename.snake)
enum DocumentType {
  passport,
  idCard,
  driverLicense,
  contract,
  invoice,
  receipt,
  certificate,
  insurance,
  tax,
  medical,
  legal,
  financial,
  other,
}
