import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'core/constants/app_constants.dart';
import 'features/shell/presentation/pages/app_shell.dart';

void main() {
  runApp(const KaedeTasksApp());
}

/// Kaede Tasks 应用入口
/// 任务管理应用，支持多平台
class KaedeTasksApp extends StatefulWidget {
  const KaedeTasksApp({super.key});

  @override
  State<KaedeTasksApp> createState() => _KaedeTasksAppState();
}

class _KaedeTasksAppState extends State<KaedeTasksApp> {
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
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      
      // 主题配置 - 使用动态颜色
      theme: AppTheme.lightTheme(_themeController.seedColor),
      darkTheme: AppTheme.darkTheme(_themeController.seedColor),
      themeMode: _themeController.flutterThemeMode,
      
      // 首页
      home: const AppShell(),
    );
  }
}
