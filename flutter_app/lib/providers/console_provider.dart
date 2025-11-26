import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/console_output.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';

/// 控制台输出管理Provider
class ConsoleProvider extends ChangeNotifier {
  final ApiService apiService;
  final SocketService socketService;
  
  // 各引擎的控制台输出
  final Map<String, ConsoleOutput> _outputs = {
    'insight': ConsoleOutput(engineName: 'insight'),
    'media': ConsoleOutput(engineName: 'media'),
    'query': ConsoleOutput(engineName: 'query'),
    'forum': ConsoleOutput(engineName: 'forum'),
    'report': ConsoleOutput(engineName: 'report'),
  };
  
  bool _isLoading = false;
  StreamSubscription? _consoleSubscription;
  
  // Getters
  Map<String, ConsoleOutput> get outputs => _outputs;
  bool get isLoading => _isLoading;
  
  ConsoleProvider({
    required this.apiService,
    required this.socketService,
  }) {
    _init();
  }
  
  void _init() {
    // 监听实时控制台输出
    _consoleSubscription = socketService.consoleOutputStream.listen((data) {
      final app = data['app'] as String?;
      final line = data['line'] as String?;
      
      if (app != null && line != null && _outputs.containsKey(app)) {
        _outputs[app]!.addLine(ConsoleLine.fromString(line));
        notifyListeners();
      }
    });
  }
  
  /// 获取指定引擎的输出
  ConsoleOutput getOutput(String engineName) {
    return _outputs[engineName] ?? ConsoleOutput(engineName: engineName);
  }
  
  /// 获取指定引擎的输出行列表
  List<ConsoleLine> getLines(String engineName) {
    return _outputs[engineName]?.lines ?? [];
  }
  
  /// 加载引擎历史输出
  Future<void> loadEngineOutput(String engineName) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final lines = await apiService.getEngineOutput(engineName);
      _outputs[engineName]?.clear();
      for (final line in lines) {
        _outputs[engineName]?.addLine(ConsoleLine.fromString(line));
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// 刷新指定引擎的输出
  Future<void> refreshOutput(String engineName) async {
    await loadEngineOutput(engineName);
  }
  
  /// 清空指定引擎的输出
  void clearOutput(String engineName) {
    _outputs[engineName]?.clear();
    notifyListeners();
  }
  
  /// 清空所有输出
  void clearAllOutputs() {
    for (final output in _outputs.values) {
      output.clear();
    }
    notifyListeners();
  }
  
  /// 添加一行输出
  void addLine(String engineName, String line) {
    if (_outputs.containsKey(engineName)) {
      _outputs[engineName]!.addLine(ConsoleLine.fromString(line));
      notifyListeners();
    }
  }
  
  @override
  void dispose() {
    _consoleSubscription?.cancel();
    super.dispose();
  }
}

