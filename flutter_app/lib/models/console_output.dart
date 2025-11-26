/// 控制台输出行模型
class ConsoleLine {
  final String content;
  final DateTime timestamp;
  final String? app;
  
  ConsoleLine({
    required this.content,
    DateTime? timestamp,
    this.app,
  }) : timestamp = timestamp ?? DateTime.now();
  
  factory ConsoleLine.fromJson(Map<String, dynamic> json) {
    return ConsoleLine(
      content: json['line'] as String? ?? '',
      app: json['app'] as String?,
    );
  }
  
  factory ConsoleLine.fromString(String line) {
    return ConsoleLine(content: line);
  }
  
  /// 判断是否为错误行
  bool get isError {
    final lowerContent = content.toLowerCase();
    return lowerContent.contains('error') || 
           lowerContent.contains('exception') ||
           lowerContent.contains('failed');
  }
  
  /// 判断是否为警告行
  bool get isWarning {
    final lowerContent = content.toLowerCase();
    return lowerContent.contains('warning') || 
           lowerContent.contains('warn');
  }
  
  /// 判断是否为成功行
  bool get isSuccess {
    final lowerContent = content.toLowerCase();
    return lowerContent.contains('success') || 
           lowerContent.contains('started') ||
           lowerContent.contains('running');
  }
}

/// 控制台输出管理
class ConsoleOutput {
  final String engineName;
  final List<ConsoleLine> lines;
  final int maxLines;
  
  ConsoleOutput({
    required this.engineName,
    List<ConsoleLine>? lines,
    this.maxLines = 1000,
  }) : lines = lines ?? [];
  
  /// 添加一行输出
  void addLine(ConsoleLine line) {
    lines.add(line);
    // 限制最大行数
    if (lines.length > maxLines) {
      lines.removeAt(0);
    }
  }
  
  /// 添加多行输出
  void addLines(List<ConsoleLine> newLines) {
    lines.addAll(newLines);
    // 限制最大行数
    while (lines.length > maxLines) {
      lines.removeAt(0);
    }
  }
  
  /// 清空输出
  void clear() {
    lines.clear();
  }
  
  /// 获取最后N行
  List<ConsoleLine> getLastLines(int count) {
    if (lines.length <= count) {
      return List.from(lines);
    }
    return lines.sublist(lines.length - count);
  }
  
  /// 复制并添加新行
  ConsoleOutput copyWithNewLine(ConsoleLine line) {
    final newLines = List<ConsoleLine>.from(lines);
    newLines.add(line);
    if (newLines.length > maxLines) {
      newLines.removeAt(0);
    }
    return ConsoleOutput(
      engineName: engineName,
      lines: newLines,
      maxLines: maxLines,
    );
  }
}

