import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 搜索引擎类型
enum SearchEngineType {
  tavily,
  bocha,
  duckduckgo,
  bing,
  google,
  searxng,
}

/// 搜索引擎配置
class SearchEngineConfig {
  final SearchEngineType type;
  final String name;
  final String? apiKey;
  final String? baseUrl;
  final bool enabled;
  final bool requiresApiKey;

  SearchEngineConfig({
    required this.type,
    required this.name,
    this.apiKey,
    this.baseUrl,
    this.enabled = false,
    this.requiresApiKey = true,
  });

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'name': name,
    'apiKey': apiKey,
    'baseUrl': baseUrl,
    'enabled': enabled,
    'requiresApiKey': requiresApiKey,
  };

  factory SearchEngineConfig.fromJson(Map<String, dynamic> json) {
    return SearchEngineConfig(
      type: SearchEngineType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => SearchEngineType.duckduckgo,
      ),
      name: json['name'] ?? '',
      apiKey: json['apiKey'],
      baseUrl: json['baseUrl'],
      enabled: json['enabled'] ?? false,
      requiresApiKey: json['requiresApiKey'] ?? true,
    );
  }

  SearchEngineConfig copyWith({
    SearchEngineType? type,
    String? name,
    String? apiKey,
    String? baseUrl,
    bool? enabled,
    bool? requiresApiKey,
  }) {
    return SearchEngineConfig(
      type: type ?? this.type,
      name: name ?? this.name,
      apiKey: apiKey ?? this.apiKey,
      baseUrl: baseUrl ?? this.baseUrl,
      enabled: enabled ?? this.enabled,
      requiresApiKey: requiresApiKey ?? this.requiresApiKey,
    );
  }
}

/// LLM配置
class LLMConfig {
  final String apiKey;
  final String baseUrl;
  final String modelName;
  final double temperature;
  final int maxTokens;

  LLMConfig({
    this.apiKey = '',
    this.baseUrl = 'https://api.openai.com/v1',
    this.modelName = 'gpt-3.5-turbo',
    this.temperature = 0.7,
    this.maxTokens = 4096,
  });

  Map<String, dynamic> toJson() => {
    'apiKey': apiKey,
    'baseUrl': baseUrl,
    'modelName': modelName,
    'temperature': temperature,
    'maxTokens': maxTokens,
  };

  factory LLMConfig.fromJson(Map<String, dynamic> json) {
    return LLMConfig(
      apiKey: json['apiKey'] ?? '',
      baseUrl: json['baseUrl'] ?? 'https://api.openai.com/v1',
      modelName: json['modelName'] ?? 'gpt-3.5-turbo',
      temperature: (json['temperature'] ?? 0.7).toDouble(),
      maxTokens: json['maxTokens'] ?? 4096,
    );
  }

  LLMConfig copyWith({
    String? apiKey,
    String? baseUrl,
    String? modelName,
    double? temperature,
    int? maxTokens,
  }) {
    return LLMConfig(
      apiKey: apiKey ?? this.apiKey,
      baseUrl: baseUrl ?? this.baseUrl,
      modelName: modelName ?? this.modelName,
      temperature: temperature ?? this.temperature,
      maxTokens: maxTokens ?? this.maxTokens,
    );
  }

  bool get isConfigured => apiKey.isNotEmpty && baseUrl.isNotEmpty;
}

/// 应用设置
class AppSettings {
  final LLMConfig llmConfig;
  final List<SearchEngineConfig> searchEngines;
  final int maxSearchResults;
  final bool autoAnalyze;

  AppSettings({
    LLMConfig? llmConfig,
    List<SearchEngineConfig>? searchEngines,
    this.maxSearchResults = 10,
    this.autoAnalyze = true,
  }) : llmConfig = llmConfig ?? LLMConfig(),
       searchEngines = searchEngines ?? _defaultSearchEngines();

  static List<SearchEngineConfig> _defaultSearchEngines() {
    return [
      SearchEngineConfig(
        type: SearchEngineType.duckduckgo,
        name: 'DuckDuckGo',
        enabled: true,
        requiresApiKey: false,
      ),
      SearchEngineConfig(
        type: SearchEngineType.tavily,
        name: 'Tavily',
        baseUrl: 'https://api.tavily.com',
        requiresApiKey: true,
      ),
      SearchEngineConfig(
        type: SearchEngineType.bocha,
        name: 'Bocha',
        requiresApiKey: true,
      ),
      SearchEngineConfig(
        type: SearchEngineType.bing,
        name: 'Bing Search',
        baseUrl: 'https://api.bing.microsoft.com/v7.0/search',
        requiresApiKey: true,
      ),
      SearchEngineConfig(
        type: SearchEngineType.google,
        name: 'Google Search',
        requiresApiKey: true,
      ),
      SearchEngineConfig(
        type: SearchEngineType.searxng,
        name: 'SearXNG (自托管)',
        requiresApiKey: false,
      ),
    ];
  }

  Map<String, dynamic> toJson() => {
    'llmConfig': llmConfig.toJson(),
    'searchEngines': searchEngines.map((e) => e.toJson()).toList(),
    'maxSearchResults': maxSearchResults,
    'autoAnalyze': autoAnalyze,
  };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      llmConfig: LLMConfig.fromJson(json['llmConfig'] ?? {}),
      searchEngines: (json['searchEngines'] as List?)
          ?.map((e) => SearchEngineConfig.fromJson(e))
          .toList(),
      maxSearchResults: json['maxSearchResults'] ?? 10,
      autoAnalyze: json['autoAnalyze'] ?? true,
    );
  }

  AppSettings copyWith({
    LLMConfig? llmConfig,
    List<SearchEngineConfig>? searchEngines,
    int? maxSearchResults,
    bool? autoAnalyze,
  }) {
    return AppSettings(
      llmConfig: llmConfig ?? this.llmConfig,
      searchEngines: searchEngines ?? this.searchEngines,
      maxSearchResults: maxSearchResults ?? this.maxSearchResults,
      autoAnalyze: autoAnalyze ?? this.autoAnalyze,
    );
  }

  /// 获取已启用的搜索引擎
  List<SearchEngineConfig> get enabledSearchEngines =>
      searchEngines.where((e) => e.enabled).toList();
}

/// 设置存储服务
class SettingsStorage {
  static const String _settingsKey = 'app_settings';

  static Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_settingsKey);
    if (jsonStr != null) {
      try {
        return AppSettings.fromJson(jsonDecode(jsonStr));
      } catch (e) {
        return AppSettings();
      }
    }
    return AppSettings();
  }

  static Future<void> save(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsKey, jsonEncode(settings.toJson()));
  }
}

