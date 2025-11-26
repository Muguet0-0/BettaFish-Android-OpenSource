import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../models/forum_message.dart';

/// Socket.IO服务类 - 实时通信
class SocketService {
  final String serverUrl;
  io.Socket? _socket;
  bool _isConnected = false;
  
  // 事件流控制器
  final _connectionController = StreamController<bool>.broadcast();
  final _consoleOutputController = StreamController<Map<String, dynamic>>.broadcast();
  final _forumMessageController = StreamController<ForumMessage>.broadcast();
  final _statusUpdateController = StreamController<Map<String, dynamic>>.broadcast();
  
  // 公开的事件流
  Stream<bool> get connectionStream => _connectionController.stream;
  Stream<Map<String, dynamic>> get consoleOutputStream => _consoleOutputController.stream;
  Stream<ForumMessage> get forumMessageStream => _forumMessageController.stream;
  Stream<Map<String, dynamic>> get statusUpdateStream => _statusUpdateController.stream;
  
  bool get isConnected => _isConnected;
  
  SocketService({required this.serverUrl});
  
  /// 连接到服务器
  void connect({String? customUrl}) {
    final url = customUrl ?? serverUrl;
    
    _socket = io.io(url, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
      'reconnection': true,
      'reconnectionAttempts': 10,
      'reconnectionDelay': 1000,
      'reconnectionDelayMax': 5000,
    });
    
    _setupEventListeners();
    _socket?.connect();
  }
  
  /// 设置事件监听器
  void _setupEventListeners() {
    _socket?.onConnect((_) {
      _isConnected = true;
      _connectionController.add(true);
      print('Socket.IO: 已连接');
    });
    
    _socket?.onDisconnect((_) {
      _isConnected = false;
      _connectionController.add(false);
      print('Socket.IO: 已断开');
    });
    
    _socket?.onConnectError((error) {
      _isConnected = false;
      _connectionController.add(false);
      print('Socket.IO: 连接错误 - $error');
    });
    
    _socket?.onError((error) {
      print('Socket.IO: 错误 - $error');
    });
    
    // 监听控制台输出
    _socket?.on('console_output', (data) {
      if (data is Map<String, dynamic>) {
        _consoleOutputController.add(data);
      }
    });
    
    // 监听论坛消息
    _socket?.on('forum_message', (data) {
      if (data is Map<String, dynamic>) {
        final message = ForumMessage.fromJson(data);
        _forumMessageController.add(message);
      }
    });
    
    // 监听状态更新
    _socket?.on('status_update', (data) {
      if (data is Map<String, dynamic>) {
        _statusUpdateController.add(data);
      }
    });
  }
  
  /// 断开连接
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
  }
  
  /// 重新连接
  void reconnect({String? customUrl}) {
    disconnect();
    connect(customUrl: customUrl);
  }
  
  /// 发送状态请求
  void requestStatus() {
    _socket?.emit('status_request');
  }
  
  /// 释放资源
  void dispose() {
    disconnect();
    _connectionController.close();
    _consoleOutputController.close();
    _forumMessageController.close();
    _statusUpdateController.close();
  }
}

