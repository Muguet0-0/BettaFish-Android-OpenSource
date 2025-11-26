import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../providers/config_provider.dart';
import '../providers/app_state_provider.dart';
import '../models/config_model.dart';

/// LLM配置屏幕
class ConfigScreen extends StatefulWidget {
  const ConfigScreen({super.key});
  
  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, bool> _obscurePasswords = {};
  
  @override
  void initState() {
    super.initState();
    // 加载配置
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ConfigProvider>().loadConfig();
    });
  }
  
  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
  
  TextEditingController _getController(String key, String initialValue) {
    if (!_controllers.containsKey(key)) {
      _controllers[key] = TextEditingController(text: initialValue);
    }
    return _controllers[key]!;
  }
  
  Future<void> _saveConfig() async {
    final configProvider = context.read<ConfigProvider>();
    
    // 更新所有编辑值
    for (final entry in _controllers.entries) {
      configProvider.updateEditingValue(entry.key, entry.value.text);
    }
    
    final success = await configProvider.saveConfig();
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('配置保存成功')),
      );
    }
  }
  
  Future<void> _saveAndStart() async {
    await _saveConfig();
    if (mounted) {
      final appState = context.read<AppStateProvider>();
      final success = await appState.startSystem();
      if (success && mounted) {
        Navigator.of(context).pop();
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LLM 配置'),
        actions: [
          IconButton(
            onPressed: () => context.read<ConfigProvider>().loadConfig(),
            icon: const Icon(Icons.refresh),
            tooltip: '刷新',
          ),
        ],
      ),
      body: Consumer<ConfigProvider>(
        builder: (context, configProvider, _) {
          if (configProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (configProvider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: AppTheme.errorColor),
                  const SizedBox(height: 16),
                  Text(configProvider.errorMessage!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => configProvider.loadConfig(),
                    child: const Text('重试'),
                  ),
                ],
              ),
            );
          }
          
          final groups = configProvider.getConfigGroups();
          
          return Column(
            children: [
              // 配置表单
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: groups.length,
                  itemBuilder: (context, index) {
                    return _buildConfigGroup(groups[index], configProvider);
                  },
                ),
              ),
              
              // 底部按钮
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  border: Border(
                    top: BorderSide(color: AppTheme.borderColor),
                  ),
                ),
                child: Row(
                  children: [
                    if (configProvider.successMessage != null)
                      Expanded(
                        child: Text(
                          configProvider.successMessage!,
                          style: TextStyle(color: AppTheme.runningColor),
                        ),
                      )
                    else
                      const Spacer(),
                    OutlinedButton(
                      onPressed: configProvider.isSaving ? null : _saveConfig,
                      child: configProvider.isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('保存'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: configProvider.isSaving ? null : _saveAndStart,
                      child: const Text('保存并启动系统'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildConfigGroup(ConfigGroup group, ConfigProvider provider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: Text(
          group.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        initiallyExpanded: true,
        children: group.items.map((item) {
          return _buildConfigItem(item, provider);
        }).toList(),
      ),
    );
  }
  
  Widget _buildConfigItem(ConfigItem item, ConfigProvider provider) {
    final controller = _getController(item.key, provider.getValue(item.key));
    final isPassword = item.isPassword;
    final obscure = _obscurePasswords[item.key] ?? true;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: controller,
        obscureText: isPassword && obscure,
        decoration: InputDecoration(
          labelText: item.label,
          hintText: item.key,
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
                  onPressed: () {
                    setState(() {
                      _obscurePasswords[item.key] = !obscure;
                    });
                  },
                )
              : null,
        ),
        keyboardType: item.isNumber ? TextInputType.number : TextInputType.text,
        onChanged: (value) {
          provider.updateEditingValue(item.key, value);
        },
      ),
    );
  }
}

