/// 报告任务状态
enum ReportTaskStatus {
  pending,
  running,
  completed,
  failed,
}

/// 报告任务模型
class ReportTask {
  final String taskId;
  final ReportTaskStatus status;
  final double progress;
  final String? message;
  final String? reportContent;
  final DateTime createdAt;
  final DateTime? completedAt;
  
  ReportTask({
    required this.taskId,
    required this.status,
    this.progress = 0.0,
    this.message,
    this.reportContent,
    DateTime? createdAt,
    this.completedAt,
  }) : createdAt = createdAt ?? DateTime.now();
  
  factory ReportTask.fromJson(Map<String, dynamic> json) {
    return ReportTask(
      taskId: json['task_id'] as String? ?? '',
      status: _parseStatus(json['status'] as String?),
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      message: json['message'] as String?,
      reportContent: json['report_content'] as String?,
    );
  }
  
  static ReportTaskStatus _parseStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return ReportTaskStatus.pending;
      case 'running':
        return ReportTaskStatus.running;
      case 'completed':
        return ReportTaskStatus.completed;
      case 'failed':
        return ReportTaskStatus.failed;
      default:
        return ReportTaskStatus.pending;
    }
  }
  
  bool get isCompleted => status == ReportTaskStatus.completed;
  bool get isFailed => status == ReportTaskStatus.failed;
  bool get isRunning => status == ReportTaskStatus.running;
  bool get isPending => status == ReportTaskStatus.pending;
  
  ReportTask copyWith({
    String? taskId,
    ReportTaskStatus? status,
    double? progress,
    String? message,
    String? reportContent,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return ReportTask(
      taskId: taskId ?? this.taskId,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      message: message ?? this.message,
      reportContent: reportContent ?? this.reportContent,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

/// 报告模型
class Report {
  final String id;
  final String title;
  final String content;
  final String query;
  final DateTime createdAt;
  
  Report({
    required this.id,
    required this.title,
    required this.content,
    required this.query,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
  
  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '舆情分析报告',
      content: json['content'] as String? ?? '',
      query: json['query'] as String? ?? '',
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'query': query,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

