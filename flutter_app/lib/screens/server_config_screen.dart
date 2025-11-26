import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_theme.dart';
import '../config/app_config.dart';
import '../providers/app_state_provider.dart';

/// 服务器配置屏幕
class ServerConfigScreen extends StatefulWidget {
  const ServerConfigScreen({super.key});
  
  @override
  State<ServerConfigScreen> createState() => _ServerConfigScreenState();
}

class _ServerConfigScreenState extends State<ServerConfigScreen> {
  final TextEditingController _urlController = TextEditingController();
  bool _isConnecting = false;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _loadSavedUrl();
  }
  
  Future<void> _loadSavedUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString('server_url') ?? AppConfig.defaultServerUrl;
    _urlController.text = savedUrl;
  }
  
  Future<void> _saveUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_url', url);
  }
  
  Future<void> _connect() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() {
        _errorMessage = '请输入服务器地址';
      });
      return;
    }
    
    setState(() {
      _isConnecting = true;
      _errorMessage = null;
    });
    
    try {
      final appState = context.read<AppStateProvider>();
      await appState.connectToServer(url);
      await _saveUrl(url);
      
      // 等待连接
      await Future.delayed(const Duration(seconds: 2));
      
      if (appState.isConnected) {
        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        setState(() {
          _errorMessage = '连接失败，请检查服务器地址';
          _isConnecting = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '连接错误: $e';
        _isConnecting = false;
      });
    }
  }
  
  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('服务器配置'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 标题
            const Text(
              '微舆',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '致力于打造简洁通用的舆情分析平台',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.secondaryTextColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            
            // 服务器地址输入
            const Text(
              '服务器地址',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                hintText: 'http://192.168.1.100:5000',
                prefixIcon: const Icon(Icons.link),
                errorText: _errorMessage,
              ),
              keyboardType: TextInputType.url,
              enabled: !_isConnecting,
            ),
            const SizedBox(height: 8),
            Text(
              '请输入运行微舆后端服务的服务器地址',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.secondaryTextColor,
              ),
            ),
            const SizedBox(height: 24),
            
            // 连接按钮
            ElevatedButton(
              onPressed: _isConnecting ? null : _connect,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isConnecting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('连接'),
            ),
            
            const Spacer(),
            
            // 帮助信息
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '使用说明',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '1. 确保后端服务已启动\n'
                    '2. 手机与服务器在同一网络\n'
                    '3. 输入服务器的IP地址和端口',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

