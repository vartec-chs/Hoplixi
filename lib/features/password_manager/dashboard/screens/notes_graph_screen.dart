import 'package:flutter/material.dart';
import 'package:flutter_graph_view/flutter_graph_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/logger/index.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/main_store/models/graph_data.dart';
import 'package:hoplixi/main_store/provider/dao_providers.dart';
import 'package:hoplixi/routing/paths.dart';

final _notesGraphDataProvider = FutureProvider.autoDispose<GraphData>((
  ref,
) async {
  final dao = await ref.watch(noteLinkDaoProvider.future);
  return dao.getGraphData();
});

/// Экран графа связей заметок (в стиле Obsidian).
class NotesGraphScreen extends ConsumerWidget {
  const NotesGraphScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final graphAsync = ref.watch(_notesGraphDataProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Граф заметок'),

        actions: [
          IconButton(
            tooltip: 'Обновить',
            onPressed: () => ref.invalidate(_notesGraphDataProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: graphAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) {
          logError('Failed to load notes graph', error: e, stackTrace: s);
          return Center(
            child: Text(
              'Не удалось загрузить граф',
              style: theme.textTheme.bodyLarge,
            ),
          );
        },
        data: (data) {
          final vertexCount = data.vertexes.length;
          final edgeCount = data.edges.length;

          if (vertexCount == 0) {
            return Center(
              child: Text(
                'Нет заметок для отображения',
                style: theme.textTheme.bodyLarge,
              ),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: Row(
                  children: [
                    Text(
                      'Узлы: $vertexCount',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Связи: $edgeCount',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: RepaintBoundary(
                  child: _NotesGraphView(
                    key: ValueKey('graph_${vertexCount}_$edgeCount'),
                    data: data,
                    theme: theme,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Виджет графа заметок с force-directed алгоритмом.
class _NotesGraphView extends StatefulWidget {
  const _NotesGraphView({super.key, required this.data, required this.theme});

  final GraphData data;
  final ThemeData theme;

  @override
  State<_NotesGraphView> createState() => _NotesGraphViewState();
}

class _NotesGraphViewState extends State<_NotesGraphView> {
  Options? _options;
  GraphStyle? _graphStyle;
  ForceDirected? _algorithm;

  void _initGraphOptions() {
    // Создаём GraphStyle один раз
    _graphStyle = GraphStyle()
      ..tagColorByIndex = [
        widget.theme.colorScheme.primary,
        widget.theme.colorScheme.secondary,
        widget.theme.colorScheme.tertiary,
        widget.theme.colorScheme.primaryContainer,
      ]
      ..hoverOpacity = 0.3
      ..vertexTextStyleGetter = (vertex, shape) {
        final opacity = shape?.isWeaken(vertex) == true ? 0.5 : 1.0;
        return TextStyle(
          color: widget.theme.colorScheme.onSurface.withValues(alpha: opacity),
          fontSize: 11,
        );
      };

    // Создаём Options один раз
    _options = Options();
    _options!.enableHit = true;
    _options!.hoverable = true;
    _options!.panelDelay = const Duration(milliseconds: 200);
    _options!.showText = true;
    _options!.textGetter = (vertex) {
      final title = vertex.data is Map
          ? (vertex.data['title']?.toString() ?? '')
          : '';
      return title.length > 20 ? '${title.substring(0, 17)}...' : title;
    };
    _options!.edgePanelBuilder = _buildEdgePanel;
    _options!.vertexPanelBuilder = _buildVertexPanel;

    // Обработка клика по вершине
    // Примечание: библиотека вызывает onVertexTapUp только когда есть hoverVertex
    _options!.onVertexTapUp = (vertex, event) {
      final id = vertex.id?.toString() ?? '';
      logInfo('Vertex tap up: id=$id');
      if (id.isNotEmpty && mounted) {
        context.push(AppRoutesPaths.dashboardEntityEdit(EntityType.note, id));
      }
    };

    _options!.edgeShape = EdgeLineShape();
    _options!.vertexShape = VertexCircleShape();
    _options!.backgroundBuilder = (ctx) =>
        ColoredBox(color: widget.theme.colorScheme.surfaceContainerLowest);
    _options!.graphStyle = _graphStyle!;

    // Создаём алгоритм с декораторами, притягивающими к центру
    // Убран CoulombCenterDecorator, который отталкивает от центра
    _algorithm = ForceDirected(
      decorators: [
        CoulombDecorator(),
        HookeBorderDecorator(),
        HookeDecorator(),
        HookeCenterDecorator(), // Притягивает к центру
        ForceDecorator(),
        ForceMotionDecorator(),
        TimeCounterDecorator(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Используем LayoutBuilder для получения размера и Center для центрирования
    return LayoutBuilder(
      builder: (context, constraints) {
        // Инициализируем опции при первом build, когда размер известен
        if (_options == null) {
          _initGraphOptions();
        }

        return Center(
          child: SizedBox(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            child: FlutterGraphWidget(
              data: {
                'vertexes': widget.data.vertexes
                    .map((v) => v.toJson())
                    .toList(),
                'edges': widget.data.edges.map((e) => e.toJson()).toList(),
              },
              algorithm: _algorithm!,
              convertor: MapConvertor(),
              options: _options!,
            ),
          ),
        );
      },
    );
  }

  Widget _buildEdgePanel(Edge edge) {
    final pos = edge.g?.options?.pointer ?? Vector2.zero();

    return Stack(
      children: [
        Positioned(
          left: pos.x + 8,
          top: pos.y + 8,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: widget.theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: widget.theme.shadowColor.withAlpha(30),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                'Связь',
                style: widget.theme.textTheme.bodySmall?.copyWith(
                  color: widget.theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVertexPanel(Vertex vertex) {
    final pos = vertex.g?.options?.localToGlobal(vertex.position);
    final x = pos?.x ?? 0.0;
    final y = pos?.y ?? 0.0;
    final id = vertex.id?.toString() ?? '';
    final title = vertex.data is Map
        ? (vertex.data['title']?.toString() ?? id)
        : id;
    final degree = vertex.degree;

    return Stack(
      children: [
        Positioned(
          left: x + vertex.radius + 12,
          top: y - 16,
          child: Material(
            color: Colors.transparent,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: widget.theme.shadowColor.withAlpha(40),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
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
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.link,
                          size: 14,
                          color: widget.theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$degree связей',
                          style: widget.theme.textTheme.bodySmall?.copyWith(
                            color: widget.theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
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
        ),
      ],
    );
  }
}
