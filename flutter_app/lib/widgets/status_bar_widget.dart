import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/app_theme.dart';

/// 状态栏组件
class StatusBarWidget extends StatefulWidget {
  final bool isConnected;
  final String? errorMessage;
  
  const StatusBarWidget({
    super.key,
    required this.isConnected,
    this.errorMessage,
  });
  
  @override
  State<StatusBarWidget> createState() => _StatusBarWidgetState();
}

class _StatusBarWidgetState extends State<StatusBarWidget> {
  String _currentTime = '';
  
  @override
  void initState() {
    super.initState();
    _updateTime();
    // 每秒更新时间
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        _updateTime();
        return true;
      }
      return false;
    });
  }
  
  void _updateTime() {
    setState(() {
      _currentTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(
          top: BorderSide(
            color: AppTheme.borderColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // 连接状态
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: widget.isConnected 
                      ? AppTheme.runningColor 
                      : AppTheme.errorColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                widget.isConnected ? '已连接' : '未连接',
                style: TextStyle(
                  fontSize: 12,
                  color: widget.isConnected 
                      ? AppTheme.textColor 
                      : AppTheme.errorColor,
                ),
              ),
            ],
          ),
          
          // 错误消息
          if (widget.errorMessage != null) ...[
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                widget.errorMessage!,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.errorColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ] else
            const Spacer(),
          
          // 当前时间
          Text(
            _currentTime,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }
}

