import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

class ChatSource {
  const ChatSource({
    required this.title,
    required this.url,
    required this.publisher,
  });

  final String title;
  final String url;
  final String publisher;

  factory ChatSource.fromJson(Map<String, dynamic> json) {
    return ChatSource(
      title: json['title'] as String? ?? 'مصدر طبي',
      url: json['url'] as String? ?? '',
      publisher: json['publisher'] as String? ?? '',
    );
  }
}

class ChatReply {
  const ChatReply({
    required this.answer,
    this.sources = const [],
    this.concernDetected = false,
    this.emergency = false,
  });

  final String answer;
  final List<ChatSource> sources;
  final bool concernDetected;
  final bool emergency;

  factory ChatReply.fromJson(Map<String, dynamic> json) {
    final rawSources = json['sources'];
    final sources = rawSources is List
        ? rawSources
            .whereType<Map<String, dynamic>>()
            .map(ChatSource.fromJson)
            .toList(growable: false)
        : const <ChatSource>[];
    return ChatReply(
      answer: json['answer'] as String? ?? 'تعذّر قراءة الرد من الخادم.',
      sources: sources,
      concernDetected: json['concern_detected'] as bool? ?? false,
      emergency: json['emergency'] as bool? ?? false,
    );
  }
}

abstract interface class ChatService {
  Future<ChatReply> sendMessage(String message);
}

class ChatApiException implements Exception {
  const ChatApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class HttpChatService implements ChatService {
  HttpChatService({String? baseUrl, HttpClient? client})
      : _baseUrl = baseUrl ??
            const String.fromEnvironment('SABAH_API_BASE_URL').trim(),
        _client = client ?? HttpClient() {
    _client.connectionTimeout = const Duration(seconds: 8);
  }

  final String _baseUrl;
  final HttpClient _client;

  @override
  Future<ChatReply> sendMessage(String message) async {
    if (_baseUrl.isEmpty) {
      throw const ChatApiException(
        'الخادم غير مهيأ لهذه النسخة. لا تكتب معلومات صحية حقيقية هنا.',
      );
    }

    final Uri baseUri;
    try {
      baseUri = Uri.parse(_baseUrl);
    } on FormatException {
      throw const ChatApiException('عنوان الخادم غير صالح.');
    }
    if (!baseUri.hasAuthority ||
        baseUri.userInfo.isNotEmpty ||
        baseUri.scheme != 'https') {
      throw const ChatApiException(
        'يتطلب صباح عنوان خادم HTTPS آمنًا قبل إرسال الرسائل.',
      );
    }

    final requestUri = baseUri.resolve('/api/chat');
    try {
      final request = await _client.postUrl(requestUri).timeout(
            const Duration(seconds: 10),
          );
      request.headers.contentType = ContentType.json;
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      request.write(jsonEncode({'message': message}));
      final response = await request.close().timeout(
            const Duration(seconds: 20),
          );
      final body = await utf8.decoder.bind(response).join().timeout(
            const Duration(seconds: 10),
          );
      if (response.statusCode != HttpStatus.ok) {
        throw const ChatApiException(
          'تعذّر إكمال الطلب بأمان. حاول لاحقًا أو راجع الطبيب عند وجود شكوى.',
        );
      }
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        throw const ChatApiException('استجابة الخادم غير صالحة.');
      }
      return ChatReply.fromJson(decoded);
    } on ChatApiException {
      rethrow;
    } on SocketException {
      throw const ChatApiException(
        'تعذّر الاتصال بالخادم. تأكد من إعداد عنوان HTTPS وحاول لاحقًا.',
      );
    } on FormatException {
      throw const ChatApiException('تعذّر قراءة استجابة الخادم.');
    } on HttpException {
      throw const ChatApiException('تعذّر الاتصال بالخادم الآن.');
    } on Exception {
      throw const ChatApiException('حدث خطأ أثناء الاتصال بالخادم.');
    }
  }

  void close() => _client.close(force: true);
}

@visibleForTesting
class FakeChatService implements ChatService {
  FakeChatService(this.reply);

  final ChatReply reply;
  final List<String> sentMessages = [];

  @override
  Future<ChatReply> sendMessage(String message) async {
    sentMessages.add(message);
    return reply;
  }
}
