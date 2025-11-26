import 'package:flutter/foundation.dart';
import '../models/config_model.dart';
import '../services/api_service.dart';
import '../config/app_config.dart';

/// 配置管理Provider
class ConfigProvider extends ChangeNotifier {
  final ApiService apiService;
  
  AppConfigModel _config = AppConfigModel();
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  String? _successMessage;
  
  // 编辑中的配置值
  Map<String, String> _editingValues = {};
  
  // Getters
  AppConfigModel get config => _config;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  Map<String, String> get editingValues => _editingValues;
  
  ConfigProvider({required this.apiService});
  
  /// 加载配置
  Future<void> loadConfig() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      _config = await apiService.getConfig();
      _editingValues = Map.from(_config.values);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = '加载配置失败: $e';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// 更新编辑中的配置值
  void updateEditingValue(String key, String value) {
    _editingValues[key] = value;
    notifyListeners();
  }
  
  /// 获取配置值
  String getValue(String key) {
    return _editingValues[key] ?? _config.getValue(key);
  }
  
  /// 保存配置
  Future<bool> saveConfig() async {
    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
    
    try {
      final result = await apiService.saveConfig(_editingValues);
      if (result['success'] == true) {
        _config = _config.copyWith(values: Map.from(_editingValues));
        _successMessage = '配置保存成功';
        _isSaving = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] as String? ?? '保存失败';
        _isSaving = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = '保存配置失败: $e';
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }
  
  /// 重置编辑值
  void resetEditingValues() {
    _editingValues = Map.from(_config.values);
    notifyListeners();
  }
  
  /// 获取配置组列表
  List<ConfigGroup> getConfigGroups() {
    return AppConfig.configFieldGroups.map((group) {
      final items = (group['fields'] as List<Map<String, dynamic>>).map((field) {
        return ConfigItem(
          key: field['key'] as String,
          label: field['label'] as String,
          type: field['type'] as String,
          value: getValue(field['key'] as String),
        );
      }).toList();
      
      return ConfigGroup(
        title: group['title'] as String,
        items: items,
      );
    }).toList();
  }
  
  /// 清除消息
  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }
}

