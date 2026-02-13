import 'resource.dart';

class ResourceList {
  String? sort;
  String? path;
  List<Resource>? items;
  int? limit;
  int? offset;
  int? total;

  ResourceList({
    this.sort,
    this.path,
    this.items,
    this.limit,
    this.offset,
    this.total,
  });

  factory ResourceList.fromJson(Map<String, dynamic> json) {
    return ResourceList(
      sort: json['sort'],
      path: json['path'],
      items: (json['items'] as List?)
          ?.map((e) => Resource.fromJson(e as Map<String, dynamic>))
          .toList(),
      limit: json['limit'],
      offset: json['offset'],
      total: json['total'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sort': sort,
      'path': path,
      'items': items?.map((e) => e.toJson()).toList(),
      'limit': limit,
      'offset': offset,
      'total': total,
    };
  }
}
