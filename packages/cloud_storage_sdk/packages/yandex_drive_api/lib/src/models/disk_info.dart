class DiskInfo {
  int? trashSize;
  int? totalSpace;
  int? usedSpace;
  Map<String, String>? systemFolders;

  DiskInfo({
    this.trashSize,
    this.totalSpace,
    this.usedSpace,
    this.systemFolders,
  });

  factory DiskInfo.fromJson(Map<String, dynamic> json) {
    return DiskInfo(
      trashSize: json['trash_size'],
      totalSpace: json['total_space'],
      usedSpace: json['used_space'],
      systemFolders: (json['system_folders'] as Map<String, dynamic>?)
          ?.cast<String, String>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'trash_size': trashSize,
      'total_space': totalSpace,
      'used_space': usedSpace,
      'system_folders': systemFolders,
    };
  }
}
