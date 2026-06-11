import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_graph_view/flutter_graph_view.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/features/password_manager/dashboard/dashboard.dart';
import 'package:hoplixi/features/password_manager/item_links_graph/flutter_graph_view_data_adapter.dart';
import 'package:hoplixi/features/password_manager/item_links_graph/widgets/floating_panel.dart';
import 'package:hoplixi/routing/paths.dart';
import 'package:hoplixi/vault_db/core/models/item_links_graph/item_links_graph_models.dart';
import 'package:hoplixi/vault_db/core/scheme/tables/vault_items/vault_items.dart';

const _logTag = 'ItemLinksGraphView';

class ItemLinksGraphView extends StatefulWidget {
  const ItemLinksGraphView({
    super.key,
    required this.graph,
    required this.theme,
  });

  final ItemLinksGraph graph;
  final ThemeData theme;

  @override
  State<ItemLinksGraphView> createState() => _ItemLinksGraphViewState();
}

class _ItemLinksGraphViewState extends State<ItemLinksGraphView> {
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
      ..vertexShape = _VertexTitleCircleShape()
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
            fontWeight: FontWeight.w600,
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
    if (title.length <= 24) return title;
    return '${title.substring(0, 21)}...';
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
          child: FloatingPanel(
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
          child: FloatingPanel(
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

final class _VertexTitleCircleShape extends VertexCircleShape {
  _VertexTitleCircleShape()
    : super(textRenderer: _VertexTitleAboveTextRenderer()) {
    textRenderer?.shape = this;
  }

  @override
  void render(Vertex vertex, ui.Canvas canvas, paint, paintLayers) {
    canvas.drawCircle(ui.Offset.zero, vertex.radiusZoom, paint);

    if (vertex.g?.options?.showText ?? true) {
      textRenderer?.render(vertex, canvas, paint);
    }

    decorators?.forEach((decorator) {
      decorator.decorate(vertex, canvas, paint, paintLayers);
    });
  }
}

final class _VertexTitleAboveTextRenderer extends VertexTextRenderer {
  _VertexTitleAboveTextRenderer();

  static const double _maxTextWidth = 132;

  @override
  void render(Vertex<dynamic> vertex, ui.Canvas canvas, ui.Paint paint) {
    if (vertex.zoom <= 0.3) return;

    final text = vertex.g?.options?.textGetter.call(vertex) ?? '';
    if (text.isEmpty) return;

    final vertexTextStyle = vertex.g?.options?.graphStyle.vertexTextStyleGetter
        ?.call(vertex, shape);
    final textStyle = super.textStyleGetter(
      vertexTextStyle,
      paint,
      scale: 1 / vertex.zoom,
    );
    final painter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 2,
      ellipsis: '...',
      text: TextSpan(style: textStyle, text: text),
    )..layout(maxWidth: _maxTextWidth);

    final offset = ui.Offset(
      -painter.width / 2,
      -vertex.radiusZoom - painter.height - 8,
    );
    painter.paint(canvas, offset);
  }
}
