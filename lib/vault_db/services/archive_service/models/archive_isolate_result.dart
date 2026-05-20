class ArchiveIsolateResult {
  final bool success;
  final String? data;
  final String? error;
  final bool isInvalidPassword;

  ArchiveIsolateResult.success(this.data)
    : success = true,
      error = null,
      isInvalidPassword = false;

  ArchiveIsolateResult.error(this.error, {this.isInvalidPassword = false})
    : success = false,
      data = null;
}
