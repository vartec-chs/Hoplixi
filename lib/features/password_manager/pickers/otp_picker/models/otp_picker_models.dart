/// Результат выбора OTP
class OtpPickerResult {
  final String id;
  final String name;

  const OtpPickerResult({required this.id, required this.name});
}

/// Результат выбора нескольких OTP
class OtpPickerMultiResult {
  final List<OtpPickerResult> otps;

  const OtpPickerMultiResult({this.otps = const []});

  bool get isEmpty => otps.isEmpty;
  bool get isNotEmpty => otps.isNotEmpty;
  int get length => otps.length;
}

/// Состояние данных OTP
class OtpPickerData {
  final List<dynamic> otps;
  final bool hasMore;
  final bool isLoadingMore;
  final String? excludeOtpId;

  const OtpPickerData({
    this.otps = const [],
    this.hasMore = false,
    this.isLoadingMore = false,
    this.excludeOtpId,
  });

  OtpPickerData copyWith({
    List<dynamic>? otps,
    bool? hasMore,
    bool? isLoadingMore,
    String? excludeOtpId,
  }) {
    return OtpPickerData(
      otps: otps ?? this.otps,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      excludeOtpId: excludeOtpId ?? this.excludeOtpId,
    );
  }
}
