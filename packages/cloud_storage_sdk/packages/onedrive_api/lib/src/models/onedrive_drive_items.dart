import 'onedrive_drive_item.dart';

/// OneDrive 드라이브 아이템 목록을 나타내는 클래스입니다.
class OneDriveDriveItems {
  final List<OneDriveDriveItem> value;
  final String? nextLink;

  OneDriveDriveItems({required this.value, this.nextLink});

  factory OneDriveDriveItems.fromJson(Map<String, dynamic> json) {
    return OneDriveDriveItems(
      value: (json['value'] as List)
          .map((e) => OneDriveDriveItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      nextLink: json['@odata.nextLink'] as String?,
    );
  }

  /// 더 불러올 데이터가 있는지 확인합니다.
  bool get hasMore => nextLink != null;
}
