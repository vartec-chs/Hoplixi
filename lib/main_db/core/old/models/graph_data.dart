import 'package:freezed_annotation/freezed_annotation.dart';

part 'graph_data.freezed.dart';
part 'graph_data.g.dart';

/// Структура данных для графа заметок
@freezed
sealed class GraphData with _$GraphData {
  const factory GraphData({
    /// Список вершин (узлов) графа
    required List<VertexData> vertexes,

    /// Список рёбер (связей) графа
    required List<EdgeData> edges,
  }) = _GraphData;

  factory GraphData.fromJson(Map<String, dynamic> json) =>
      _$GraphDataFromJson(json);
}

/// Данные вершины графа
@freezed
sealed class VertexData with _$VertexData {
  const factory VertexData({
    /// Уникальный идентификатор вершины (ID заметки)
    required String id,

    /// Основной тег для раскраски (tag0, tag1, tag2, tag3)
    required String tag,

    /// Список всех тегов вершины
    required List<String> tags,

    /// Заголовок заметки
    required String title,
  }) = _VertexData;

  factory VertexData.fromJson(Map<String, dynamic> json) =>
      _$VertexDataFromJson(json);
}

/// Данные ребра графа
@freezed
sealed class EdgeData with _$EdgeData {
  const factory EdgeData({
    /// ID исходной вершины (заметки, откуда идёт ссылка)
    required String srcId,

    /// ID целевой вершины (заметки, куда идёт ссылка)
    required String dstId,

    /// Тип связи (обычно 'link')
    required String edgeName,

    /// Ранжирование для сортировки (timestamp создания связи)
    required int ranking,
  }) = _EdgeData;

  factory EdgeData.fromJson(Map<String, dynamic> json) =>
      _$EdgeDataFromJson(json);
}
