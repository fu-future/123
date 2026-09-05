import 'dart:convert';

import 'package:dio/dio.dart';

/// OpenAI 兼容 HTTP 客户端（chat/completions）。
class AiClient {
  AiClient({
    required this.baseUrl,
    required this.apiKey,
    required this.model,
    this.timeoutMs = 8000,
    Dio? dio,
  }) : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: Duration(milliseconds: timeoutMs),
              receiveTimeout: Duration(milliseconds: timeoutMs),
            ));

  final String baseUrl;
  final String apiKey;
  final String model;
  final int timeoutMs;
  final Dio _dio;

  /// 规范化 BaseUrl：兼容带/不带 `/v1`，自动补 `chat/completions`。
  String get _endpoint {
    var base = baseUrl.trim();
    while (base.endsWith('/')) {
      base = base.substring(0, base.length - 1);
    }
    if (!base.endsWith('/v1') && !base.contains('/v1/')) {
      base = '$base/v1';
    }
    return '$base/chat/completions';
  }

  /// 发起对话补全，返回首条 assistant 内容。
  Future<String> chatCompletion(String systemPrompt, String userPrompt) async {
    final response = await _dio.post<Map<String, dynamic>>(
      _endpoint,
      options: Options(headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      }),
      data: {
        'model': model,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userPrompt},
        ],
        'temperature': 0.2,
      },
    );
    final data = response.data;
    final content =
        data?['choices']?[0]?['message']?['content'] as String?;
    if (content == null || content.trim().isEmpty) {
      throw const FormatException('AI 返回空内容');
    }
    return content.trim();
  }

  /// 连接测试。
  Future<bool> testConnection() async {
    try {
      await chatCompletion('回复"ok"', '测试');
      return true;
    } catch (_) {
      return false;
    }
  }
}
