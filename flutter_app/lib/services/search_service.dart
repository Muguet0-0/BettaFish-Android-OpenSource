import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/settings_model.dart';

/// 搜索结果
class SearchResult {
  final String title;
  final String url;
  final String snippet;
  final String? source;
  final DateTime? publishedDate;

  SearchResult({
    required this.title,
    required this.url,
    required this.snippet,
    this.source,
    this.publishedDate,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'url': url,
    'snippet': snippet,
    'source': source,
    'publishedDate': publishedDate?.toIso8601String(),
  };
}

/// 搜索响应
class SearchResponse {
  final bool success;
  final List<SearchResult> results;
  final String? error;
  final SearchEngineType engine;

  SearchResponse({
    required this.success,
    this.results = const [],
    this.error,
    required this.engine,
  });
}

/// 搜索服务 - 支持多种搜索引擎
class SearchService {
  /// 执行搜索
  Future<SearchResponse> search(
    String query,
    SearchEngineConfig config, {
    int maxResults = 10,
  }) async {
    switch (config.type) {
      case SearchEngineType.duckduckgo:
        return _searchDuckDuckGo(query, maxResults);
      case SearchEngineType.tavily:
        return _searchTavily(query, config, maxResults);
      case SearchEngineType.bocha:
        return _searchBocha(query, config, maxResults);
      case SearchEngineType.bing:
        return _searchBing(query, config, maxResults);
      case SearchEngineType.google:
        return _searchGoogle(query, config, maxResults);
      case SearchEngineType.searxng:
        return _searchSearXNG(query, config, maxResults);
    }
  }

  /// DuckDuckGo搜索 (免费，无需API)
  Future<SearchResponse> _searchDuckDuckGo(String query, int maxResults) async {
    try {
      // 使用DuckDuckGo Lite版本，更容易解析
      final url = Uri.parse(
        'https://lite.duckduckgo.com/lite/?q=${Uri.encodeComponent(query)}',
      );
      final response = await http.get(url, headers: {
        'User-Agent': 'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
      }).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final results = _parseDuckDuckGoLite(response.body, maxResults);
        if (results.isNotEmpty) {
          return SearchResponse(
            success: true,
            results: results,
            engine: SearchEngineType.duckduckgo,
          );
        }
        // 如果lite版本没有结果，尝试html版本
        return _searchDuckDuckGoHtml(query, maxResults);
      }
      return SearchResponse(
        success: false,
        error: 'DuckDuckGo搜索失败: ${response.statusCode}',
        engine: SearchEngineType.duckduckgo,
      );
    } catch (e) {
      return SearchResponse(
        success: false,
        error: '搜索超时或网络错误: $e',
        engine: SearchEngineType.duckduckgo,
      );
    }
  }

  /// DuckDuckGo HTML版本备用
  Future<SearchResponse> _searchDuckDuckGoHtml(String query, int maxResults) async {
    try {
      final url = Uri.parse(
        'https://html.duckduckgo.com/html/?q=${Uri.encodeComponent(query)}',
      );
      final response = await http.get(url, headers: {
        'User-Agent': 'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36',
      }).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final results = _parseDuckDuckGoHtml(response.body, maxResults);
        return SearchResponse(
          success: true,
          results: results,
          engine: SearchEngineType.duckduckgo,
        );
      }
      return SearchResponse(
        success: false,
        error: 'DuckDuckGo HTML搜索失败: ${response.statusCode}',
        engine: SearchEngineType.duckduckgo,
      );
    } catch (e) {
      return SearchResponse(
        success: false,
        error: '网络错误: $e',
        engine: SearchEngineType.duckduckgo,
      );
    }
  }

  /// 解析DuckDuckGo Lite页面
  List<SearchResult> _parseDuckDuckGoLite(String html, int maxResults) {
    final results = <SearchResult>[];

    // Lite版本的结果在<tr>中，包含<a class="result-link">
    // 匹配结果链接
    final resultPattern = RegExp(
      r'<a[^>]*rel="nofollow"[^>]*href="([^"]+)"[^>]*>([^<]+)</a>',
      caseSensitive: false,
      multiLine: true,
    );

    // 匹配摘要 (在result-link之后的td中)
    final snippetPattern = RegExp(
      r'<td[^>]*class="result-snippet"[^>]*>([^<]*(?:<[^>]+>[^<]*)*)</td>',
      caseSensitive: false,
      multiLine: true,
    );

    final linkMatches = resultPattern.allMatches(html).toList();
    final snippetMatches = snippetPattern.allMatches(html).toList();

    for (int i = 0; i < linkMatches.length && results.length < maxResults; i++) {
      final link = linkMatches[i];
      var url = link.group(1) ?? '';
      final title = _decodeHtml(link.group(2) ?? '').trim();

      // 跳过DuckDuckGo内部链接
      if (url.contains('duckduckgo.com') || url.isEmpty || title.isEmpty) {
        continue;
      }

      // 处理URL
      if (url.startsWith('//')) {
        url = 'https:$url';
      }

      final snippet = i < snippetMatches.length
          ? _cleanSnippet(snippetMatches[i].group(1) ?? '')
          : '';

      results.add(SearchResult(
        title: title,
        url: url,
        snippet: snippet,
        source: 'DuckDuckGo',
      ));
    }
    return results;
  }

  List<SearchResult> _parseDuckDuckGoHtml(String html, int maxResults) {
    final results = <SearchResult>[];

    // HTML版本使用不同的class
    final resultBlockPattern = RegExp(
      r'<div[^>]*class="[^"]*result[^"]*"[^>]*>.*?</div>\s*</div>',
      caseSensitive: false,
      dotAll: true,
    );

    final linkPattern = RegExp(
      r'<a[^>]*class="[^"]*result__a[^"]*"[^>]*href="([^"]*)"[^>]*>(.*?)</a>',
      caseSensitive: false,
      dotAll: true,
    );

    final snippetPattern = RegExp(
      r'<a[^>]*class="[^"]*result__snippet[^"]*"[^>]*>(.*?)</a>',
      caseSensitive: false,
      dotAll: true,
    );

    final blocks = resultBlockPattern.allMatches(html);

    for (final block in blocks) {
      if (results.length >= maxResults) break;

      final blockHtml = block.group(0) ?? '';
      final linkMatch = linkPattern.firstMatch(blockHtml);
      final snippetMatch = snippetPattern.firstMatch(blockHtml);

      if (linkMatch != null) {
        var url = linkMatch.group(1) ?? '';
        final title = _cleanSnippet(linkMatch.group(2) ?? '');
        final snippet = snippetMatch != null
            ? _cleanSnippet(snippetMatch.group(1) ?? '')
            : '';

        if (url.isNotEmpty && !url.startsWith('/') && !url.contains('duckduckgo.com')) {
          results.add(SearchResult(
            title: title,
            url: url,
            snippet: snippet,
            source: 'DuckDuckGo',
          ));
        }
      }
    }
    return results;
  }

  String _cleanSnippet(String text) {
    return _decodeHtml(text)
        .replaceAll(RegExp(r'<[^>]+>'), '') // 移除HTML标签
        .replaceAll(RegExp(r'\s+'), ' ')    // 合并空白
        .trim();
  }

  String _decodeHtml(String html) {
    return html
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ')
        .replaceAll('<b>', '')
        .replaceAll('</b>', '');
  }

  /// Tavily搜索
  Future<SearchResponse> _searchTavily(
    String query, SearchEngineConfig config, int maxResults) async {
    if (config.apiKey == null || config.apiKey!.isEmpty) {
      return SearchResponse(
        success: false,
        error: '请配置Tavily API密钥',
        engine: SearchEngineType.tavily,
      );
    }

    try {
      final url = Uri.parse('https://api.tavily.com/search');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'api_key': config.apiKey,
          'query': query,
          'max_results': maxResults,
          'include_answer': false,
          'include_raw_content': false,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = (data['results'] as List?)?.map((r) {
          return SearchResult(
            title: r['title'] ?? '',
            url: r['url'] ?? '',
            snippet: r['content'] ?? '',
            source: Uri.tryParse(r['url'] ?? '')?.host,
          );
        }).toList() ?? [];

        return SearchResponse(
          success: true,
          results: results,
          engine: SearchEngineType.tavily,
        );
      }
      return SearchResponse(
        success: false,
        error: 'Tavily搜索失败: ${response.statusCode}',
        engine: SearchEngineType.tavily,
      );
    } catch (e) {
      return SearchResponse(
        success: false,
        error: '网络错误: $e',
        engine: SearchEngineType.tavily,
      );
    }
  }

  /// Bocha搜索
  Future<SearchResponse> _searchBocha(
    String query, SearchEngineConfig config, int maxResults) async {
    if (config.apiKey == null || config.apiKey!.isEmpty) {
      return SearchResponse(
        success: false,
        error: '请配置Bocha API密钥',
        engine: SearchEngineType.bocha,
      );
    }

    try {
      final url = Uri.parse('https://api.bochaai.com/v1/web-search');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${config.apiKey}',
        },
        body: jsonEncode({
          'query': query,
          'count': maxResults,
          'summary': true,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final webPages = data['data']?['webPages']?['value'] as List? ?? [];
        final results = webPages.map((r) {
          return SearchResult(
            title: r['name'] ?? '',
            url: r['url'] ?? '',
            snippet: r['summary'] ?? r['snippet'] ?? '',
            source: Uri.tryParse(r['url'] ?? '')?.host,
          );
        }).toList();

        return SearchResponse(
          success: true,
          results: results,
          engine: SearchEngineType.bocha,
        );
      }
      return SearchResponse(
        success: false,
        error: 'Bocha搜索失败: ${response.statusCode}',
        engine: SearchEngineType.bocha,
      );
    } catch (e) {
      return SearchResponse(
        success: false,
        error: '网络错误: $e',
        engine: SearchEngineType.bocha,
      );
    }
  }

  /// Bing搜索
  Future<SearchResponse> _searchBing(
    String query, SearchEngineConfig config, int maxResults) async {
    if (config.apiKey == null || config.apiKey!.isEmpty) {
      return SearchResponse(
        success: false,
        error: '请配置Bing API密钥',
        engine: SearchEngineType.bing,
      );
    }

    try {
      final url = Uri.parse(
        '${config.baseUrl ?? "https://api.bing.microsoft.com/v7.0/search"}?q=${Uri.encodeComponent(query)}&count=$maxResults',
      );
      final response = await http.get(url, headers: {
        'Ocp-Apim-Subscription-Key': config.apiKey!,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final webPages = data['webPages']?['value'] as List? ?? [];
        final results = webPages.map((r) {
          return SearchResult(
            title: r['name'] ?? '',
            url: r['url'] ?? '',
            snippet: r['snippet'] ?? '',
            source: Uri.tryParse(r['url'] ?? '')?.host,
          );
        }).toList();

        return SearchResponse(
          success: true,
          results: results,
          engine: SearchEngineType.bing,
        );
      }
      return SearchResponse(
        success: false,
        error: 'Bing搜索失败: ${response.statusCode}',
        engine: SearchEngineType.bing,
      );
    } catch (e) {
      return SearchResponse(
        success: false,
        error: '网络错误: $e',
        engine: SearchEngineType.bing,
      );
    }
  }

  /// Google搜索 (需要Custom Search API)
  Future<SearchResponse> _searchGoogle(
    String query, SearchEngineConfig config, int maxResults) async {
    if (config.apiKey == null || config.apiKey!.isEmpty) {
      return SearchResponse(
        success: false,
        error: '请配置Google API密钥和搜索引擎ID (格式: apiKey:searchEngineId)',
        engine: SearchEngineType.google,
      );
    }

    try {
      final parts = config.apiKey!.split(':');
      if (parts.length != 2) {
        return SearchResponse(
          success: false,
          error: 'Google API配置格式错误，应为: apiKey:searchEngineId',
          engine: SearchEngineType.google,
        );
      }

      final apiKey = parts[0];
      final cx = parts[1];
      final url = Uri.parse(
        'https://www.googleapis.com/customsearch/v1?key=$apiKey&cx=$cx&q=${Uri.encodeComponent(query)}&num=$maxResults',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final items = data['items'] as List? ?? [];
        final results = items.map((r) {
          return SearchResult(
            title: r['title'] ?? '',
            url: r['link'] ?? '',
            snippet: r['snippet'] ?? '',
            source: Uri.tryParse(r['link'] ?? '')?.host,
          );
        }).toList();

        return SearchResponse(
          success: true,
          results: results,
          engine: SearchEngineType.google,
        );
      }
      return SearchResponse(
        success: false,
        error: 'Google搜索失败: ${response.statusCode}',
        engine: SearchEngineType.google,
      );
    } catch (e) {
      return SearchResponse(
        success: false,
        error: '网络错误: $e',
        engine: SearchEngineType.google,
      );
    }
  }

  /// SearXNG搜索 (自托管)
  Future<SearchResponse> _searchSearXNG(
    String query, SearchEngineConfig config, int maxResults) async {
    final baseUrl = config.baseUrl;
    if (baseUrl == null || baseUrl.isEmpty) {
      return SearchResponse(
        success: false,
        error: '请配置SearXNG服务器地址',
        engine: SearchEngineType.searxng,
      );
    }

    try {
      final url = Uri.parse(
        '$baseUrl/search?q=${Uri.encodeComponent(query)}&format=json&pageno=1',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final items = data['results'] as List? ?? [];
        final results = items.take(maxResults).map((r) {
          return SearchResult(
            title: r['title'] ?? '',
            url: r['url'] ?? '',
            snippet: r['content'] ?? '',
            source: r['engine'] ?? Uri.tryParse(r['url'] ?? '')?.host,
          );
        }).toList();

        return SearchResponse(
          success: true,
          results: results,
          engine: SearchEngineType.searxng,
        );
      }
      return SearchResponse(
        success: false,
        error: 'SearXNG搜索失败: ${response.statusCode}',
        engine: SearchEngineType.searxng,
      );
    } catch (e) {
      return SearchResponse(
        success: false,
        error: '网络错误: $e',
        engine: SearchEngineType.searxng,
      );
    }
  }

  /// 使用所有启用的引擎进行搜索
  Future<List<SearchResponse>> searchAll(
    String query,
    List<SearchEngineConfig> engines, {
    int maxResults = 10,
  }) async {
    final enabledEngines = engines.where((e) => e.enabled).toList();
    if (enabledEngines.isEmpty) {
      return [
        SearchResponse(
          success: false,
          error: '没有启用任何搜索引擎',
          engine: SearchEngineType.duckduckgo,
        ),
      ];
    }

    final futures = enabledEngines.map(
      (e) => search(query, e, maxResults: maxResults),
    );
    return Future.wait(futures);
  }
}

