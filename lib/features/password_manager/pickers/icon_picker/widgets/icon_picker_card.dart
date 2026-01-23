import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hoplixi/main_store/models/dto/icon_dto.dart';
import 'package:hoplixi/main_store/provider/dao_providers.dart';

/// Виджет карточки иконки для picker
class IconPickerCard extends ConsumerWidget {
  final IconCardDto icon;
  final VoidCallback onTap;

  const IconPickerCard({super.key, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Превью иконки
              Expanded(
                child: _IconPreviewAsync(
                  iconId: icon.id,
                  type: icon.type,
                  ref: ref,
                ),
              ),
              const SizedBox(height: 8),
              // Название иконки
              Text(
                icon.name,
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

/// Виджет для асинхронного отображения иконки в picker
class _IconPreviewAsync extends StatelessWidget {
  final String iconId;
  final String type;
  final WidgetRef ref;

  const _IconPreviewAsync({
    required this.iconId,
    required this.type,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _loadIconData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError ||
            snapshot.data == null ||
            snapshot.data!.isEmpty) {
          return Center(
            child: Icon(
              Icons.broken_image,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
          );
        }

        return _buildIconPreview(snapshot.data!, type);
      },
    );
  }

  Future<Uint8List?> _loadIconData() async {
    try {
      final iconDao = await ref.read(iconDaoProvider.future);
      return await iconDao.getIconData(iconId);
    } catch (e) {
      return null;
    }
  }

  static Widget _buildIconPreview(Uint8List data, String type) {
    final isSvg = type == 'svg';

    if (isSvg) {
      return SvgPicture.memory(
        data,
        fit: BoxFit.contain,
        placeholderBuilder: (context) =>
            const Center(child: CircularProgressIndicator()),
      );
    } else {
      return Image.memory(
        data,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.broken_image, size: 48);
        },
      );
    }
  }
}
