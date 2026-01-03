import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/models/dto/icon_dto.dart';
import 'package:hoplixi/main_store/models/enums/entity_types.dart';
import 'package:hoplixi/main_store/provider/dao_providers.dart';
import 'package:hoplixi/routing/paths.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

import 'provider/icon_list_provider.dart';
import 'widgets/icon_list_view.dart';
import 'widgets/icon_manager_app_bar.dart';

/// Экран управления иконками с фильтрацией и пагинацией
class IconManagerScreen extends ConsumerStatefulWidget {
  const IconManagerScreen({super.key, required this.entity});

   final EntityType entity;

  @override
  ConsumerState<IconManagerScreen> createState() => _IconManagerScreenState();
}

class _IconManagerScreenState extends ConsumerState<IconManagerScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _refresh() {
    final notifier = ref.read(iconListProvider.notifier);
    notifier.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          const IconManagerAppBar(),
          IconListView(
            scrollController: _scrollController,
            onRefresh: _refresh,
            onIconTap: _showIconDetails,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'iconManagerFab',
        onPressed: () {
   
          final result = context.push<bool>(
            AppRoutesPaths.iconAddForEntity(widget.entity),
          );

          result.then((added) {
            if (added == true) {
              _refresh();
            }
          });
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildIconPreview(IconsData icon) {
    return _IconPreviewAsync(
      iconId: icon.id,
      type: icon.type.toString(),
      ref: ref,
    );
  }

  void _showIconDetails(BuildContext context, IconsData icon) {
    final iconDto = IconCardDto(
      id: icon.id,
      name: icon.name,
      type: icon.type.toString(),
      createdAt: icon.createdAt,
      modifiedAt: icon.modifiedAt,
    );

    WoltModalSheet.show(
      context: context,
      useRootNavigator: true,

      barrierDismissible: true,
      pageListBuilder: (modalContext) {
        return [
          WoltModalSheetPage(
            surfaceTintColor: Colors.transparent,
            hasTopBarLayer: true,
            topBarTitle: Text(
              icon.name,
              style: Theme.of(modalContext).textTheme.titleMedium,
            ),
            isTopBarLayerAlwaysVisible: true,
            leadingNavBarWidget: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(modalContext).pop(),
            ),
            trailingNavBarWidget: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Кнопка редактирования
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    Navigator.of(modalContext).pop();
                    final state = GoRouterState.of(
                      context,
                    ).pathParameters['entity'];
                    final entity = EntityType.fromId(state ?? '')!;
                    final result = context.push<bool>(
                      AppRoutesPaths.iconEditForEntity(entity, icon.id),
                    );

                    result.then((edited) {
                      if (edited == true) {
                        _refresh();
                      }
                    });
                  },
                  tooltip: 'Редактировать',
                ),
                // Кнопка удаления
                IconButton(
                  icon: const Icon(Icons.delete),
                  color: Theme.of(modalContext).colorScheme.error,
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: modalContext,
                      builder: (dialogContext) => AlertDialog(
                        title: const Text('Подтверждение'),
                        content: Text('Удалить иконку "${icon.name}"?'),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(false),
                            child: const Text('Отмена'),
                          ),
                          TextButton(
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(true),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            child: const Text('Удалить'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true && modalContext.mounted) {
                      try {
                        final iconDao = await ref.read(iconDaoProvider.future);
                        await iconDao.deleteIcon(icon.id);

                        // Обновляем список
                        _refresh();

                        if (modalContext.mounted) {
                          Navigator.of(modalContext).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Иконка успешно удалена'),
                            ),
                          );
                        }
                      } catch (e) {
                        if (modalContext.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Ошибка удаления: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    }
                  },
                  tooltip: 'Удалить',
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Превью иконки
                  Center(
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(modalContext).colorScheme.outline,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(child: _buildIconPreview(icon)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Информация об иконке
                  // _InfoRow(label: 'ID', value: icon.id),
                  // const SizedBox(height: 8),
                  _InfoRow(label: 'Тип', value: icon.type.value),
                  const SizedBox(height: 8),
                  _InfoRow(label: 'Создана', value: icon.createdAt.toString()),
                  const SizedBox(height: 8),
                  _InfoRow(
                    label: 'Изменена',
                    value: icon.modifiedAt.toString(),
                  ),
                  const SizedBox(height: 8),
                  // Размер загружается асинхронно
                  _SizeRow(iconId: icon.id, ref: ref),
                ],
              ),
            ),
          ),
        ];
      },
    );
  }
}

/// Виджет для асинхронного отображения иконки
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
          return const SizedBox(
            width: 100,
            height: 100,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError ||
            snapshot.data == null ||
            snapshot.data!.isEmpty) {
          return const Icon(Icons.broken_image, size: 100);
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
    final isSvg =
        type.toLowerCase() == 'icontype.svg' ||
        type.toLowerCase().contains('svg');

    if (isSvg) {
      return SvgPicture.memory(
        data,
        width: 100,
        height: 100,
        fit: BoxFit.contain,
        placeholderBuilder: (context) => const SizedBox(
          width: 100,
          height: 100,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    } else {
      return Image.memory(
        data,
        width: 100,
        height: 100,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.broken_image, size: 100);
        },
      );
    }
  }
}

/// Виджет для отображения размера иконки
class _SizeRow extends StatelessWidget {
  final String iconId;
  final WidgetRef ref;

  const _SizeRow({required this.iconId, required this.ref});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int?>(
      future: _loadIconSize(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 80,
                child: Text(
                  'Размер:',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: SizedBox(
                  width: 20,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ],
          );
        }

        if (snapshot.hasError || snapshot.data == null) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 80,
                child: Text(
                  'Размер:',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Ошибка загрузки',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          );
        }

        return _InfoRow(label: 'Размер', value: '${snapshot.data} байт');
      },
    );
  }

  Future<int?> _loadIconSize() async {
    try {
      final iconDao = await ref.read(iconDaoProvider.future);
      final data = await iconDao.getIconData(iconId);
      return data?.length;
    } catch (e) {
      return null;
    }
  }
}

/// Виджет для отображения строки информации
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}
