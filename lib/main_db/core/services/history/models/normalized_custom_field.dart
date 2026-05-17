import '../../../tables/vault_items/vault_item_custom_fields.dart';
import 'history_field_snapshot.dart';

class NormalizedCustomField {
  const NormalizedCustomField({
    required this.identityKey,
    this.originalFieldId,
    required this.label,
    this.value,
    required this.fieldType,
    required this.isSecret,
    required this.sortOrder,
  });

  final String identityKey;
  final String? originalFieldId;
  final String label;
  final Object? value;
  final CustomFieldType fieldType;
  final bool isSecret;
  final int sortOrder;

  bool get isSensitive {
    return isSecret || fieldType == CustomFieldType.concealed;
  }

  List<HistoryFieldSnapshot<Object?>> diffFields() {
    return [
      HistoryFieldSnapshot<String>(
        key: '$identityKey.label',
        label: '$label / Label',
        value: label,
      ),
      HistoryFieldSnapshot<Object?>(
        key: '$identityKey.value',
        label: label,
        value: value,
        isSensitive: isSensitive,
      ),
      HistoryFieldSnapshot<String>(
        key: '$identityKey.fieldType',
        label: '$label / Type',
        value: fieldType.name,
      ),
      HistoryFieldSnapshot<bool>(
        key: '$identityKey.isSecret',
        label: '$label / Secret',
        value: isSecret,
      ),
      HistoryFieldSnapshot<int>(
        key: '$identityKey.sortOrder',
        label: '$label / Sort order',
        value: sortOrder,
      ),
    ];
  }
}
