import '../models/settings_model.dart';
import 'llm_service.dart';
import 'search_service.dart';

/// 分析结果
class AnalysisResult {
  final String query;
  final List<SearchResult> searchResults;
  final String? analysis;
  final String? error;
  final DateTime timestamp;
  final bool isAnalyzing;

  AnalysisResult({
    required this.query,
    this.searchResults = const [],
    this.analysis,
    this.error,
    DateTime? timestamp,
    this.isAnalyzing = false,
  }) : timestamp = timestamp ?? DateTime.now();

  AnalysisResult copyWith({
    String? query,
    List<SearchResult>? searchResults,
    String? analysis,
    String? error,
    DateTime? timestamp,
    bool? isAnalyzing,
  }) {
    return AnalysisResult(
      query: query ?? this.query,
      searchResults: searchResults ?? this.searchResults,
      analysis: analysis ?? this.analysis,
      error: error ?? this.error,
      timestamp: timestamp ?? this.timestamp,
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
    );
  }
}

/// 分析进度回调
typedef AnalysisProgressCallback = void Function(String stage, double progress);

/// 分析服务 - 整合搜索和LLM分析
class AnalysisService {
  final SearchService _searchService = SearchService();
  LLMService? _llmService;

  void updateLLMConfig(LLMConfig config) {
    _llmService = LLMService(config: config);
  }

  /// 执行完整的搜索和分析流程
  Future<AnalysisResult> analyze(
    String query,
    AppSettings settings, {
    AnalysisProgressCallback? onProgress,
  }) async {
    final enabledEngines = settings.enabledSearchEngines;
    final engineNames = enabledEngines.map((e) => e.name).join(', ');
    onProgress?.call('联合搜索中 ($engineNames)...', 0.1);

    // 1. 执行多引擎联合搜索
    final searchResponses = await _searchService.searchAll(
      query,
      settings.searchEngines,
      maxResults: settings.maxSearchResults,
    );

    // 合并所有搜索结果并去重
    final allResults = <SearchResult>[];
    final seenUrls = <String>{};
    final errors = <String>[];
    final successEngines = <String>[];

    for (final response in searchResponses) {
      if (response.success) {
        successEngines.add(response.engine.name);
        for (final result in response.results) {
          // 基于URL去重
          if (!seenUrls.contains(result.url)) {
            seenUrls.add(result.url);
            allResults.add(result);
          }
        }
      } else if (response.error != null) {
        errors.add('${response.engine.name}: ${response.error}');
      }
    }

    onProgress?.call(
      '${successEngines.join("+")} 搜索完成，整合 ${allResults.length} 条结果',
      0.4,
    );

    if (allResults.isEmpty) {
      return AnalysisResult(
        query: query,
        error: errors.isNotEmpty ? errors.join('\n') : '未找到任何搜索结果',
      );
    }

    // 2. 使用LLM分析
    if (!settings.autoAnalyze || !settings.llmConfig.isConfigured) {
      return AnalysisResult(
        query: query,
        searchResults: allResults,
        analysis: settings.llmConfig.isConfigured ? null : '请先配置LLM API以启用自动分析',
      );
    }

    onProgress?.call('正在分析搜索结果...', 0.6);
    _llmService ??= LLMService(config: settings.llmConfig);

    final analysisResponse = await _llmService!.analyzeSearchResults(
      query,
      allResults.map((r) => r.toJson()).toList(),
    );

    onProgress?.call('分析完成', 1.0);

    if (analysisResponse.success) {
      return AnalysisResult(
        query: query,
        searchResults: allResults,
        analysis: analysisResponse.content,
      );
    } else {
      return AnalysisResult(
        query: query,
        searchResults: allResults,
        error: '分析失败: ${analysisResponse.error}',
      );
    }
  }

  /// 仅执行搜索
  Future<AnalysisResult> searchOnly(String query, AppSettings settings) async {
    final searchResponses = await _searchService.searchAll(
      query,
      settings.searchEngines,
      maxResults: settings.maxSearchResults,
    );

    final allResults = <SearchResult>[];
    final errors = <String>[];

    for (final response in searchResponses) {
      if (response.success) {
        allResults.addAll(response.results);
      } else if (response.error != null) {
        errors.add('${response.engine.name}: ${response.error}');
      }
    }

    return AnalysisResult(
      query: query,
      searchResults: allResults,
      error: allResults.isEmpty && errors.isNotEmpty ? errors.join('\n') : null,
    );
  }

  /// 对已有结果执行分析
  Future<AnalysisResult> analyzeExisting(
    AnalysisResult result,
    LLMConfig config,
  ) async {
    if (result.searchResults.isEmpty) {
      return result.copyWith(error: '没有可分析的搜索结果');
    }

    final llmService = LLMService(config: config);
    final response = await llmService.analyzeSearchResults(
      result.query,
      result.searchResults.map((r) => r.toJson()).toList(),
    );

    if (response.success) {
      return result.copyWith(analysis: response.content, error: null);
    } else {
      return result.copyWith(error: '分析失败: ${response.error}');
    }
  }
}

