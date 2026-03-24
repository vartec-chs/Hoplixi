import 'dart:async';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

Never _throwWindowsError(String operation, WIN32_ERROR error) {
  throw WindowsException(
    error.toHRESULT(),
    message: '$operation failed',
  );
}

void _throwIfError(String operation, WIN32_ERROR error) {
  if (error.isError) {
    _throwWindowsError(operation, error);
  }
}

void _checkBoolResult(String operation, Win32Result<bool> result) {
  if (!result.value) {
    _throwWindowsError(operation, result.error);
  }
}

HGLOBAL _checkGlobalHandle(String operation, Win32Result<HGLOBAL> result) {
  if (!result.value.isValid) {
    _throwWindowsError(operation, result.error);
  }
  return result.value;
}

HANDLE _checkHandle(String operation, Win32Result<HANDLE> result) {
  if (!result.value.isValid) {
    _throwWindowsError(operation, result.error);
  }
  return result.value;
}

Pointer _checkPointer(String operation, Win32Result<Pointer> result) {
  if (result.value.isNull) {
    _throwWindowsError(operation, result.error);
  }
  return result.value;
}

Uint8List _sha256Utf16leFromUnits(Uint16List units) {
  final bytes = Uint8List(units.length * 2);
  for (var i = 0; i < units.length; i++) {
    final unit = units[i];
    bytes[i * 2] = unit & 0xFF;
    bytes[i * 2 + 1] = (unit >> 8) & 0xFF;
  }
  return Uint8List.fromList(sha256.convert(bytes).bytes);
}

Uint8List _sha256Utf16leFromNullTerminatedPtr(Pointer<Uint16> ptr) {
  var len = 0;
  while (ptr[len] != 0) {
    len++;
  }

  final bytes = Uint8List(len * 2);
  for (var i = 0; i < len; i++) {
    final unit = ptr[i];
    bytes[i * 2] = unit & 0xFF;
    bytes[i * 2 + 1] = (unit >> 8) & 0xFF;
  }

  return Uint8List.fromList(sha256.convert(bytes).bytes);
}

void _unlockGlobalMemory(HGLOBAL memory) {
  final result = GlobalUnlock(memory);
  _throwIfError('GlobalUnlock', result.error);
}

void _freeGlobalMemory(HGLOBAL memory) {
  final result = GlobalFree(memory);
  _throwIfError('GlobalFree', result.error);
}

Timer? _pendingClearTimer;
Uint8List? _pendingClearDigest;

void _withOpenClipboard(void Function() action) {
  _checkBoolResult('OpenClipboard', OpenClipboard(null));
  try {
    action();
  } finally {
    _checkBoolResult('CloseClipboard', CloseClipboard());
  }
}

void _writeUtf16UnitsToGlobalMemory(HGLOBAL memory, Uint16List units) {
  final locked =
      _checkPointer('GlobalLock', GlobalLock(memory)).cast<Uint16>();
  try {
    for (var i = 0; i < units.length; i++) {
      locked[i] = units[i];
    }
    locked[units.length] = 0;
  } finally {
    _unlockGlobalMemory(memory);
  }
}

void _writeDwordZeroToGlobalMemory(HGLOBAL memory) {
  final locked =
      _checkPointer('GlobalLock', GlobalLock(memory)).cast<Uint32>();
  try {
    locked.value = 0;
  } finally {
    _unlockGlobalMemory(memory);
  }
}

void _setClipboardDataUtf16Units(Uint16List units) {
  final byteSize = (units.length + 1) * sizeOf<Uint16>();
  final memory = _checkGlobalHandle(
    'GlobalAlloc',
    GlobalAlloc(GMEM_MOVEABLE, byteSize),
  );

  var transferred = false;
  try {
    _writeUtf16UnitsToGlobalMemory(memory, units);
    _checkHandle(
      'SetClipboardData(CF_UNICODETEXT)',
      SetClipboardData(CF_UNICODETEXT, HANDLE(memory)),
    );
    transferred = true;
  } finally {
    if (!transferred) {
      _freeGlobalMemory(memory);
    }
  }
}

void _setMarkerFormatDwordZeroOpened(String formatName) {
  final registerResult = using((arena) {
    final namePtr = formatName.toNativeUtf16(allocator: arena);
    return RegisterClipboardFormat(PCWSTR(namePtr));
  });

  if (registerResult.error.isError || registerResult.value == 0) {
    return;
  }

  final memory = _checkGlobalHandle(
    'GlobalAlloc',
    GlobalAlloc(GMEM_MOVEABLE, sizeOf<Uint32>()),
  );

  var transferred = false;
  try {
    _writeDwordZeroToGlobalMemory(memory);
    _checkHandle(
      'SetClipboardData($formatName)',
      SetClipboardData(registerResult.value, HANDLE(memory)),
    );
    transferred = true;
  } finally {
    if (!transferred) {
      _freeGlobalMemory(memory);
    }
  }
}

/// Best-effort: clears clipboard content.
///
/// Useful for app shutdown hooks / lifecycle events.
void clearClipboardNow() {
  final openResult = OpenClipboard(null);
  if (!openResult.value) {
    return;
  }

  try {
    EmptyClipboard();
  } finally {
    CloseClipboard();
  }
}

/// Cancels the scheduled TTL-based clipboard clear (if any).
void cancelScheduledClipboardClear() {
  _pendingClearTimer?.cancel();
  _pendingClearTimer = null;
  _pendingClearDigest = null;
}

/// Attempts to clear the clipboard *before* TTL expires.
///
/// This is safe-by-default: it only clears the clipboard if the current
/// `CF_UNICODETEXT` digest matches the secret that was last scheduled for TTL
/// cleanup.
///
/// Returns `true` if the clipboard was cleared.
bool clearScheduledSecretNow() {
  final expected = _pendingClearDigest;
  cancelScheduledClipboardClear();
  if (expected == null) return false;

  final currentDigest = _getClipboardUtf16leSha256Digest();
  if (currentDigest == null) return false;

  if (_bytesEqual(currentDigest, expected)) {
    clearClipboardNow();
    return true;
  }

  return false;
}

Uint8List? _getClipboardUtf16leSha256Digest() {
  final openResult = OpenClipboard(null);
  if (!openResult.value) {
    return null;
  }

  try {
    final clipboardData = GetClipboardData(CF_UNICODETEXT);
    if (!clipboardData.value.isValid) {
      return null;
    }

    final memory = HGLOBAL(clipboardData.value);
    final lockedResult = GlobalLock(memory);
    if (lockedResult.value.isNull) {
      return null;
    }

    try {
      return _sha256Utf16leFromNullTerminatedPtr(
        lockedResult.value.cast<Uint16>(),
      );
    } finally {
      _unlockGlobalMemory(memory);
    }
  } finally {
    CloseClipboard();
  }
}

/// High-security API: accepts UTF-16 code units directly.
///
/// This avoids creating an immutable Dart [String] for the secret.
/// Caller can overwrite [secretUtf16] after the call.
void copySecretWithTtlFromUtf16(Uint16List secretUtf16, Duration ttl) {
  final originalDigest = _sha256Utf16leFromUnits(secretUtf16);

  _withOpenClipboard(() {
    _checkBoolResult('EmptyClipboard', EmptyClipboard());
    _setClipboardDataUtf16Units(secretUtf16);
    _setMarkerFormatDwordZeroOpened('CanIncludeInClipboardHistory');
    _setMarkerFormatDwordZeroOpened('CanUploadToCloudClipboard');
    _setMarkerFormatDwordZeroOpened(
      'ExcludeClipboardContentFromMonitorProcessing',
    );
    _setMarkerFormatDwordZeroOpened('Clipboard Viewer Ignore');
  });

  _pendingClearTimer?.cancel();
  _pendingClearDigest = originalDigest;
  _pendingClearTimer = Timer(ttl, () {
    final currentDigest = _getClipboardUtf16leSha256Digest();
    if (currentDigest == null) return;

    if (_bytesEqual(currentDigest, originalDigest)) {
      clearClipboardNow();
    }
  });
}

/// Public API: copy secret with TTL (KeePass-like)
void copySecretWithTtl(String secret, Duration ttl) {
  // Convenience wrapper. Still creates a Dart String (by definition), but
  // avoids retaining it in the TTL timer and compares clipboard content
  // without creating a new String.
  copySecretWithTtlFromUtf16(Uint16List.fromList(secret.codeUnits), ttl);
}

bool _bytesEqual(Uint8List a, Uint8List b) {
  if (a.lengthInBytes != b.lengthInBytes) return false;
  var diff = 0;
  for (var i = 0; i < a.lengthInBytes; i++) {
    diff |= a[i] ^ b[i];
  }
  return diff == 0;
}
