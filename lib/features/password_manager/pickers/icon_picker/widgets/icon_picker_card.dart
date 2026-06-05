import 'package:flutter/material.dart';
import 'package:hoplixi/shared/widgets/icon_ref_preview.dart';
import 'package:hoplixi/vault_db/core/models/dto/dto.dart';
import 'package:hoplixi/vault_db/core/scheme/tables/system/icons/icon_refs.dart';

/// Виджет карточки иконки для picker.
class IconPickerCard extends StatelessWidget {
  const IconPickerCard({super.key, required this.icon, required this.onTap});

  final CustomIconCardDto icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = icon.name;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Center(
                  child: IconRefPreview(
                    iconRef: IconRefDto(
                      id: icon.id,
                      iconSourceType: IconSourceType.custom,
                      customIconId: icon.id,
                    ),
                    fallbackIcon: Icons.image_outlined,
                    size: 44,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
