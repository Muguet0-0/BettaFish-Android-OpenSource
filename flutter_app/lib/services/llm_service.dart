import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/settings_model.dart';

/// LLM消息角色
enum MessageRole { system, user, assistant }

/// LLM消息
class LLMMessage {
  final MessageRole role;
  final String content;

  LLMMessage({required this.role, required this.content});

  Map<String, dynamic> toJson() => {
    'role': role.name,
    'content': content,
  };
}

/// LLM响应
class LLMResponse {
  final bool success;
  final String content;
  final String? error;
  final int? promptTokens;
  final int? completionTokens;

  LLMResponse({
    required this.success,
    this.content = '',
    this.error,
    this.promptTokens,
    this.completionTokens,
  });
}

/// LLM服务 - 调用OpenAI兼容API
class LLMService {
  final LLMConfig config;

  LLMService({required this.config});

  /// 发送聊天请求
  Future<LLMResponse> chat(List<LLMMessage> messages) async {
    if (!config.isConfigured) {
      return LLMResponse(
        success: false,
        error: '请先配置LLM API密钥和地址',
      );
    }

    try {
      final url = Uri.parse('${config.baseUrl}/chat/completions');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${config.apiKey}',
        },
        body: jsonEncode({
          'model': config.modelName,
          'messages': messages.map((m) => m.toJson()).toList(),
          'temperature': config.temperature,
          'max_tokens': config.maxTokens,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices']?[0]?['message']?['content'] ?? '';
        final usage = data['usage'];
        return LLMResponse(
          success: true,
          content: content,
          promptTokens: usage?['prompt_tokens'],
          completionTokens: usage?['completion_tokens'],
        );
      } else {
        final error = jsonDecode(response.body);
        return LLMResponse(
          success: false,
          error: error['error']?['message'] ?? '请求失败: ${response.statusCode}',
        );
      }
    } catch (e) {
      return LLMResponse(
        success: false,
        error: '网络错误: $e',
      );
    }
  }

  /// 简单的单轮对话
  Future<LLMResponse> complete(String prompt, {String? systemPrompt}) async {
    final messages = <LLMMessage>[];
    if (systemPrompt != null) {
      messages.add(LLMMessage(role: MessageRole.system, content: systemPrompt));
    }
    messages.add(LLMMessage(role: MessageRole.user, content: prompt));
    return chat(messages);
  }

  /// 分析搜索结果
  Future<LLMResponse> analyzeSearchResults(
    String query,
    List<Map<String, dynamic>> results,
  ) async {
    final systemPrompt = '''你是一个专业的舆情分析师。请根据用户的搜索查询和搜索结果，进行全面的舆情分析。

分析要求：
1. 总结主要观点和信息
2. 识别情感倾向（正面/负面/中性）
3. 提取关键实体和话题
4. 分析信息来源的可靠性
5. 给出综合结论和建议

请用中文回答，格式清晰。''';

    final resultsText = results.map((r) {
      return '''
标题: ${r['title'] ?? '无标题'}
来源: ${r['source'] ?? '未知'}
摘要: ${r['snippet'] ?? r['description'] ?? '无摘要'}
链接: ${r['url'] ?? '无链接'}
''';
    }).join('\n---\n');

    final userPrompt = '''
搜索查询: $query

搜索结果:
$resultsText

请对以上搜索结果进行舆情分析。''';

    return complete(userPrompt, systemPrompt: systemPrompt);
  }

  /// 测试API连接
  Future<LLMResponse> testConnection() async {
    return complete('你好，请回复"连接成功"。');
  }
}

