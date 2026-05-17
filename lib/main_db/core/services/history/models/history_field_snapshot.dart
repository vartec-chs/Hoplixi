class HistoryFieldSnapshot<T> {
  const HistoryFieldSnapshot({
    required this.key,
    required this.label,
    required this.value,
    this.isSensitive = false,
  });

  final String key;
  final String label;
  final T? value;
  final bool isSensitive;
}
