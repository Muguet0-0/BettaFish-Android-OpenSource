import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/engine_status.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';

/// 应用状态管理Provider
class AppStateProvider extends ChangeNotifier {
  final ApiService apiService;
  final SocketService socketService;
  
  // 状态
  bool _isConnected = false;
  bool _systemStarted = false;
  bool _systemStarting = false;
  String _currentEngine = 'insight';
  SystemStatus _systemStatus = SystemStatus.initial();
  String? _currentQuery;
  String? _customTemplate;
  String? _errorMessage;
  
  // 订阅
  StreamSubscription? _connectionSubscription;
  StreamSubscription? _statusSubscription;
  
  // Getters
  bool get isConnected => _isConnected;
  bool get systemStarted => _systemStarted;
  bool get systemStarting => _systemStarting;
  String get currentEngine => _currentEngine;
  SystemStatus get systemStatus => _systemStatus;
  String? get currentQuery => _currentQuery;
  String? get customTemplate => _customTemplate;
  String? get errorMessage => _errorMessage;
  
  AppStateProvider({
    required this.apiService,
    required this.socketService,
  }) {
    _init();
  }
  
  void _init() {
    // 监听连接状态
    _connectionSubscription = socketService.connectionStream.listen((connected) {
      _isConnected = connected;
      notifyListeners();
      if (connected) {
        _fetchSystemStatus();
      }
    });
    
    // 监听状态更新
    _statusSubscription = socketService.statusUpdateStream.listen((data) {
      _updateStatusFromSocket(data);
    });
  }
  
  /// 连接到服务器
  Future<void> connectToServer(String serverUrl) async {
    apiService.updateServerUrl(serverUrl);
    socketService.reconnect(customUrl: serverUrl);
  }
  
  /// 获取系统状态
  Future<void> _fetchSystemStatus() async {
    try {
      final status = await apiService.getSystemStatus();
      _systemStarted = status['started'] as bool? ?? false;
      _systemStarting = status['starting'] as bool? ?? false;
      
      if (_systemStarted) {
        final engineStatus = await apiService.getEngineStatus();
        _systemStatus = engineStatus;
      }
      
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = '获取状态失败: $e';
      notifyListeners();
    }
  }
  
  /// 从Socket更新状态
  void _updateStatusFromSocket(Map<String, dynamic> data) {
    // 更新引擎状态
    data.forEach((key, value) {
      if (value is Map<String, dynamic> && _systemStatus.engines.containsKey(key)) {
        final newStatus = EngineStatus.fromJson(key, value);
        _systemStatus.engines[key] = newStatus;
      }
    });
    notifyListeners();
  }
  
  /// 启动系统
  Future<bool> startSystem() async {
    if (_systemStarting || _systemStarted) return false;
    
    _systemStarting = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final result = await apiService.startSystem();
      if (result['success'] == true) {
        _systemStarted = true;
        _systemStarting = false;
        await _fetchSystemStatus();
        return true;
      } else {
        _errorMessage = result['message'] as String? ?? '启动失败';
        _systemStarting = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = '启动系统失败: $e';
      _systemStarting = false;
      notifyListeners();
      return false;
    }
  }
  
  /// 切换当前引擎
  void switchEngine(String engineName) {
    if (_currentEngine != engineName) {
      _currentEngine = engineName;
      notifyListeners();
    }
  }
  
  /// 执行搜索
  Future<bool> performSearch(String query) async {
    if (query.isEmpty) return false;
    
    _currentQuery = query;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final result = await apiService.performSearch(query, template: _customTemplate);
      return result['success'] == true;
    } catch (e) {
      _errorMessage = '搜索失败: $e';
      notifyListeners();
      return false;
    }
  }
  
  /// 设置自定义模板
  void setCustomTemplate(String? template) {
    _customTemplate = template;
    notifyListeners();
  }
  
  /// 清除错误
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
  
  /// 刷新状态
  Future<void> refreshStatus() async {
    await _fetchSystemStatus();
  }
  
  @override
  void dispose() {
    _connectionSubscription?.cancel();
    _statusSubscription?.cancel();
    super.dispose();
  }
}

