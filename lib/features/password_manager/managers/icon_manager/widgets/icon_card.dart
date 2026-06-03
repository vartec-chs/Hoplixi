import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/vault_db/core/models/dto/system/custom_icon_dto.dart';
import 'package:hoplixi/vault_db/core/scheme/tables/system/icons/custom_icons.dart';
import 'package:hoplixi/vault_db/providers/providers.dart';

/// Виджет карточки иконки с асинхронной загрузкой данных
class IconCard extends ConsumerWidget {
  final CustomIconCardDto icon;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const IconCard({super.key, required this.icon, this.onTap, this.onLongPress});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Иконка
              Expanded(child: Center(child: _buildIconAsync(ref))),
              const SizedBox(height: 8),
              // Название
              Text(
                icon.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              // Тип иконки
              Text(
                icon.format.name.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Загрузить и показать иконку асинхронно
  Widget _buildIconAsync(WidgetRef ref) {
    return FutureBuilder<Uint8List?>(
      future: _loadIconData(ref),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            width: 64,
            height: 64,
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        if (snapshot.hasError ||
            snapshot.data == null ||
            snapshot.data!.isEmpty) {
          return const Icon(
            Icons.image_not_supported,
            size: 64,
            color: Colors.grey,
          );
        }

        return _buildIcon(snapshot.data!, icon.format);
      },
    );
  }

  /// Загрузить данные иконки из БД
  Future<Uint8List?> _loadIconData(WidgetRef ref) async {
    try {
      final repos = await ref.read(vaultRepositories.future);
      final result = await repos.icon.getCustomIcon(icon.id);
      return result.getOrNull()?.getOrNull()?.data;
    } catch (e) {
      logError('Error loading icon data for ID: ${icon.id}', error: e);
      return null;
    }
  }

  /// Построить иконку из данных
  Widget _buildIcon(Uint8List iconDataBytes, CustomIconFormat format) {
    if (iconDataBytes.isEmpty) {
      return const Icon(
        Icons.image_not_supported,
        size: 64,
        color: Colors.grey,
      );
    }

    logTrace('Building icon preview for icon ID: ${icon.id}, Format: $format');

    if (format == CustomIconFormat.svg) {
      // SVG иконка
      return SvgPicture.memory(
        iconDataBytes,
        fit: BoxFit.contain,
        width: 64,
        height: 64,
        placeholderBuilder: (context) => const SizedBox(
          width: 64,
          height: 64,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    } else {
      // Обычная растровая иконка (PNG, JPG, etc.)
      return Image.memory(
        iconDataBytes,
        fit: BoxFit.contain,
        width: 64,
        height: 64,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.broken_image, size: 64);
        },
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded) {
            return child;
          }
          return AnimatedOpacity(
            opacity: frame == null ? 0 : 1,
            duration: const Duration(milliseconds: 500),
            child: child,
          );
        },
      );
    }
  }
}
