import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../config/app_config.dart';
import '../models/engine_status.dart';

/// 引擎标签组件
class EngineTabsWidget extends StatelessWidget {
  final String currentEngine;
  final Map<String, EngineStatus> engineStatus;
  final Function(String) onEngineSelected;
  final bool reportLocked;
  
  const EngineTabsWidget({
    super.key,
    required this.currentEngine,
    required this.engineStatus,
    required this.onEngineSelected,
    this.reportLocked = true,
  });
  
  @override
  Widget build(BuildContext context) {
    final engines = ['insight', 'media', 'query', 'forum', 'report'];
    
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.borderColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: engines.map((engine) {
          final status = engineStatus[engine];
          final isActive = currentEngine == engine;
          final isLocked = engine == 'report' && reportLocked;
          
          return Expanded(
            child: _EngineTab(
              name: AppConfig.engineNames[engine] ?? engine,
              status: status?.status ?? EngineStatusType.stopped,
              isActive: isActive,
              isLocked: isLocked,
              onTap: isLocked ? null : () => onEngineSelected(engine),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _EngineTab extends StatelessWidget {
  final String name;
  final EngineStatusType status;
  final bool isActive;
  final bool isLocked;
  final VoidCallback? onTap;
  
  const _EngineTab({
    required this.name,
    required this.status,
    required this.isActive,
    required this.isLocked,
    this.onTap,
  });
  
  Color get _statusColor {
    switch (status) {
      case EngineStatusType.running:
        return AppTheme.runningColor;
      case EngineStatusType.starting:
        return AppTheme.startingColor;
      case EngineStatusType.error:
        return AppTheme.errorColor;
      case EngineStatusType.stopped:
        return AppTheme.stoppedColor;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isActive ? Colors.grey.shade100 : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: isActive ? AppTheme.primaryColor : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 状态指示器
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: _statusColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            
            // 引擎名称
            Flexible(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isLocked 
                      ? AppTheme.secondaryTextColor 
                      : AppTheme.textColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            // 锁定图标
            if (isLocked) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.lock_outline,
                size: 12,
                color: AppTheme.secondaryTextColor,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

