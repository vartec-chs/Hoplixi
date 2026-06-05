import 'package:flutter/material.dart';
import 'package:flutter_graph_view/flutter_graph_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/features/password_manager/dashboard/dashboard.dart';
import 'package:hoplixi/routing/paths.dart';
import 'package:hoplixi/vault_db/core/models/graph_data.dart';
import 'package:hoplixi/vault_db/providers/api_providers.dart';

const _logTag = 'NotesGraphScreen';

final _notesGraphDataProvider = FutureProvider.autoDispose<GraphData>((
  ref,
) async {
  final api = await ref.watch(vaultApiProvider.future);
  final result = await api.relationsService.getNotesGraph();
  return result.getOrThrow();
});

/// Экран графа связей заметок.
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
        error: (error, stackTrace) {
          logError(
            'Failed to load notes graph',
            error: error,
            stackTrace: stackTrace,
            tag: _logTag,
          );
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

class _NotesGraphView extends StatefulWidget {
  const _NotesGraphView({super.key, required this.data, required this.theme});

  final GraphData data;
  final ThemeData theme;

  @override
  State<_NotesGraphView> createState() => _NotesGraphViewState();
}

class _NotesGraphViewState extends State<_NotesGraphView> {
  late final Options _options;
  late final ForceDirected _algorithm;

  @override
  void initState() {
    super.initState();
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
      ..edgePanelBuilder = _buildEdgePanel
      ..vertexPanelBuilder = _buildVertexPanel
      ..onVertexTapUp = (vertex, _) {
        final id = vertex.id?.toString() ?? '';
        logInfo('Open note graph vertex: $id', tag: _logTag);
        if (id.isNotEmpty && mounted) {
          context.push(AppRoutesPaths.dashboardEntityEdit(EntityType.note, id));
        }
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
          widget.theme.colorScheme.primaryContainer,
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
        return Center(
          child: SizedBox(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            child: FlutterGraphWidget(
              data: _toGraphWidgetData(widget.data),
              algorithm: _algorithm,
              convertor: MapConvertor(),
              options: _options,
            ),
          ),
        );
      },
    );
  }

  Map<String, List<Map<String, Object?>>> _toGraphWidgetData(GraphData data) {
    return {
      'vertexes': data.vertexes
          .map(
            (vertex) => {
              'id': vertex.id,
              'tag': vertex.tag,
              'tags': vertex.tags,
              'data': {'title': vertex.title},
            },
          )
          .toList(),
      'edges': data.edges
          .map(
            (edge) => {
              'srcId': edge.srcId,
              'dstId': edge.dstId,
              'edgeName': edge.edgeName,
              'ranking': edge.ranking,
            },
          )
          .toList(),
    };
  }

  String _vertexTitle(Vertex vertex) {
    final data = vertex.data;
    final title = data is Map ? data['title']?.toString() ?? '' : '';
    if (title.length <= 20) return title;
    return '${title.substring(0, 17)}...';
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
                edge.edgeName,
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
    final title = _vertexTitle(vertex);
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
                  borderRadius: BorderRadius.circular(8),
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
