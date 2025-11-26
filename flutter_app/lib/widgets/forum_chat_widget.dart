import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/forum_message.dart';

/// 论坛聊天组件
class ForumChatWidget extends StatefulWidget {
  final List<ForumMessage> messages;
  final VoidCallback? onRefresh;
  final bool isLoading;
  
  const ForumChatWidget({
    super.key,
    required this.messages,
    this.onRefresh,
    this.isLoading = false,
  });
  
  @override
  State<ForumChatWidget> createState() => _ForumChatWidgetState();
}

class _ForumChatWidgetState extends State<ForumChatWidget> {
  final ScrollController _scrollController = ScrollController();
  
  @override
  void didUpdateWidget(ForumChatWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 新消息时自动滚动到底部
    if (widget.messages.length > oldWidget.messages.length) {
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
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        border: Border.all(
          color: AppTheme.borderColor,
          width: AppTheme.borderWidth,
        ),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      child: Column(
        children: [
          // 标题栏
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
                const Icon(Icons.forum_outlined, size: 18),
                const SizedBox(width: 8),
                const Text(
                  'Forum Engine - 多Agent讨论',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
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
          
          // 消息列表
          Expanded(
            child: widget.messages.isEmpty
                ? const Center(
                    child: Text(
                      '等待Agent讨论开始...',
                      style: TextStyle(
                        color: AppTheme.secondaryTextColor,
                        fontSize: 14,
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: widget.messages.length,
                    itemBuilder: (context, index) {
                      return _ForumMessageBubble(
                        message: widget.messages[index],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// 论坛消息气泡
class _ForumMessageBubble extends StatelessWidget {
  final ForumMessage message;
  
  const _ForumMessageBubble({required this.message});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: message.backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 发送者信息
          Row(
            children: [
              Icon(message.senderIcon, size: 16),
              const SizedBox(width: 6),
              Text(
                message.displaySender,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              Text(
                message.timestamp,
                style: TextStyle(
                  color: AppTheme.secondaryTextColor,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 消息内容
          Text(
            message.content,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
}

