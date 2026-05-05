import 'package:flutter/widgets.dart';
import 'package:hoplixi/features/password_manager/forms/shared/share/share_fields_dialog.dart';
import 'package:hoplixi/features/password_manager/forms/shared/share/shareable_field.dart';
import 'package:hoplixi/features/password_manager/shared/widgets/custom_fields/custom_fields_helpers.dart';
import 'package:hoplixi/features/password_manager/shared/widgets/custom_fields/models/custom_field_entry.dart';
import 'package:hoplixi/generated/l10n/translations.g.dart';

Future<List<ShareableField>> loadCustomShareableFields(
  Object ref,
  String itemId,
) async {
  final fields = await loadCustomFields(ref, itemId);
  return customFieldsToShareableFields(fields);
}

List<ShareableField> buildCommonShareFields(
  BuildContext context, {
  required String name,
  String? categoryName,
  List<String> tagNames = const [],
  String? description,
  List<CustomFieldEntry> customFields = const [],
}) {
  final l10n = context.t.dashboard_forms;

  return compactShareableFields([
    shareableField(id: 'name', label: l10n.share_name_label, value: name),
    shareableField(
      id: 'category',
      label: l10n.share_category_label,
      value: categoryName,
    ),
    shareableField(id: 'tags', label: l10n.share_tags_label, value: tagNames),
    shareableField(
      id: 'description',
      label: l10n.description_label,
      value: description,
    ),
    ...customFieldsToShareableFields(customFields),
  ]);
}

Future<void> shareEntityFields({
  required BuildContext context,
  required ShareableEntity entity,
}) {
  return showShareFieldsDialog(context: context, entity: entity);
}
