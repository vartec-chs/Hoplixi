import 'package:flutter/material.dart';
import 'package:hoplixi/vault_db/core/scheme/tables/system/custom_fields/vault_item_custom_fields.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

IconData iconForCustomFieldType(CustomFieldType type) => switch (type) {
  CustomFieldType.text => LucideIcons.textCursor,
  CustomFieldType.concealed => LucideIcons.lock,
  CustomFieldType.url => LucideIcons.globe,
  CustomFieldType.email => LucideIcons.mail,
  CustomFieldType.phone => LucideIcons.phone,
  CustomFieldType.date => LucideIcons.calendar,
  CustomFieldType.number => LucideIcons.hash,
  CustomFieldType.multiline => LucideIcons.squareSplitHorizontal,
  CustomFieldType.boolean => LucideIcons.check,
};
