import 'package:flutter/material.dart';
import 'package:flutter_graph_view/flutter_graph_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/features/password_manager/dashboard/dashboard.dart';
import 'package:hoplixi/features/password_manager/item_links_graph/flutter_graph_view_data_adapter.dart';
import 'package:hoplixi/routing/paths.dart';
import 'package:hoplixi/vault_db/core/models/item_links_graph/item_links_graph_models.dart';
import 'package:hoplixi/vault_db/core/scheme/tables/system/item_link/item_links.dart';
import 'package:hoplixi/vault_db/core/scheme/tables/vault_items/vault_items.dart';
import 'package:hoplixi/vault_db/providers/service_providers.dart';

const _logTag = 'ItemLinksGraphScreen';

final _graphModeProvider =
    NotifierProvider.autoDispose<_GraphModeNotifier, ItemLinksGraphMode>(
      _GraphModeNotifier.new,
    );

final class _GraphModeNotifier extends Notifier<ItemLinksGraphMode> {
  @override
  ItemLinksGraphMode build() => const AllItemLinksGraphMode();

  void setMode(ItemLinksGraphMode mode) {
    state = mode;
  }
}

final _itemLinksGraphProvider =
    FutureProvider.autoDispose<ItemLinksGraphLoadResult>((ref) async {
      final mode = ref.watch(_graphModeProvider);
      final service = await ref.watch(loadItemLinksGraphServiceProvider.future);
      final result = await service(mode);
      return result.getOrThrow();
    });

/// Screen for the graph of directed item_links between VaultItems.
class ItemLinksGraphScreen extends ConsumerWidget {
  const ItemLinksGraphScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final graphAsync = ref.watch(_itemLinksGraphProvider);
    final mode = ref.watch(_graphModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Граф связей'),
        actions: [
          IconButton(
            tooltip: 'Обновить',
            onPressed: () => ref.invalidate(_itemLinksGraphProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          _ItemLinksGraphFilters(
            mode: mode,
            onModeChanged: (nextMode) {
              ref.read(_graphModeProvider.notifier).setMode(nextMode);
            },
          ),
          const Divider(height: 1),
          Expanded(
            child: graphAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) {
                logError(
                  'Failed to load item links graph',
                  error: error,
                  stackTrace: stackTrace,
                  tag: _logTag,
                );
                return _GraphMessage(
                  icon: Icons.error_outline,
                  title: 'Не удалось загрузить граф',
                  subtitle: 'Попробуйте обновить данные.',
                  action: FilledButton.icon(
                    onPressed: () => ref.invalidate(_itemLinksGraphProvider),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Повторить'),
                  ),
                );
              },
              data: (result) {
                return switch (result) {
                  ItemLinksGraphFilterRequired() => const _GraphMessage(
                    icon: Icons.filter_alt_outlined,
                    title: 'Выберите тип связи',
                    subtitle:
                        'Для режима по типам нужен хотя бы один выбранный тип.',
                  ),
                  ItemLinksGraphLoaded(:final graph) => _GraphBody(
                    graph: graph,
                    theme: theme,
                  ),
                };
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemLinksGraphFilters extends StatelessWidget {
  const _ItemLinksGraphFilters({
    required this.mode,
    required this.onModeChanged,
  });

  final ItemLinksGraphMode mode;
  final ValueChanged<ItemLinksGraphMode> onModeChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedTypes = switch (mode) {
      AllItemLinksGraphMode() => <ItemLinkType>{},
      RelationTypesItemLinksGraphMode(:final relationTypes) => relationTypes,
    };
    final isAll = mode is AllItemLinksGraphMode;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(
                value: true,
                icon: Icon(Icons.hub_outlined),
                label: Text('Все связи'),
              ),
              ButtonSegment(
                value: false,
                icon: Icon(Icons.filter_alt_outlined),
                label: Text('По типам'),
              ),
            ],
            selected: {isAll},
            onSelectionChanged: (selection) {
              final nextIsAll = selection.first;
              onModeChanged(
                nextIsAll
                    ? const AllItemLinksGraphMode()
                    : RelationTypesItemLinksGraphMode(selectedTypes),
              );
            },
          ),
          if (!isAll) ...[
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final type in ItemLinkType.values) ...[
                    FilterChip(
                      label: Text(_itemLinkTypeLabel(type)),
                      selected: selectedTypes.contains(type),
                      onSelected: (selected) {
                        final nextTypes = {...selectedTypes};
                        if (selected) {
                          nextTypes.add(type);
                        } else {
                          nextTypes.remove(type);
                        }
                        onModeChanged(
                          RelationTypesItemLinksGraphMode(nextTypes),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            if (selectedTypes.isEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'SQL-запрос не выполняется, пока не выбран тип связи.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _GraphBody extends StatelessWidget {
  const _GraphBody({required this.graph, required this.theme});

  final ItemLinksGraph graph;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    if (graph.isEmpty) {
      return const _GraphMessage(
        icon: Icons.hub_outlined,
        title: 'Связей пока нет',
        subtitle: 'Граф показывает только элементы, участвующие в связях.',
      );
    }

    final relationTypes = graph.edges.map((edge) => edge.relationType).toSet();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
          child: Row(
            children: [
              Text(
                'Узлы: ${graph.nodes.length}',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(width: 12),
              Text(
                'Связи: ${graph.edges.length}',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        _ItemLinksGraphLegend(relationTypes: relationTypes),
        const Divider(height: 1),
        Expanded(
          child: RepaintBoundary(
            child: _ItemLinksGraphView(
              key: ValueKey(
                'graph_${graph.nodes.length}_${graph.edges.length}',
              ),
              graph: graph,
              theme: theme,
            ),
          ),
        ),
      ],
    );
  }
}

class _ItemLinksGraphLegend extends StatelessWidget {
  const _ItemLinksGraphLegend({required this.relationTypes});

  final Set<ItemLinkType> relationTypes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: Row(
        children: [
          Icon(Icons.arrow_forward, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 4),
          Text('source -> target', style: theme.textTheme.bodySmall),
          const SizedBox(width: 16),
          for (final type in relationTypes) ...[
            Icon(Icons.link, size: 14, color: theme.colorScheme.secondary),
            const SizedBox(width: 4),
            Text(_itemLinkTypeLabel(type), style: theme.textTheme.bodySmall),
            const SizedBox(width: 12),
          ],
        ],
      ),
    );
  }
}

class _ItemLinksGraphView extends StatefulWidget {
  const _ItemLinksGraphView({
    super.key,
    required this.graph,
    required this.theme,
  });

  final ItemLinksGraph graph;
  final ThemeData theme;

  @override
  State<_ItemLinksGraphView> createState() => _ItemLinksGraphViewState();
}

class _ItemLinksGraphViewState extends State<_ItemLinksGraphView> {
  late final Options _options;
  late final ForceDirected _algorithm;
  late final Map<String, String> _edgeLabelsById;
  late final Map<String, List<Map<String, Object?>>> _data;

  @override
  void initState() {
    super.initState();
    final converted = const FlutterGraphViewDataAdapter().convert(widget.graph);
    _data = converted.data;
    _edgeLabelsById = converted.edgeLabelsById;
    _options = _buildOptions();
    _algorithm = ForceDirected(
      decorators: [
        CoulombDecorator(),
        HookeBorderDecorator(),
        HookeDecorator(),
        HookeCenterDecorator(),
        ForceDecorator(),
        ForceMotionDecorator(),
        TimeCounterDecorator(),
      ],
    );
  }

  Options _buildOptions() {
    return Options()
      ..enableHit = true
      ..hoverable = true
      ..panelDelay = const Duration(milliseconds: 200)
      ..showText = true
      ..textGetter = _vertexTitle
      ..edgeTextGetter = (edge) {
        return _edgeLabelsById[edge.edgeName] ?? '';
      }
      ..edgePanelBuilder = _buildEdgePanel
      ..vertexPanelBuilder = _buildVertexPanel
      ..onVertexTapUp = (vertex, _) {
        final id = vertex.id?.toString() ?? '';
        final typeName = _vertexData(vertex, 'type');
        final vaultType = _vaultItemTypeByName(typeName);
        if (id.isEmpty || vaultType == null || !mounted) return;

        final entityType = EntityType.fromVaultItemType(vaultType);
        logInfo('Open item graph vertex: $id', tag: _logTag);
        context.push(AppRoutesPaths.dashboardEntityView(entityType, id));
      }
      ..edgeShape = EdgeLineShape()
      ..vertexShape = VertexCircleShape()
      ..backgroundBuilder = ((context) =>
          ColoredBox(color: widget.theme.colorScheme.surfaceContainerLowest))
      ..graphStyle = (GraphStyle()
        ..tagColorByIndex = [
          widget.theme.colorScheme.primary,
          widget.theme.colorScheme.secondary,
          widget.theme.colorScheme.tertiary,
          widget.theme.colorScheme.error,
          widget.theme.colorScheme.primaryContainer,
          widget.theme.colorScheme.secondaryContainer,
          widget.theme.colorScheme.tertiaryContainer,
          widget.theme.colorScheme.surfaceTint,
        ]
        ..hoverOpacity = 0.3
        ..vertexTextStyleGetter = (vertex, shape) {
          final opacity = shape?.isWeaken(vertex) == true ? 0.5 : 1.0;
          return TextStyle(
            color: widget.theme.colorScheme.onSurface.withValues(
              alpha: opacity,
            ),
            fontSize: 11,
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: FlutterGraphWidget(
            data: _data,
            algorithm: _algorithm,
            convertor: MapConvertor(),
            options: _options,
          ),
        );
      },
    );
  }

  String _vertexTitle(Vertex vertex) {
    final title = _vertexData(vertex, 'title');
    if (title.length <= 20) return title;
    return '${title.substring(0, 17)}...';
  }

  String _vertexData(Vertex vertex, String key) {
    final data = vertex.data;
    if (data is Map) return data[key]?.toString() ?? '';
    return '';
  }

  Widget _buildEdgePanel(Edge edge) {
    final pos = edge.g?.options?.pointer ?? Vector2.zero();
    final label = _edgeLabelsById[edge.edgeName] ?? edge.edgeName;

    return Stack(
      children: [
        Positioned(
          left: pos.x + 8,
          top: pos.y + 8,
          child: _FloatingPanel(
            child: Text(label, style: widget.theme.textTheme.bodySmall),
          ),
        ),
      ],
    );
  }

  Widget _buildVertexPanel(Vertex vertex) {
    final pos = vertex.g?.options?.localToGlobal(vertex.position);
    final x = pos?.x ?? 0.0;
    final y = pos?.y ?? 0.0;
    final title = _vertexData(vertex, 'title');
    final type = _vaultItemTypeByName(_vertexData(vertex, 'type'));
    final label = type == null
        ? 'Элемент'
        : EntityType.fromVaultItemType(type).label;

    return Stack(
      children: [
        Positioned(
          left: x + vertex.radius + 12,
          top: y - 16,
          child: _FloatingPanel(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: widget.theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(label, style: widget.theme.textTheme.bodySmall),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.open_in_new,
                        size: 14,
                        color: widget.theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Нажмите чтобы открыть',
                        style: widget.theme.textTheme.bodySmall?.copyWith(
                          color: widget.theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  VaultItemType? _vaultItemTypeByName(String name) {
    for (final value in VaultItemType.values) {
      if (value.name == name) return value;
    }
    return null;
  }
}

class _FloatingPanel extends StatelessWidget {
  const _FloatingPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withAlpha(40),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

class _GraphMessage extends StatelessWidget {
  const _GraphMessage({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}

String _itemLinkTypeLabel(ItemLinkType type) {
  return switch (type) {
    ItemLinkType.related => 'Связано',
    ItemLinkType.note => 'Заметка',
    ItemLinkType.attachment => 'Вложение',
    ItemLinkType.otpForPassword => 'OTP для пароля',
    ItemLinkType.supportContact => 'Контакт поддержки',
    ItemLinkType.purchaseDocument => 'Документ покупки',
    ItemLinkType.identityScan => 'Скан документа',
    ItemLinkType.identityPhoto => 'Фото документа',
    ItemLinkType.sshPublicKeyFile => 'SSH public key',
    ItemLinkType.sshPrivateKeyFile => 'SSH private key',
    ItemLinkType.certificateFile => 'Файл сертификата',
    ItemLinkType.certificatePrivateKeyFile => 'Ключ сертификата',
    ItemLinkType.other => 'Другое',
  };
}
