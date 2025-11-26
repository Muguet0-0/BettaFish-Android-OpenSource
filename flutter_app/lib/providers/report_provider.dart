import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/report.dart';
import '../services/api_service.dart';

/// 报告管理Provider
class ReportProvider extends ChangeNotifier {
  final ApiService apiService;
  
  ReportTask? _currentTask;
  String? _reportContent;
  bool _isLocked = true;
  bool _isGenerating = false;
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _progressTimer;
  
  // Getters
  ReportTask? get currentTask => _currentTask;
  String? get reportContent => _reportContent;
  bool get isLocked => _isLocked;
  bool get isGenerating => _isGenerating;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  double get progress => _currentTask?.progress ?? 0.0;
  
  ReportProvider({required this.apiService});
  
  /// 检查锁定状态
  Future<void> checkLockStatus() async {
    try {
      _isLocked = await apiService.checkReportLockStatus();
      notifyListeners();
    } catch (e) {
      // 默认锁定
      _isLocked = true;
      notifyListeners();
    }
  }
  
  /// 生成报告
  Future<bool> generateReport({String? query, String? template}) async {
    if (_isLocked || _isGenerating) return false;

    _isGenerating = true;
    _errorMessage = null;
    _reportContent = null;
    notifyListeners();

    try {
      final result = await apiService.generateReport(
        query: query ?? '智能舆情分析报告',
        template: template,
      );
      if (result['success'] == true) {
        final taskId = result['task_id'] as String?;
        if (taskId != null) {
          _currentTask = ReportTask(
            taskId: taskId,
            status: ReportTaskStatus.running,
            progress: 0.05, // 初始进度5%
          );
          _startProgressPolling(taskId);
          return true;
        }
      }
      _errorMessage = result['error'] as String? ?? result['message'] as String? ?? '生成失败';
      _isGenerating = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = '生成报告失败: $e';
      _isGenerating = false;
      notifyListeners();
      return false;
    }
  }
  
  /// 开始轮询进度
  void _startProgressPolling(String taskId) {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      await _checkProgress(taskId);
    });
  }
  
  /// 检查进度
  Future<void> _checkProgress(String taskId) async {
    try {
      final task = await apiService.getReportTaskStatus(taskId);
      _currentTask = task;
      
      if (task.isCompleted) {
        _progressTimer?.cancel();
        _isGenerating = false;
        await _loadReportContent(taskId);
      } else if (task.isFailed) {
        _progressTimer?.cancel();
        _isGenerating = false;
        _errorMessage = task.message ?? '报告生成失败';
      }
      
      notifyListeners();
    } catch (e) {
      // 继续轮询
    }
  }
  
  /// 加载报告内容
  Future<void> _loadReportContent(String taskId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _reportContent = await apiService.getReportResult(taskId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = '加载报告内容失败: $e';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// 查看报告
  Future<void> viewReport(String taskId) async {
    await _loadReportContent(taskId);
  }
  
  /// 清除报告
  void clearReport() {
    _currentTask = null;
    _reportContent = null;
    _errorMessage = null;
    notifyListeners();
  }
  
  /// 解锁报告引擎
  void unlock() {
    _isLocked = false;
    notifyListeners();
  }
  
  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }
}

