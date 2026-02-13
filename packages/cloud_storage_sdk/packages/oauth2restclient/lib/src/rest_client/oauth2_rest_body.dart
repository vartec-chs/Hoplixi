import 'dart:convert';

abstract interface class OAuth2RestBody {
  List<int> toBytes();
  Stream<List<int>> toStream();
  String? get contentType;
  int? get contentLength; // 전체 길이(optional)
}

class OAuth2TextBody implements OAuth2RestBody {
  final String text;
  List<int>? _encoded;

  @override
  List<int> toBytes() {
    return _encoded ??= utf8.encode(text);
  }

  OAuth2TextBody(this.text);

  @override
  Stream<List<int>> toStream() async* {
    final bytes = toBytes();
    yield bytes; // 텍스트를 스트림으로
  }

  @override
  String? get contentType => "text/plain; charset=utf-8";

  @override
  int get contentLength => toBytes().length;
}

class OAuth2JsonBody implements OAuth2RestBody {
  final Map<String, dynamic> jsonMap;
  List<int>? _encoded;

  @override
  List<int> toBytes() {
    return _encoded ??= utf8.encode(jsonEncode(jsonMap));
  }

  OAuth2JsonBody(this.jsonMap);

  @override
  Stream<List<int>> toStream() async* {
    final bytes = toBytes();
    yield bytes; // 텍스트를 스트림으로
  }

  @override
  String? get contentType => "application/json; charset=utf-8";

  @override
  int get contentLength => toBytes().length;
}

class OAuth2FileBody implements OAuth2RestBody {
  final Stream<List<int>> fileStream;
  final String? _contentType;
  final int _contentLength;

  OAuth2FileBody(
    this.fileStream, {
    String? contentType,
    required int contentLength,
  }) : _contentType = contentType,
       _contentLength = contentLength;

  @override
  List<int> toBytes() {
    throw UnimplementedError('toBytes is not supported for OAuth2FileBody');
  }

  @override
  Stream<List<int>> toStream() => fileStream;

  @override
  String? get contentType => _contentType ?? 'application/octet-stream';

  @override
  int? get contentLength => _contentLength;
}
