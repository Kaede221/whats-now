import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/theme_controller.dart';

/// 设置页面
/// 提供应用设置选项，如主题切换、通知设置等
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final ThemeController _themeController = ThemeController();

  @override
  void initState() {
    super.initState();
    _themeController.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    _themeController.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.titleSettings),
      ),
      body: ListView(
        children: [
          // 外观设置分组
          _buildSectionHeader(context, '外观'),
          _buildSettingsTile(
            context,
            icon: Icons.dark_mode_outlined,
            title: '深色模式',
            subtitle: _themeController.themeMode.label,
            onTap: () => _showThemeModeDialog(context),
          ),
          _buildColorSettingsTile(
            context,
            icon: Icons.palette_outlined,
            title: '主题颜色',
            subtitle: _themeController.currentColorName,
            color: _themeController.seedColor,
            onTap: () => _showColorPickerDialog(context),
          ),
          
          const Divider(),
          
          // 关于分组
          _buildSectionHeader(context, '关于'),
          _buildSettingsTile(
            context,
            icon: Icons.info_outline,
            title: '版本',
            subtitle: AppConstants.appVersion,
            onTap: null,
          ),
        ],
      ),
    );
  }

  /// 显示主题模式选择对话框
  void _showThemeModeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择主题'),
        contentPadding: const EdgeInsets.only(top: 16, bottom: 8),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppThemeMode.values.map((mode) {
            final isSelected = _themeController.themeMode == mode;
            return RadioListTile<AppThemeMode>(
              value: mode,
              groupValue: _themeController.themeMode,
              onChanged: (value) {
                if (value != null) {
                  _themeController.setThemeMode(value);
                  Navigator.of(context).pop();
                }
              },
              title: Text(mode.label),
              secondary: Icon(mode.icon),
              selected: isSelected,
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  /// 显示颜色选择对话框
  void _showColorPickerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择主题颜色'),
        contentPadding: const EdgeInsets.all(16),
        content: SizedBox(
          width: double.maxFinite,
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: ThemeColors.presetColors.map((option) {
              final isSelected = _themeController.seedColor.value == option.color.value;
              return _ColorButton(
                color: option.color,
                name: option.name,
                isSelected: isSelected,
                onTap: () {
                  _themeController.setSeedColor(option.color);
                  Navigator.of(context).pop();
                },
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  /// 构建设置分组标题
  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// 构建设置项
  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.onSurfaceVariant),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: onTap != null
          ? Icon(Icons.chevron_right, color: theme.colorScheme.outline)
          : null,
      onTap: onTap,
    );
  }

  /// 构建带颜色预览的设置项
  Widget _buildColorSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required Color color,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.onSurfaceVariant),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.5),
                width: 1,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right, color: theme.colorScheme.outline),
        ],
      ),
      onTap: onTap,
    );
  }
}

/// 颜色选择按钮
class _ColorButton extends StatelessWidget {
  final Color color;
  final String name;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorButton({
    required this.color,
    required this.name,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: name,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: isSelected
                ? Border.all(
                    color: theme.colorScheme.onSurface,
                    width: 3,
                  )
                : null,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: isSelected
              ? Icon(
                  Icons.check,
                  color: _getContrastColor(color),
                  size: 24,
                )
              : null,
        ),
      ),
    );
  }

  /// 获取对比色（用于勾选图标）
  Color _getContrastColor(Color color) {
    final luminance = color.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}