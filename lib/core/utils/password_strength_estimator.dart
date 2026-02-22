import 'dart:math';

enum PasswordStrengthLevel { weak, medium, strong, excellent }

class PasswordStrengthResult {
  const PasswordStrengthResult({
    required this.score,
    required this.level,
    required this.entropyBits,
  });

  final double score;
  final PasswordStrengthLevel level;
  final double entropyBits;
}

class PasswordStrengthEstimator {
  const PasswordStrengthEstimator();

  PasswordStrengthResult evaluate(String password) {
    if (password.isEmpty) {
      return const PasswordStrengthResult(
        score: 0,
        level: PasswordStrengthLevel.weak,
        entropyBits: 0,
      );
    }

    final lengthScore = (password.length / 20).clamp(0.0, 1.0);
    final varietyScore = _characterVarietyScore(password);
    final entropyBits = _estimateEntropyBits(password);
    final entropyScore = (entropyBits / 80).clamp(0.0, 1.0);
    final penalty = _patternPenalty(password);

    final weightedScore =
        lengthScore * 0.35 + varietyScore * 0.25 + entropyScore * 0.40;
    final score = (weightedScore - penalty).clamp(0.0, 1.0);

    return PasswordStrengthResult(
      score: score,
      level: _resolveLevel(score),
      entropyBits: entropyBits,
    );
  }

  PasswordStrengthLevel _resolveLevel(double score) {
    if (score < 0.3) return PasswordStrengthLevel.weak;
    if (score < 0.55) return PasswordStrengthLevel.medium;
    if (score < 0.8) return PasswordStrengthLevel.strong;
    return PasswordStrengthLevel.excellent;
  }

  double _characterVarietyScore(String password) {
    var classes = 0;
    if (password.contains(RegExp('[a-z]'))) classes++;
    if (password.contains(RegExp('[A-Z]'))) classes++;
    if (password.contains(RegExp('[0-9]'))) classes++;
    if (password.contains(RegExp(r'[^a-zA-Z0-9]'))) classes++;

    final classScore = classes / 4;
    final uniqueRatio =
        password.runes.toSet().length / password.runes.length.clamp(1, 1 << 20);
    return (classScore * 0.65 + uniqueRatio * 0.35).clamp(0.0, 1.0);
  }

  double _estimateEntropyBits(String password) {
    var pool = 0;
    if (password.contains(RegExp('[a-z]'))) pool += 26;
    if (password.contains(RegExp('[A-Z]'))) pool += 26;
    if (password.contains(RegExp('[0-9]'))) pool += 10;
    if (password.contains(RegExp(r'[^a-zA-Z0-9]'))) pool += 32;

    if (pool == 0) return 0;
    final bitsPerChar = log(pool) / ln2;
    return password.length * bitsPerChar;
  }

  double _patternPenalty(String password) {
    var penalty = 0.0;

    final repeatMatches = RegExp(r'(.)\1{2,}').allMatches(password).length;
    penalty += (repeatMatches * 0.12).clamp(0.0, 0.36);

    if (_hasSequentialRun(password)) {
      penalty += 0.18;
    }

    final uniqueRatio = password.runes.toSet().length / password.runes.length;
    if (uniqueRatio < 0.55) {
      penalty += 0.16;
    }

    if (password.length < 8) {
      penalty += 0.2;
    }

    return penalty.clamp(0.0, 0.55);
  }

  bool _hasSequentialRun(String password) {
    if (password.length < 3) return false;

    final codeUnits = password.codeUnits;
    var ascending = 1;
    var descending = 1;

    for (var i = 1; i < codeUnits.length; i++) {
      final diff = codeUnits[i] - codeUnits[i - 1];

      if (diff == 1) {
        ascending++;
      } else {
        ascending = 1;
      }

      if (diff == -1) {
        descending++;
      } else {
        descending = 1;
      }

      if (ascending >= 3 || descending >= 3) {
        return true;
      }
    }

    return false;
  }
}
