import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../config/app_theme.dart';
import '../config/app_config.dart';

/// 引擎WebView组件 - 用于嵌入Streamlit页面
class EngineWebViewWidget extends StatefulWidget {
  final String engineName;
  final String serverUrl;
  final bool isRunning;
  
  const EngineWebViewWidget({
    super.key,
    required this.engineName,
    required this.serverUrl,
    this.isRunning = false,
  });
  
  @override
  State<EngineWebViewWidget> createState() => _EngineWebViewWidgetState();
}

class _EngineWebViewWidgetState extends State<EngineWebViewWidget> {
  late WebViewController _controller;
  bool _isLoading = true;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _initWebView();
  }
  
  void _initWebView() {
    final port = AppConfig.enginePorts[widget.engineName];
    if (port == null) {
      setState(() {
        _errorMessage = '未知引擎: ${widget.engineName}';
        _isLoading = false;
      });
      return;
    }
    
    // 解析服务器地址获取主机
    final uri = Uri.parse(widget.serverUrl);
    final engineUrl = 'http://${uri.host}:$port';
    
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppTheme.backgroundColor)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() {
              _isLoading = true;
              _errorMessage = null;
            });
          },
          onPageFinished: (url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (error) {
            setState(() {
              _isLoading = false;
              _errorMessage = '加载失败: ${error.description}';
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(engineUrl));
  }
  
  @override
  void didUpdateWidget(EngineWebViewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.engineName != oldWidget.engineName ||
        widget.serverUrl != oldWidget.serverUrl) {
      _initWebView();
    }
  }
  
  void _reload() {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    _controller.reload();
  }
  
  @override
  Widget build(BuildContext context) {
    if (!widget.isRunning) {
      return _buildNotRunningState();
    }
    
    if (_errorMessage != null) {
      return _buildErrorState();
    }
    
    return Stack(
      children: [
        WebViewWidget(controller: _controller),
        if (_isLoading)
          const Center(
            child: CircularProgressIndicator(),
          ),
      ],
    );
  }
  
  Widget _buildNotRunningState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.power_off,
            size: 48,
            color: AppTheme.secondaryTextColor,
          ),
          const SizedBox(height: 16),
          Text(
            '${AppConfig.engineNames[widget.engineName] ?? widget.engineName} 未运行',
            style: TextStyle(
              color: AppTheme.secondaryTextColor,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '请先启动系统',
            style: TextStyle(
              color: AppTheme.secondaryTextColor,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: AppTheme.errorColor,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: TextStyle(
              color: AppTheme.errorColor,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
            label: const Text('重试'),
          ),
        ],
      ),
    );
  }
}

