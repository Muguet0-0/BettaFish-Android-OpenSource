import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/app_theme.dart';
import '../models/settings_model.dart';
import '../services/analysis_service.dart';
import '../services/search_service.dart';
import 'settings_screen.dart';

/// 主屏幕 - 本地舆情分析
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final AnalysisService _analysisService = AnalysisService();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _searchFocusNode = FocusNode();

  AppSettings _settings = AppSettings();
  AnalysisResult? _result;
  bool _isLoading = false;
  String _progressText = '';
  double _searchProgress = 0.0;

  // 联合搜索：临时选择的搜索引擎
  Set<SearchEngineType> _selectedEngines = {};

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final settings = await SettingsStorage.load();
    setState(() {
      _settings = settings;
      // 初始化选中可用的搜索引擎（已配置好的）
      _selectedEngines = settings.searchEngines
          .where((e) {
            // DuckDuckGo和SearXNG不需要API
            if (!e.requiresApiKey) {
              if (e.type == SearchEngineType.searxng) {
                return e.baseUrl != null && e.baseUrl!.isNotEmpty;
              }
              return true; // DuckDuckGo默认可用
            }
            // 其他引擎需要API Key
            return e.apiKey != null && e.apiKey!.isNotEmpty;
          })
          .map((e) => e.type)
          .toSet();
    });
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入搜索关键词')),
      );
      return;
    }

    // 检查是否选择了搜索引擎
    if (_selectedEngines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择至少一个搜索引擎')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _progressText = '开始联合搜索 (${_selectedEngines.length}个引擎)...';
      _result = null;
    });

    // 构建临时的搜索引擎配置列表
    final selectedEngineConfigs = _settings.searchEngines
        .where((e) => _selectedEngines.contains(e.type))
        .map((e) => e.copyWith(enabled: true))
        .toList();

    final tempSettings = _settings.copyWith(searchEngines: selectedEngineConfigs);

    final result = await _analysisService.analyze(
      query,
      tempSettings,
      onProgress: (stage, progress) {
        if (mounted) {
          setState(() => _progressText = stage);
        }
      },
    );

    if (mounted) {
      setState(() {
        _result = result;
        _isLoading = false;
      });
    }
  }

  Future<void> _reanalyze() async {
    if (_result == null || _result!.searchResults.isEmpty) return;

    if (!_settings.llmConfig.isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先在设置中配置LLM API')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _progressText = '正在分析...';
    });

    final newResult = await _analysisService.analyzeExisting(
      _result!,
      _settings.llmConfig,
    );

    if (mounted) {
      setState(() {
        _result = newResult;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // 顶部搜索区域
            _buildSearchHeader(),
            // 进度提示
            if (_isLoading) _buildProgressBar(),
            // 结果显示
            Expanded(child: _buildResultView()),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo 和设置按钮
          Row(
            children: [
              // Logo
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.water_drop_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '微舆',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      '智能舆情分析助手',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // 设置按钮
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.settings_rounded, color: AppTheme.textSecondary),
                  tooltip: '设置',
                  onPressed: () async {
                    final newSettings = await Navigator.push<AppSettings>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SettingsScreen(settings: _settings),
                      ),
                    );
                    if (newSettings != null) {
                      setState(() {
                        _settings = newSettings;
                        _updateSelectedEngines();
                      });
                    } else {
                      _loadSettings();
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // 搜索框
          Container(
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.textHint.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    style: const TextStyle(fontSize: 16, color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      hintText: '输入关键词开始舆情分析...',
                      hintStyle: TextStyle(color: AppTheme.textHint),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textSecondary),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    onSubmitted: (_) => _performSearch(),
                    textInputAction: TextInputAction.search,
                  ),
                ),
                // 搜索按钮
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isLoading ? null : _performSearch,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          gradient: _isLoading ? null : AppTheme.primaryGradient,
                          color: _isLoading ? AppTheme.textHint.withValues(alpha: 0.3) : null,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.search_rounded, color: Colors.white, size: 20),
                                  SizedBox(width: 6),
                                  Text(
                                    '搜索',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // 联合搜索引擎选择
          _buildEngineSelector(),
        ],
      ),
    );
  }

  Widget _buildEngineSelector() {
    final configuredEngines = _settings.searchEngines.where((e) {
      return !e.requiresApiKey ||
             (e.apiKey != null && e.apiKey!.isNotEmpty) ||
             (e.type == SearchEngineType.searxng && e.baseUrl != null && e.baseUrl!.isNotEmpty);
    }).toList();

    if (configuredEngines.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.warningColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.warningColor, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '请在设置中配置搜索引擎',
                style: TextStyle(color: AppTheme.warningColor, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题行
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.hub_rounded, size: 14, color: AppTheme.primaryColor),
            ),
            const SizedBox(width: 8),
            const Text(
              '搜索引擎',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _selectedEngines.isNotEmpty
                    ? AppTheme.successColor.withValues(alpha: 0.15)
                    : AppTheme.textHint.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${_selectedEngines.length}/${configuredEngines.length}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _selectedEngines.isNotEmpty ? AppTheme.successColor : AppTheme.textSecondary,
                ),
              ),
            ),
            const Spacer(),
            // 全选/清空按钮
            if (configuredEngines.length > 1) ...[
              GestureDetector(
                onTap: () {
                  setState(() {
                    if (_selectedEngines.length == configuredEngines.length) {
                      _selectedEngines.clear();
                    } else {
                      _selectedEngines = configuredEngines.map((e) => e.type).toSet();
                    }
                  });
                },
                child: Text(
                  _selectedEngines.length == configuredEngines.length ? '清空' : '全选',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        // 引擎标签 - 使用更现代的样式
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: configuredEngines.map((engine) {
            final isSelected = _selectedEngines.contains(engine.type);
            final color = _getEngineColor(engine.type);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedEngines.remove(engine.type);
                  } else {
                    _selectedEngines.add(engine.type);
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? color : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? color : AppTheme.textHint.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getEngineIcon(engine.type),
                      size: 16,
                      color: isSelected ? Colors.white : color,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      engine.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isSelected ? Colors.white : AppTheme.textPrimary,
                      ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.check_rounded, size: 14, color: Colors.white),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  IconData _getEngineIcon(SearchEngineType type) {
    switch (type) {
      case SearchEngineType.duckduckgo:
        return Icons.pets_rounded;
      case SearchEngineType.tavily:
        return Icons.travel_explore_rounded;
      case SearchEngineType.bocha:
        return Icons.search_rounded;
      case SearchEngineType.bing:
        return Icons.window_rounded;
      case SearchEngineType.google:
        return Icons.g_mobiledata_rounded;
      case SearchEngineType.searxng:
        return Icons.hub_rounded;
    }
  }

  Color _getEngineColor(SearchEngineType type) {
    switch (type) {
      case SearchEngineType.duckduckgo:
        return const Color(0xFFDE5833);
      case SearchEngineType.tavily:
        return const Color(0xFF3B82F6);
      case SearchEngineType.bocha:
        return const Color(0xFF10B981);
      case SearchEngineType.bing:
        return const Color(0xFF00BCF2);
      case SearchEngineType.google:
        return const Color(0xFFEA4335);
      case SearchEngineType.searxng:
        return const Color(0xFF8B5CF6);
    }
  }

  Widget _buildProgressBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.08),
            AppTheme.accentColor.withValues(alpha: 0.05),
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _progressText,
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _searchProgress > 0 ? _searchProgress : null,
                    backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.15),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultView() {
    if (_result == null && !_isLoading) {
      return _buildEmptyState();
    }
    if (_result == null) return const SizedBox();

    return _ResultView(
      result: _result!,
      scrollController: _scrollController,
      onReanalyze: _reanalyze,
      isAnalyzing: _isLoading,
      llmConfigured: _settings.llmConfig.isConfigured,
    );
  }

  Widget _buildEmptyState() {
    final hasLLM = _settings.llmConfig.isConfigured;
    final hasSearch = _selectedEngines.isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 图标
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor.withValues(alpha: 0.1),
                    AppTheme.accentColor.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.analytics_rounded,
                size: 64,
                color: AppTheme.primaryColor.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '开始舆情分析',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '输入关键词，智能搜索并分析网络舆情',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            // 状态标签
            if (hasSearch)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_rounded, size: 16, color: AppTheme.successColor),
                    const SizedBox(width: 6),
                    Text(
                      '已选择 ${_selectedEngines.length} 个搜索引擎',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.successColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 32),
            // LLM 配置提示
            if (!hasLLM)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.infoColor.withValues(alpha: 0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.infoColor.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.infoColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.auto_awesome_rounded, color: AppTheme.infoColor, size: 20),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'AI 智能分析',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                '配置 LLM API 后可启用',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final newSettings = await Navigator.push<AppSettings>(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SettingsScreen(settings: _settings),
                            ),
                          );
                          if (newSettings != null) {
                            setState(() {
                              _settings = newSettings;
                              _updateSelectedEngines();
                            });
                          } else {
                            _loadSettings();
                          }
                        },
                        icon: const Icon(Icons.settings_rounded),
                        label: const Text('前往设置'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.infoColor,
                          side: BorderSide(color: AppTheme.infoColor.withValues(alpha: 0.5)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _updateSelectedEngines() {
    _selectedEngines = _settings.searchEngines
        .where((e) {
          if (!e.requiresApiKey) {
            if (e.type == SearchEngineType.searxng) {
              return e.baseUrl != null && e.baseUrl!.isNotEmpty;
            }
            return true;
          }
          return e.apiKey != null && e.apiKey!.isNotEmpty;
        })
        .map((e) => e.type)
        .toSet();
  }
}

/// 结果显示组件 - 现代化UI
class _ResultView extends StatelessWidget {
  final AnalysisResult result;
  final ScrollController scrollController;
  final VoidCallback onReanalyze;
  final bool isAnalyzing;
  final bool llmConfigured;

  const _ResultView({
    required this.result,
    required this.scrollController,
    required this.onReanalyze,
    required this.isAnalyzing,
    required this.llmConfigured,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 错误信息
          if (result.error != null) _buildErrorCard(),

          // AI分析结果
          if (result.analysis != null) _buildAnalysisCard(),

          // 重新分析按钮
          if (result.analysis == null &&
              result.searchResults.isNotEmpty &&
              llmConfigured)
            _buildReanalyzeButton(),

          // 搜索结果列表
          if (result.searchResults.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildSearchResultsHeader(),
            const SizedBox(height: 12),
            ...result.searchResults.map(_buildSearchResultCard),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.errorColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.errorColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.error_outline_rounded, color: AppTheme.errorColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              result.error!,
              style: const TextStyle(color: AppTheme.errorColor, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头部
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: const Row(
              children: [
                Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 22),
                SizedBox(width: 10),
                Text(
                  'AI 舆情分析',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          // 内容
          Padding(
            padding: const EdgeInsets.all(20),
            child: SelectableText(
              result.analysis!,
              style: const TextStyle(
                fontSize: 15,
                height: 1.8,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReanalyzeButton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Center(
        child: Container(
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isAnalyzing ? null : onReanalyze,
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isAnalyzing)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    else
                      const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      isAnalyzing ? '分析中...' : '使用 AI 分析',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResultsHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.accentColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.article_rounded, size: 18, color: AppTheme.accentColor),
        ),
        const SizedBox(width: 12),
        Text(
          '搜索结果',
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.accentColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${result.searchResults.length}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.accentColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResultCard(SearchResult item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _launchUrl(item.url),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                // 摘要
                Text(
                  item.snippet,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    height: 1.5,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                // 来源
                Row(
                  children: [
                    Icon(Icons.link_rounded, size: 14, color: AppTheme.textHint),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item.source ?? _extractDomain(item.url),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textHint,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.open_in_new_rounded, size: 14, color: AppTheme.textHint),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _extractDomain(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host;
    } catch (_) {
      return url;
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}


