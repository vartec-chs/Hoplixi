import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

class OAuthPkcePair {
  const OAuthPkcePair({
    required this.codeVerifier,
    required this.codeChallenge,
    required this.state,
  });

  final String codeVerifier;
  final String codeChallenge;
  final String state;

  static OAuthPkcePair generate() {
    final verifier = _randomUrlSafeString(64);
    final challenge = base64UrlEncode(
      sha256.convert(ascii.encode(verifier)).bytes,
    ).replaceAll('=', '');

    return OAuthPkcePair(
      codeVerifier: verifier,
      codeChallenge: challenge,
      state: _randomUrlSafeString(32),
    );
  }

  static String _randomUrlSafeString(int length) {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final random = Random.secure();
    return List<String>.generate(
      length,
      (_) => chars[random.nextInt(chars.length)],
      growable: false,
    ).join();
  }
}
