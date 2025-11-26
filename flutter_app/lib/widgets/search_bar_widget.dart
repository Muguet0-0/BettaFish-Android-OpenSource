import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../config/app_theme.dart';

/// 搜索栏组件
class SearchBarWidget extends StatefulWidget {
  final Function(String query) onSearch;
  final Function(String? template) onTemplateSelected;
  final VoidCallback onConfigPressed;
  final bool isEnabled;
  final String? currentTemplate;
  
  const SearchBarWidget({
    super.key,
    required this.onSearch,
    required this.onTemplateSelected,
    required this.onConfigPressed,
    this.isEnabled = true,
    this.currentTemplate,
  });
  
  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final TextEditingController _controller = TextEditingController();
  String? _templateFileName;
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  Future<void> _pickTemplate() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['md', 'txt'],
      );
      
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        setState(() {
          _templateFileName = file.name;
        });
        
        // 读取文件内容
        if (file.bytes != null) {
          final content = String.fromCharCodes(file.bytes!);
          widget.onTemplateSelected(content);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('选择模板失败: $e')),
      );
    }
  }
  
  void _clearTemplate() {
    setState(() {
      _templateFileName = null;
    });
    widget.onTemplateSelected(null);
  }
  
  void _handleSearch() {
    final query = _controller.text.trim();
    if (query.isNotEmpty) {
      widget.onSearch(query);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.borderColor,
            width: AppTheme.borderWidth,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          const Text(
            '微舆 - 致力于打造简洁通用的舆情分析平台',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor,
            ),
          ),
          const SizedBox(height: 12),
          
          // 搜索行
          Row(
            children: [
              // 配置按钮
              OutlinedButton(
                onPressed: widget.onConfigPressed,
                child: const Text('LLM 配置'),
              ),
              const SizedBox(width: 12),
              
              // 搜索框
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppTheme.borderColor,
                      width: AppTheme.borderWidth,
                    ),
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          enabled: widget.isEnabled,
                          decoration: const InputDecoration(
                            hintText: '请输入要分析的内容...',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16),
                          ),
                          onSubmitted: (_) => _handleSearch(),
                        ),
                      ),
                      // 开始按钮
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(AppTheme.borderRadius - 2),
                            bottomRight: Radius.circular(AppTheme.borderRadius - 2),
                          ),
                        ),
                        child: TextButton(
                          onPressed: widget.isEnabled ? _handleSearch : null,
                          child: const Text(
                            '开始',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              // 上传模板按钮
              OutlinedButton.icon(
                onPressed: widget.isEnabled ? _pickTemplate : null,
                icon: const Icon(Icons.upload_file, size: 18),
                label: Text(_templateFileName ?? '上传模板'),
              ),
              
              // 清除模板按钮
              if (_templateFileName != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _clearTemplate,
                  icon: const Icon(Icons.close, size: 18),
                  tooltip: '清除模板',
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

