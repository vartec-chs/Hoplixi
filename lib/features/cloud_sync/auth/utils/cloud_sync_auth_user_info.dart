String? extractAccountId(Map<String, dynamic>? userInfo) {
  if (userInfo == null) {
    return null;
  }

  return _firstNonEmpty([
    userInfo['account_id'],
    userInfo['id'],
    userInfo['sub'],
    userInfo['uid'],
  ]);
}

String? extractAccountEmail(Map<String, dynamic>? userInfo) {
  if (userInfo == null) {
    return null;
  }

  return _firstNonEmpty([
    userInfo['email'],
    userInfo['mail'],
    userInfo['userPrincipalName'],
    userInfo['default_email'],
    userInfo['defaultEmail'],
    userInfo['login'],
  ]);
}

String? extractAccountName(Map<String, dynamic>? userInfo) {
  if (userInfo == null) {
    return null;
  }

  final realName = userInfo['name_details'];
  final realDisplayName = realName is Map<String, dynamic>
      ? realName['display_name']
      : null;

  return _firstNonEmpty([
    userInfo['name'],
    userInfo['display_name'],
    userInfo['displayName'],
    userInfo['real_name'],
    realDisplayName,
    userInfo['given_name'],
    userInfo['login'],
  ]);
}

String? _firstNonEmpty(List<Object?> values) {
  for (final value in values) {
    if (value is String) {
      final normalized = value.trim();
      if (normalized.isNotEmpty) {
        return normalized;
      }
    }
  }

  return null;
}
