/// 应用配置常量
class AppConfig {
  // 服务器配置
  static const String defaultServerUrl = 'http://192.168.1.100:5000';
  
  // 引擎端口配置
  static const Map<String, int> enginePorts = {
    'insight': 8501,
    'media': 8502,
    'query': 8503,
  };
  
  // 引擎名称映射
  static const Map<String, String> engineNames = {
    'insight': 'Insight Engine',
    'media': 'Media Engine',
    'query': 'Query Engine',
    'forum': 'Forum Engine',
    'report': 'Report Engine',
  };
  
  // 配置字段分组
  static const List<Map<String, dynamic>> configFieldGroups = [
    {
      'title': '数据库配置',
      'fields': [
        {'key': 'DB_DIALECT', 'label': '数据库类型', 'type': 'text'},
        {'key': 'DB_HOST', 'label': '数据库主机', 'type': 'text'},
        {'key': 'DB_PORT', 'label': '数据库端口', 'type': 'number'},
        {'key': 'DB_USER', 'label': '数据库用户', 'type': 'text'},
        {'key': 'DB_PASSWORD', 'label': '数据库密码', 'type': 'password'},
        {'key': 'DB_NAME', 'label': '数据库名称', 'type': 'text'},
        {'key': 'DB_CHARSET', 'label': '字符集', 'type': 'text'},
      ],
    },
    {
      'title': 'Insight Agent 配置',
      'fields': [
        {'key': 'INSIGHT_ENGINE_API_KEY', 'label': 'API Key', 'type': 'password'},
        {'key': 'INSIGHT_ENGINE_BASE_URL', 'label': 'Base URL', 'type': 'text'},
        {'key': 'INSIGHT_ENGINE_MODEL_NAME', 'label': '模型名称', 'type': 'text'},
      ],
    },
    {
      'title': 'Media Agent 配置',
      'fields': [
        {'key': 'MEDIA_ENGINE_API_KEY', 'label': 'API Key', 'type': 'password'},
        {'key': 'MEDIA_ENGINE_BASE_URL', 'label': 'Base URL', 'type': 'text'},
        {'key': 'MEDIA_ENGINE_MODEL_NAME', 'label': '模型名称', 'type': 'text'},
      ],
    },
    {
      'title': 'Query Agent 配置',
      'fields': [
        {'key': 'QUERY_ENGINE_API_KEY', 'label': 'API Key', 'type': 'password'},
        {'key': 'QUERY_ENGINE_BASE_URL', 'label': 'Base URL', 'type': 'text'},
        {'key': 'QUERY_ENGINE_MODEL_NAME', 'label': '模型名称', 'type': 'text'},
      ],
    },
    {
      'title': 'Report Agent 配置',
      'fields': [
        {'key': 'REPORT_ENGINE_API_KEY', 'label': 'API Key', 'type': 'password'},
        {'key': 'REPORT_ENGINE_BASE_URL', 'label': 'Base URL', 'type': 'text'},
        {'key': 'REPORT_ENGINE_MODEL_NAME', 'label': '模型名称', 'type': 'text'},
      ],
    },
    {
      'title': 'Forum Host 配置',
      'fields': [
        {'key': 'FORUM_HOST_API_KEY', 'label': 'API Key', 'type': 'password'},
        {'key': 'FORUM_HOST_BASE_URL', 'label': 'Base URL', 'type': 'text'},
        {'key': 'FORUM_HOST_MODEL_NAME', 'label': '模型名称', 'type': 'text'},
      ],
    },
    {
      'title': 'Keyword Optimizer 配置',
      'fields': [
        {'key': 'KEYWORD_OPTIMIZER_API_KEY', 'label': 'API Key', 'type': 'password'},
        {'key': 'KEYWORD_OPTIMIZER_BASE_URL', 'label': 'Base URL', 'type': 'text'},
        {'key': 'KEYWORD_OPTIMIZER_MODEL_NAME', 'label': '模型名称', 'type': 'text'},
      ],
    },
    {
      'title': '网络工具配置',
      'fields': [
        {'key': 'TAVILY_API_KEY', 'label': 'Tavily API Key', 'type': 'password'},
        {'key': 'BOCHA_WEB_SEARCH_API_KEY', 'label': 'Bocha API Key', 'type': 'password'},
      ],
    },
  ];
  
  // 引擎颜色配置 (用于论坛消息)
  static const Map<String, int> engineColors = {
    'QUERY': 0xFFEAF1F8,   // 蓝色背景
    'INSIGHT': 0xFFF2EBF3, // 紫色背景
    'MEDIA': 0xFFEBF2EA,   // 绿色背景
    'HOST': 0xFFFFF8DC,    // 金色背景
  };
}

