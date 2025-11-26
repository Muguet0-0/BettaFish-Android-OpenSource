/// 引擎状态枚举
enum EngineStatusType {
  stopped,
  starting,
  running,
  error,
}

/// 引擎状态模型
class EngineStatus {
  final String name;
  final EngineStatusType status;
  final int? port;
  final int outputLines;
  
  EngineStatus({
    required this.name,
    required this.status,
    this.port,
    this.outputLines = 0,
  });
  
  factory EngineStatus.fromJson(String name, Map<String, dynamic> json) {
    return EngineStatus(
      name: name,
      status: _parseStatus(json['status'] as String?),
      port: json['port'] as int?,
      outputLines: json['output_lines'] as int? ?? 0,
    );
  }
  
  static EngineStatusType _parseStatus(String? status) {
    switch (status) {
      case 'running':
        return EngineStatusType.running;
      case 'starting':
        return EngineStatusType.starting;
      case 'stopped':
        return EngineStatusType.stopped;
      case 'error':
        return EngineStatusType.error;
      default:
        return EngineStatusType.stopped;
    }
  }
  
  bool get isRunning => status == EngineStatusType.running;
  bool get isStopped => status == EngineStatusType.stopped;
  bool get isStarting => status == EngineStatusType.starting;
  
  EngineStatus copyWith({
    String? name,
    EngineStatusType? status,
    int? port,
    int? outputLines,
  }) {
    return EngineStatus(
      name: name ?? this.name,
      status: status ?? this.status,
      port: port ?? this.port,
      outputLines: outputLines ?? this.outputLines,
    );
  }
}

/// 系统状态模型
class SystemStatus {
  final bool started;
  final bool starting;
  final Map<String, EngineStatus> engines;
  
  SystemStatus({
    required this.started,
    required this.starting,
    required this.engines,
  });
  
  factory SystemStatus.initial() {
    return SystemStatus(
      started: false,
      starting: false,
      engines: {
        'insight': EngineStatus(name: 'insight', status: EngineStatusType.stopped, port: 8501),
        'media': EngineStatus(name: 'media', status: EngineStatusType.stopped, port: 8502),
        'query': EngineStatus(name: 'query', status: EngineStatusType.stopped, port: 8503),
        'forum': EngineStatus(name: 'forum', status: EngineStatusType.stopped),
        'report': EngineStatus(name: 'report', status: EngineStatusType.stopped),
      },
    );
  }
  
  factory SystemStatus.fromJson(Map<String, dynamic> json) {
    final engines = <String, EngineStatus>{};
    json.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        engines[key] = EngineStatus.fromJson(key, value);
      }
    });
    return SystemStatus(
      started: true,
      starting: false,
      engines: engines,
    );
  }
  
  bool get allEnginesRunning {
    return engines.values.where((e) => e.name != 'report').every((e) => e.isRunning);
  }
  
  SystemStatus copyWith({
    bool? started,
    bool? starting,
    Map<String, EngineStatus>? engines,
  }) {
    return SystemStatus(
      started: started ?? this.started,
      starting: starting ?? this.starting,
      engines: engines ?? this.engines,
    );
  }
}

