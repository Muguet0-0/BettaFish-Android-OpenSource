import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/forum_message.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';

/// 论坛消息管理Provider
class ForumProvider extends ChangeNotifier {
  final ApiService apiService;
  final SocketService socketService;
  
  List<ForumMessage> _messages = [];
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription? _messageSubscription;
  
  // Getters
  List<ForumMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  ForumProvider({
    required this.apiService,
    required this.socketService,
  }) {
    _init();
  }
  
  void _init() {
    // 监听实时论坛消息
    _messageSubscription = socketService.forumMessageStream.listen((message) {
      _addMessage(message);
    });
  }
  
  /// 添加消息
  void _addMessage(ForumMessage message) {
    _messages.add(message);
    // 限制最大消息数
    if (_messages.length > 500) {
      _messages.removeAt(0);
    }
    notifyListeners();
  }
  
  /// 加载历史消息
  Future<void> loadMessages() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final messages = await apiService.getForumLog();
      _messages = messages;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = '加载消息失败: $e';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// 刷新消息
  Future<void> refreshMessages() async {
    await loadMessages();
  }
  
  /// 清空消息
  void clearMessages() {
    _messages.clear();
    notifyListeners();
  }
  
  /// 获取指定来源的消息
  List<ForumMessage> getMessagesBySource(ForumMessageSource source) {
    return _messages.where((m) => m.source == source).toList();
  }
  
  /// 获取最近N条消息
  List<ForumMessage> getRecentMessages(int count) {
    if (_messages.length <= count) {
      return List.from(_messages);
    }
    return _messages.sublist(_messages.length - count);
  }
  
  @override
  void dispose() {
    _messageSubscription?.cancel();
    super.dispose();
  }
}

