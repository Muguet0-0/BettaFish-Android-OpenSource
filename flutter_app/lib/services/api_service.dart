import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/engine_status.dart';
import '../models/config_model.dart';
import '../models/forum_message.dart';
import '../models/report.dart';

/// API服务类 - 与Flask后端通信
class ApiService {
  final String baseUrl;
  final http.Client _client;
  
  ApiService({
    required this.baseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();
  
  /// 更新服务器地址
  String _serverUrl = '';
  void updateServerUrl(String url) {
    _serverUrl = url;
  }
  
  String get serverUrl => _serverUrl.isNotEmpty ? _serverUrl : baseUrl;
  
  /// 通用GET请求
  Future<Map<String, dynamic>> _get(String path) async {
    try {
      final response = await _client.get(
        Uri.parse('$serverUrl$path'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw ApiException('请求失败: ${response.statusCode}', response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('网络错误: $e', 0);
    }
  }
  
  /// 通用POST请求
  Future<Map<String, dynamic>> _post(String path, {Map<String, dynamic>? body}) async {
    try {
      final response = await _client.post(
        Uri.parse('$serverUrl$path'),
        headers: {'Content-Type': 'application/json'},
        body: body != null ? json.encode(body) : null,
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw ApiException('请求失败: ${response.statusCode}', response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('网络错误: $e', 0);
    }
  }
  
  // ==================== 系统状态 API ====================
  
  /// 获取系统状态
  Future<Map<String, dynamic>> getSystemStatus() async {
    return await _get('/api/system/status');
  }
  
  /// 启动系统
  Future<Map<String, dynamic>> startSystem() async {
    return await _post('/api/system/start');
  }
  
  /// 获取所有引擎状态
  Future<SystemStatus> getEngineStatus() async {
    final data = await _get('/api/status');
    return SystemStatus.fromJson(data);
  }
  
  // ==================== 配置 API ====================
  
  /// 获取配置
  Future<AppConfigModel> getConfig() async {
    final data = await _get('/api/config');
    return AppConfigModel.fromJson(data);
  }
  
  /// 保存配置
  Future<Map<String, dynamic>> saveConfig(Map<String, String> config) async {
    return await _post('/api/config', body: config);
  }
  
  // ==================== 搜索 API ====================
  
  /// 执行搜索
  Future<Map<String, dynamic>> performSearch(String query, {String? template}) async {
    final body = <String, dynamic>{'query': query};
    if (template != null && template.isNotEmpty) {
      body['template'] = template;
    }
    return await _post('/api/search', body: body);
  }
  
  // ==================== 控制台输出 API ====================
  
  /// 获取引擎输出
  Future<List<String>> getEngineOutput(String engineName) async {
    final data = await _get('/api/output/$engineName');
    if (data['success'] == true) {
      return (data['output'] as List<dynamic>).cast<String>();
    }
    return [];
  }
  
  // ==================== 论坛 API ====================
  
  /// 获取论坛日志
  Future<List<ForumMessage>> getForumLog() async {
    final data = await _get('/api/forum/log');
    if (data['success'] == true) {
      final messages = (data['parsed_messages'] as List<dynamic>)
          .map((m) => ForumMessage.fromJson(m as Map<String, dynamic>))
          .toList();
      return messages;
    }
    return [];
  }
  
  // ==================== 报告 API ====================

  /// 获取报告引擎状态
  Future<Map<String, dynamic>> getReportStatus() async {
    return await _get('/api/report/status');
  }

  /// 获取报告引擎日志
  Future<List<String>> getReportLog() async {
    final data = await _get('/api/report/log');
    if (data['success'] == true) {
      return (data['log_lines'] as List<dynamic>?)?.cast<String>() ?? [];
    }
    return [];
  }

  /// 生成报告
  Future<Map<String, dynamic>> generateReport({String? query, String? template}) async {
    final body = <String, dynamic>{};
    if (query != null && query.isNotEmpty) {
      body['query'] = query;
    }
    if (template != null && template.isNotEmpty) {
      body['custom_template'] = template;
    }
    return await _post('/api/report/generate', body: body);
  }

  /// 获取报告任务进度
  Future<Map<String, dynamic>> getReportProgress(String taskId) async {
    return await _get('/api/report/progress/$taskId');
  }

  /// 获取报告任务状态
  Future<ReportTask> getReportTaskStatus(String taskId) async {
    final data = await _get('/api/report/progress/$taskId');
    if (data['success'] == true && data['task'] != null) {
      return ReportTask.fromJson(data['task'] as Map<String, dynamic>);
    }
    return ReportTask(taskId: taskId, status: ReportTaskStatus.pending);
  }

  /// 获取报告内容结果
  Future<String> getReportResult(String taskId) async {
    try {
      final response = await _client.get(
        Uri.parse('$serverUrl/api/report/result/$taskId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        // 返回原始HTML内容
        return response.body;
      }
      return '';
    } catch (e) {
      return '';
    }
  }

  /// 检查报告锁定状态
  Future<bool> checkReportLockStatus() async {
    final data = await _get('/api/report/lock-status');
    return data['locked'] as bool? ?? true;
  }
}

/// API异常类
class ApiException implements Exception {
  final String message;
  final int statusCode;
  
  ApiException(this.message, this.statusCode);
  
  @override
  String toString() => 'ApiException: $message (status: $statusCode)';
}

