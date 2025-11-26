import 'package:flutter/material.dart';
import '../config/app_theme.dart';

/// 论坛消息类型
enum ForumMessageType {
  agent,
  system,
  host,
}

/// 论坛消息来源
enum ForumMessageSource {
  query,
  insight,
  media,
  host,
  system,
}

/// 论坛消息模型
class ForumMessage {
  final ForumMessageType type;
  final ForumMessageSource source;
  final String sender;
  final String content;
  final String timestamp;
  
  ForumMessage({
    required this.type,
    required this.source,
    required this.sender,
    required this.content,
    required this.timestamp,
  });
  
  factory ForumMessage.fromJson(Map<String, dynamic> json) {
    return ForumMessage(
      type: _parseType(json['type'] as String?),
      source: _parseSource(json['source'] as String?),
      sender: json['sender'] as String? ?? 'Unknown',
      content: json['content'] as String? ?? '',
      timestamp: json['timestamp'] as String? ?? '',
    );
  }
  
  static ForumMessageType _parseType(String? type) {
    switch (type) {
      case 'agent':
        return ForumMessageType.agent;
      case 'host':
        return ForumMessageType.host;
      case 'system':
        return ForumMessageType.system;
      default:
        return ForumMessageType.agent;
    }
  }
  
  static ForumMessageSource _parseSource(String? source) {
    final upperSource = source?.toUpperCase() ?? '';
    if (upperSource.contains('QUERY')) {
      return ForumMessageSource.query;
    } else if (upperSource.contains('INSIGHT')) {
      return ForumMessageSource.insight;
    } else if (upperSource.contains('MEDIA')) {
      return ForumMessageSource.media;
    } else if (upperSource.contains('HOST')) {
      return ForumMessageSource.host;
    }
    return ForumMessageSource.system;
  }
  
  /// 获取消息背景颜色
  Color get backgroundColor {
    switch (source) {
      case ForumMessageSource.query:
        return AppTheme.queryMessageBg;
      case ForumMessageSource.insight:
        return AppTheme.insightMessageBg;
      case ForumMessageSource.media:
        return AppTheme.mediaMessageBg;
      case ForumMessageSource.host:
        return AppTheme.hostMessageBg;
      case ForumMessageSource.system:
        return Colors.grey.shade100;
    }
  }
  
  /// 获取发送者显示名称
  String get displaySender {
    switch (source) {
      case ForumMessageSource.query:
        return 'Query Engine';
      case ForumMessageSource.insight:
        return 'Insight Engine';
      case ForumMessageSource.media:
        return 'Media Engine';
      case ForumMessageSource.host:
        return 'Forum Host';
      case ForumMessageSource.system:
        return 'System';
    }
  }
  
  /// 获取发送者图标
  IconData get senderIcon {
    switch (source) {
      case ForumMessageSource.query:
        return Icons.search;
      case ForumMessageSource.insight:
        return Icons.lightbulb_outline;
      case ForumMessageSource.media:
        return Icons.perm_media_outlined;
      case ForumMessageSource.host:
        return Icons.forum_outlined;
      case ForumMessageSource.system:
        return Icons.info_outline;
    }
  }
}

