import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/services/storage_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'core/constants/app_constants.dart';
import 'features/shell/presentation/pages/app_shell.dart';
import 'features/tasks/domain/controllers/task_controller.dart';
import 'features/tasks/domain/controllers/view_settings_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化应用常量（获取版本信息）
  await AppConstants.init();
  
  // 初始化存储服务
  await StorageService().init();
  
  // 加载主题设置
  await ThemeController().loadFromStorage();
  
  // 加载任务数据
  await TaskController().loadFromStorage();
  
  // 加载视图设置
  await ViewSettingsController().loadFromStorage();
  
  runApp(const WhatsNowApp());
}

/// Whats Now 应用入口
/// 任务管理应用，支持多平台 - Manage Now
class WhatsNowApp extends StatefulWidget {
  const WhatsNowApp({super.key});

  @override
  State<WhatsNowApp> createState() => _WhatsNowAppState();
}

class _WhatsNowAppState extends State<WhatsNowApp> {
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
      
      // 中文本地化支持
      locale: const Locale('zh', 'CN'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh', 'CN'),
        Locale('en', 'US'),
      ],
      
      // 主题配置 - 使用动态颜色
      theme: AppTheme.lightTheme(_themeController.seedColor),
      darkTheme: AppTheme.darkTheme(_themeController.seedColor),
      themeMode: _themeController.flutterThemeMode,
      
      // 首页
      home: const AppShell(),
    );
  }
}
