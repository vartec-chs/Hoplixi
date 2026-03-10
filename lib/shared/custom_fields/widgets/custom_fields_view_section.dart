import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/shared/custom_fields/custom_fields_helpers.dart';

import '../models/custom_field_entry.dart';
import 'custom_fields_viewer.dart';

class CustomFieldsViewSection extends ConsumerWidget {
  const CustomFieldsViewSection({super.key, required this.itemId});

  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<CustomFieldEntry>>(
      future: loadCustomFields(ref, itemId),
      builder: (context, snapshot) {
        final fields = snapshot.data;
        if (fields == null || fields.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          children: [
            const SizedBox(height: 4),
            CustomFieldsViewer(fields: fields),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }
}
