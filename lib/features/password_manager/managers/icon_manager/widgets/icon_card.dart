import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/main_store/models/dto/icon_dto.dart';
import 'package:hoplixi/main_store/provider/dao_providers.dart';

/// Виджет карточки иконки с асинхронной загрузкой данных
class IconCard extends ConsumerWidget {
  final IconCardDto icon;
  final Uint8List? iconData; // Бинарные данные иконки (опционально)
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const IconCard({
    super.key,
    required this.icon,
    this.iconData,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Если данные пусты или нет, загружаем асинхронно
    final shouldLoadData = iconData == null || iconData!.isEmpty;

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
              Expanded(
                child: Center(
                  child: shouldLoadData
                      ? _buildIconAsync(ref)
                      : _buildIcon(iconData!),
                ),
              ),
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
                icon.type,
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
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError ||
            snapshot.data == null ||
            snapshot.data!.isEmpty) {
          logWarning('Failed to load icon data for ID: ${icon.id}');
          return const Icon(Icons.image_not_supported, size: 64, color: Colors.grey);
        }

        return _buildIcon(snapshot.data!);
      },
    );
  }

  /// Загрузить данные иконки из БД
  Future<Uint8List?> _loadIconData(WidgetRef ref) async {
    try {
      final iconDao = await ref.read(iconDaoProvider.future);
      return await iconDao.getIconData(icon.id);
    } catch (e) {
      logError('Error loading icon data for ID: ${icon.id}', error: e);
      return null;
    }
  }

  /// Построить иконку из данных
  Widget _buildIcon(Uint8List iconDataBytes) {
    if (iconDataBytes.isEmpty) {
      return const Icon(Icons.image_not_supported, size: 64, color: Colors.grey);
    }

    logTrace(
      'Building icon preview for icon ID: ${icon.id}, Type: ${icon.type}',
    );

    // Определяем тип иконки по расширению
    if (icon.type == 'svg') {
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
