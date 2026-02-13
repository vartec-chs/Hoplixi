import 'onedrive_drive_item.dart';
import 'onedrive_user.dart';

/// OneDrive 드라이브 정보를 나타내는 클래스입니다.
class OneDriveDrive {
  final String id;
  final String driveType;
  final OneDriveUser? owner;
  final OneDriveDriveItem? root;
  final int? quota;

  OneDriveDrive({
    required this.id,
    required this.driveType,
    this.owner,
    this.root,
    this.quota,
  });

  factory OneDriveDrive.fromJson(Map<String, dynamic> json) {
    return OneDriveDrive(
      id: json['id'] as String,
      driveType: json['driveType'] as String,
      owner: json['owner'] != null
          ? OneDriveUser.fromJson(json['owner'] as Map<String, dynamic>)
          : null,
      root: json['root'] != null
          ? OneDriveDriveItem.fromJson(json['root'] as Map<String, dynamic>)
          : null,
      quota: json['quota']?['total'] as int?,
    );
  }
}
