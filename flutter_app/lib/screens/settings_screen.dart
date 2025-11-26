import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/settings_model.dart';
import '../services/llm_service.dart';

/// 设置页面 - 现代化UI
class SettingsScreen extends StatefulWidget {
  final AppSettings settings;

  const SettingsScreen({super.key, required this.settings});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  late AppSettings _settings;
  bool _isTesting = false;
  String? _testResult;
  late TabController _tabController;

  // LLM配置控制器
  late TextEditingController _llmApiKeyController;
  late TextEditingController _llmBaseUrlController;
  late TextEditingController _llmModelController;

  @override
  void initState() {
    super.initState();
    _settings = widget.settings;
    _tabController = TabController(length: 3, vsync: this);
    _llmApiKeyController = TextEditingController(text: _settings.llmConfig.apiKey);
    _llmBaseUrlController = TextEditingController(text: _settings.llmConfig.baseUrl);
    _llmModelController = TextEditingController(text: _settings.llmConfig.modelName);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _llmApiKeyController.dispose();
    _llmBaseUrlController.dispose();
    _llmModelController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    _settings = _settings.copyWith(
      llmConfig: _settings.llmConfig.copyWith(
        apiKey: _llmApiKeyController.text.trim(),
        baseUrl: _llmBaseUrlController.text.trim(),
        modelName: _llmModelController.text.trim(),
      ),
    );

    await SettingsStorage.save(_settings);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('设置已保存'),
            ],
          ),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      Navigator.pop(context, _settings);
    }
  }

  Future<void> _testLLMConnection() async {
    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    final config = LLMConfig(
      apiKey: _llmApiKeyController.text.trim(),
      baseUrl: _llmBaseUrlController.text.trim(),
      modelName: _llmModelController.text.trim(),
    );

    final service = LLMService(config: config);
    final response = await service.testConnection();

    if (mounted) {
      setState(() {
        _isTesting = false;
        _testResult = response.success ? '✓ 连接成功' : '✗ ${response.error}';
      });
    }
  }

  void _updateSearchEngine(int index, SearchEngineConfig config) {
    final engines = List<SearchEngineConfig>.from(_settings.searchEngines);
    engines[index] = config;
    setState(() {
      _settings = _settings.copyWith(searchEngines: engines);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('设置'),
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: _saveSettings,
              icon: const Icon(Icons.save_rounded, size: 20),
              label: const Text('保存'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primaryColor,
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(Icons.psychology_rounded), text: 'AI模型'),
            Tab(icon: Icon(Icons.search_rounded), text: '搜索引擎'),
            Tab(icon: Icon(Icons.tune_rounded), text: '其他'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLLMTab(),
          _buildSearchEnginesTab(),
          _buildOtherSettingsTab(),
        ],
      ),
    );
  }

  Widget _buildLLMTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头部说明
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryColor.withValues(alpha: 0.1), AppTheme.accentColor.withValues(alpha: 0.05)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.auto_awesome, color: AppTheme.primaryColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AI 智能分析',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '配置 OpenAI 兼容的 API 接口',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // 配置表单
          _buildModernCard(
            children: [
              _buildModernTextField(
                controller: _llmBaseUrlController,
                label: 'API 地址',
                hint: 'https://api.openai.com/v1',
                icon: Icons.link_rounded,
                helperText: '支持 OpenAI、DeepSeek、Ollama 等兼容接口',
              ),
              const SizedBox(height: 20),
              _buildModernTextField(
                controller: _llmApiKeyController,
                label: 'API 密钥',
                hint: 'sk-...',
                icon: Icons.key_rounded,
                isPassword: true,
              ),
              const SizedBox(height: 20),
              _buildModernTextField(
                controller: _llmModelController,
                label: '模型名称',
                hint: 'gpt-4o-mini',
                icon: Icons.smart_toy_rounded,
                helperText: '如 gpt-4o、deepseek-chat、qwen-plus 等',
              ),
              const SizedBox(height: 24),
              // 测试按钮
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isTesting ? null : _testLLMConnection,
                  icon: _isTesting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.wifi_tethering_rounded),
                  label: Text(_isTesting ? '测试中...' : '测试连接'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              if (_testResult != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _testResult!.startsWith('✓')
                        ? AppTheme.successColor.withValues(alpha: 0.1)
                        : AppTheme.errorColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _testResult!.startsWith('✓') ? Icons.check_circle : Icons.error,
                        color: _testResult!.startsWith('✓') ? AppTheme.successColor : AppTheme.errorColor,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _testResult!,
                          style: TextStyle(
                            color: _testResult!.startsWith('✓') ? AppTheme.successColor : AppTheme.errorColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchEnginesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 说明
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.infoColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.infoColor.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, color: AppTheme.infoColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'DuckDuckGo 免费可用，其他引擎需要配置 API',
                    style: TextStyle(color: AppTheme.infoColor, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // 搜索引擎列表
          ...List.generate(_settings.searchEngines.length, (index) {
            final engine = _settings.searchEngines[index];
            return _buildModernSearchEngineCard(index, engine);
          }),
        ],
      ),
    );
  }

  Widget _buildModernSearchEngineCard(int index, SearchEngineConfig engine) {
    final color = _getEngineColor(engine.type);
    final isConfigured = !engine.requiresApiKey ||
        (engine.apiKey != null && engine.apiKey!.isNotEmpty) ||
        (engine.type == SearchEngineType.searxng && engine.baseUrl != null && engine.baseUrl!.isNotEmpty);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: engine.enabled ? color.withValues(alpha: 0.3) : Colors.grey.shade200,
          width: engine.enabled ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: engine.enabled ? color.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // 头部
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_getEngineIcon(engine.type), color: color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        engine.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (!engine.requiresApiKey)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.successColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                '免费',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.successColor,
                                ),
                              ),
                            )
                          else if (isConfigured)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.infoColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                '已配置',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.infoColor,
                                ),
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.textHint.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                '需要API',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Transform.scale(
                  scale: 0.9,
                  child: Switch.adaptive(
                    value: engine.enabled,
                    activeColor: color,
                    onChanged: (value) {
                      _updateSearchEngine(index, engine.copyWith(enabled: value));
                    },
                  ),
                ),
              ],
            ),
          ),
          // API Key 输入
          if (engine.enabled && engine.requiresApiKey)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: TextField(
                decoration: InputDecoration(
                  labelText: 'API 密钥',
                  hintText: _getApiKeyHint(engine.type),
                  prefixIcon: Icon(Icons.vpn_key_rounded, size: 20, color: color),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: color, width: 2),
                  ),
                ),
                obscureText: true,
                controller: TextEditingController(text: engine.apiKey ?? ''),
                onChanged: (value) {
                  _updateSearchEngine(index, engine.copyWith(apiKey: value));
                },
              ),
            ),
          // SearXNG 服务器地址
          if (engine.enabled && engine.type == SearchEngineType.searxng)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: TextField(
                decoration: InputDecoration(
                  labelText: '服务器地址',
                  hintText: 'https://your-searxng-instance.com',
                  prefixIcon: Icon(Icons.dns_rounded, size: 20, color: color),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: color, width: 2),
                  ),
                ),
                controller: TextEditingController(text: engine.baseUrl ?? ''),
                onChanged: (value) {
                  _updateSearchEngine(index, engine.copyWith(baseUrl: value));
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOtherSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildModernCard(
            children: [
              // 自动AI分析
              _buildSettingTile(
                icon: Icons.auto_awesome_rounded,
                title: '自动 AI 分析',
                subtitle: '搜索完成后自动使用 LLM 分析结果',
                trailing: Switch.adaptive(
                  value: _settings.autoAnalyze,
                  activeColor: AppTheme.primaryColor,
                  onChanged: (value) {
                    setState(() {
                      _settings = _settings.copyWith(autoAnalyze: value);
                    });
                  },
                ),
              ),
              const Divider(height: 32),
              // 最大搜索结果数
              _buildSettingTile(
                icon: Icons.format_list_numbered_rounded,
                title: '搜索结果数量',
                subtitle: '每个搜索引擎返回的最大结果数',
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _settings.maxSearchResults,
                      isDense: true,
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                      icon: const Icon(Icons.arrow_drop_down, color: AppTheme.primaryColor),
                      items: [10, 20, 30, 50, 80, 100, 150, 200].map((n) {
                        return DropdownMenuItem(
                          value: n,
                          child: Text('$n 条'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _settings = _settings.copyWith(maxSearchResults: value);
                          });
                        }
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // 提示信息
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lightbulb_outline, color: AppTheme.warningColor, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '结果数量越多，搜索时间越长，分析越全面。\n建议：快速查询选 10-30，深度分析选 50-100。',
                        style: TextStyle(
                          color: const Color(0xFFB45309), // warningColor darker
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // 关于
          _buildModernCard(
            children: [
              _buildSettingTile(
                icon: Icons.info_outline_rounded,
                title: '关于微舆',
                subtitle: 'BettaFish v1.2.0 本地版',
                trailing: Icon(Icons.chevron_right, color: AppTheme.textHint),
                onTap: () => _showAboutDialog(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppTheme.primaryColor, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.water_drop_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('微舆'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('BettaFish - 本地舆情分析工具'),
            SizedBox(height: 8),
            Text('版本: 1.2.0', style: TextStyle(color: AppTheme.textSecondary)),
            SizedBox(height: 16),
            Text(
              '利用多搜索引擎爬取网络信息，结合大语言模型进行智能舆情分析。',
              style: TextStyle(fontSize: 13, height: 1.5),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Widget _buildModernCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    String? helperText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword,
          style: const TextStyle(fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppTheme.primaryColor),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
        if (helperText != null) ...[
          const SizedBox(height: 6),
          Text(
            helperText,
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
        ],
      ],
    );
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

  String _getApiKeyHint(SearchEngineType type) {
    switch (type) {
      case SearchEngineType.tavily:
        return 'tvly-...';
      case SearchEngineType.google:
        return 'API密钥:搜索引擎ID';
      case SearchEngineType.bing:
        return 'Ocp-Apim-Subscription-Key';
      default:
        return '输入API密钥';
    }
  }
}

