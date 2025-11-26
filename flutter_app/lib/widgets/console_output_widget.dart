import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/console_output.dart';

/// 控制台输出组件
class ConsoleOutputWidget extends StatefulWidget {
  final List<ConsoleLine> lines;
  final VoidCallback? onRefresh;
  final bool isLoading;
  
  const ConsoleOutputWidget({
    super.key,
    required this.lines,
    this.onRefresh,
    this.isLoading = false,
  });
  
  @override
  State<ConsoleOutputWidget> createState() => _ConsoleOutputWidgetState();
}

class _ConsoleOutputWidgetState extends State<ConsoleOutputWidget> {
  final ScrollController _scrollController = ScrollController();
  bool _autoScroll = true;
  
  @override
  void didUpdateWidget(ConsoleOutputWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 新行添加时自动滚动到底部
    if (_autoScroll && widget.lines.length > oldWidget.lines.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
  }
  
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  
  Color _getLineColor(ConsoleLine line) {
    if (line.isError) return AppTheme.errorColor;
    if (line.isWarning) return Colors.orange;
    if (line.isSuccess) return AppTheme.runningColor;
    return AppTheme.textColor;
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border.all(
          color: AppTheme.borderColor,
          width: AppTheme.borderWidth,
        ),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      child: Column(
        children: [
          // 工具栏
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: Border(
                bottom: BorderSide(
                  color: AppTheme.borderColor,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                const Text(
                  '控制台输出',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                // 自动滚动开关
                Row(
                  children: [
                    const Text('自动滚动', style: TextStyle(fontSize: 11)),
                    Switch(
                      value: _autoScroll,
                      onChanged: (value) {
                        setState(() {
                          _autoScroll = value;
                        });
                      },
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ),
                // 刷新按钮
                if (widget.onRefresh != null)
                  IconButton(
                    onPressed: widget.isLoading ? null : widget.onRefresh,
                    icon: widget.isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh, size: 18),
                    tooltip: '刷新',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
              ],
            ),
          ),
          
          // 输出内容
          Expanded(
            child: widget.lines.isEmpty
                ? const Center(
                    child: Text(
                      '[系统] 等待连接...',
                      style: TextStyle(
                        color: AppTheme.secondaryTextColor,
                        fontSize: 12,
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(8),
                    itemCount: widget.lines.length,
                    itemBuilder: (context, index) {
                      final line = widget.lines[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 1),
                        child: Text(
                          line.content,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: _getLineColor(line),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

