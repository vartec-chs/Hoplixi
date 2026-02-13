class GDDrive {
  /// The time at which the shared drive was created (RFC 3339 date-time).
  DateTime? createdTime;

  /// Whether the shared drive is hidden from default view.
  bool? hidden;

  String? id;

  String? name;

  GDDrive({this.createdTime, this.hidden, this.id, this.name});

  // JSON으로 변환하는 메서드
  Map<String, dynamic> toJson() {
    return {
      'createdTime': createdTime?.toUtc().toIso8601String(),
      'hidden': hidden,
      'id': id,
      'name': name,
    };
  }

  // JSON에서 객체를 생성하는 팩토리 메서드
  factory GDDrive.fromJson(Map<String, dynamic> json) {
    return GDDrive(
      createdTime: json['createdTime'] != null
          ? DateTime.parse(json['createdTime']).toLocal()
          : null,
      hidden: json['hidden'],
      id: json['id'],
      name: json['name'],
    );
  }
}
