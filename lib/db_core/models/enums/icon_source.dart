enum IconSourceType { db, iconPack }

extension IconSourceTypeX on IconSourceType {
  String get value => switch (this) {
    IconSourceType.db => 'db',
    IconSourceType.iconPack => 'iconPack',
  };

  static IconSourceType? tryParse(String? value) {
    return switch (value) {
      'db' => IconSourceType.db,
      'iconPack' => IconSourceType.iconPack,
      _ => null,
    };
  }
}
