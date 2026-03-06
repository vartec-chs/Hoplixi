import 'package:flutter/material.dart';

IconData getPlatformIcon(String platform) {
  return switch (platform) {
    'android' => Icons.phone_android,
    'ios' => Icons.phone_iphone,
    'windows' => Icons.desktop_windows,
    'macos' => Icons.laptop_mac,
    'linux' => Icons.computer,
    _ => Icons.devices,
  };
}
