import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../config/app_theme.dart';
import '../models/report.dart';

/// 报告视图组件
class ReportViewWidget extends StatefulWidget {
  final ReportTask? task;
  final String? reportContent;
  final bool isLocked;
  final bool isGenerating;
  final VoidCallback? onGenerate;
  final String? errorMessage;

  const ReportViewWidget({
    super.key,
    this.task,
    this.reportContent,
    this.isLocked = true,
    this.isGenerating = false,
    this.onGenerate,
    this.errorMessage,
  });

  @override
  State<ReportViewWidget> createState() => _ReportViewWidgetState();
}

class _ReportViewWidgetState extends State<ReportViewWidget> {
  WebViewController? _webViewController;

  @override
  void didUpdateWidget(ReportViewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 当报告内容更新时，重新加载WebView
    if (widget.reportContent != oldWidget.reportContent &&
        widget.reportContent != null &&
        widget.reportContent!.isNotEmpty) {
      _loadHtmlContent(widget.reportContent!);
    }
  }

  void _loadHtmlContent(String htmlContent) {
    if (_webViewController != null) {
      _webViewController!.loadHtmlString(htmlContent);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        border: Border.all(
          color: AppTheme.borderColor,
          width: AppTheme.borderWidth,
        ),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      child: Column(
        children: [
          // 标题栏
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: Border(
                bottom: BorderSide(
                  color: AppTheme.borderColor,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.description_outlined, size: 18),
                const SizedBox(width: 8),
                const Text(
                  'Report Engine - 舆情分析报告',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                if (!widget.isLocked && !widget.isGenerating)
                  ElevatedButton.icon(
                    onPressed: widget.onGenerate,
                    icon: const Icon(Icons.auto_awesome, size: 16),
                    label: const Text('生成报告'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // 内容区域
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    // 锁定状态
    if (widget.isLocked) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline,
              size: 48,
              color: AppTheme.secondaryTextColor,
            ),
            SizedBox(height: 16),
            Text(
              '需等待其余三个Agent工作完毕',
              style: TextStyle(
                color: AppTheme.secondaryTextColor,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    // 生成中
    if (widget.isGenerating && widget.task != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              '正在生成报告... ${(widget.task!.progress * 100).toStringAsFixed(0)}%',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                value: widget.task!.progress,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              ),
            ),
            if (widget.task!.message != null) ...[
              const SizedBox(height: 8),
              Text(
                widget.task!.message!,
                style: TextStyle(
                  color: AppTheme.secondaryTextColor,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      );
    }

    // 错误状态
    if (widget.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: AppTheme.errorColor,
            ),
            const SizedBox(height: 16),
            Text(
              widget.errorMessage!,
              style: const TextStyle(
                color: AppTheme.errorColor,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // 显示报告内容（使用WebView渲染HTML）
    if (widget.reportContent != null && widget.reportContent!.isNotEmpty) {
      return WebViewWidget(
        controller: WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setBackgroundColor(Colors.white)
          ..loadHtmlString(widget.reportContent!),
      );
    }

    // 空状态
    return const Center(
      child: Text(
        '点击"生成报告"开始生成舆情分析报告',
        style: TextStyle(
          color: AppTheme.secondaryTextColor,
          fontSize: 14,
        ),
      ),
    );
  }
}
