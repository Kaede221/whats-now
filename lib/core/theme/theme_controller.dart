import 'package:flutter/material.dart';
import '../services/storage_service.dart';

/// 主题模式枚举
enum AppThemeMode {
  system('跟随系统', Icons.brightness_auto),
  light('浅色模式', Icons.light_mode),
  dark('深色模式', Icons.dark_mode);

  final String label;
  final IconData icon;

  const AppThemeMode(this.label, this.icon);

  /// 转换为 Flutter 的 ThemeMode
  ThemeMode toThemeMode() {
    switch (this) {
      case AppThemeMode.system:
        return ThemeMode.system;
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
    }
  }

  /// 从索引创建
  static AppThemeMode fromIndex(int index) {
    if (index >= 0 && index < AppThemeMode.values.length) {
      return AppThemeMode.values[index];
    }
    return AppThemeMode.system;
  }
}

/// 预设主题颜色
class ThemeColorOption {
  final String name;
  final Color color;

  const ThemeColorOption(this.name, this.color);
}

/// 预设颜色列表
class ThemeColors {
  ThemeColors._();

  static const List<ThemeColorOption> presetColors = [
    ThemeColorOption('紫罗兰', Color(0xFF6750A4)),
    ThemeColorOption('靛蓝', Color(0xFF3F51B5)),
    ThemeColorOption('蓝色', Color(0xFF2196F3)),
    ThemeColorOption('青色', Color(0xFF00BCD4)),
    ThemeColorOption('青绿', Color(0xFF009688)),
    ThemeColorOption('绿色', Color(0xFF4CAF50)),
    ThemeColorOption('黄绿', Color(0xFF8BC34A)),
    ThemeColorOption('橙色', Color(0xFFFF9800)),
    ThemeColorOption('深橙', Color(0xFFFF5722)),
    ThemeColorOption('红色', Color(0xFFF44336)),
    ThemeColorOption('粉色', Color(0xFFE91E63)),
    ThemeColorOption('紫色', Color(0xFF9C27B0)),
  ];

  /// 默认颜色
  static const Color defaultColor = Color(0xFF6750A4);
}

/// 主题控制器
/// 使用单例模式管理全局主题状态
class ThemeController extends ChangeNotifier {
  static final ThemeController _instance = ThemeController._internal();
  
  factory ThemeController() => _instance;
  
  ThemeController._internal();

  final StorageService _storage = StorageService();

  AppThemeMode _themeMode = AppThemeMode.system;
  Color _seedColor = ThemeColors.defaultColor;
  bool _isInitialized = false;

  /// 是否已初始化
  bool get isInitialized => _isInitialized;

  /// 获取当前主题模式
  AppThemeMode get themeMode => _themeMode;

  /// 获取 Flutter ThemeMode
  ThemeMode get flutterThemeMode => _themeMode.toThemeMode();

  /// 获取当前种子颜色
  Color get seedColor => _seedColor;

  /// 从存储加载主题设置
  Future<void> loadFromStorage() async {
    // 加载主题模式
    final savedThemeMode = _storage.getThemeMode();
    if (savedThemeMode != null) {
      _themeMode = AppThemeMode.fromIndex(savedThemeMode);
    }

    // 加载种子颜色
    final savedColor = _storage.getSeedColor();
    if (savedColor != null) {
      _seedColor = Color(savedColor);
    }

    _isInitialized = true;
    notifyListeners();
  }

  /// 设置主题模式
  void setThemeMode(AppThemeMode mode) {
    if (_themeMode != mode) {
      _themeMode = mode;
      _storage.saveThemeMode(mode.index);
      notifyListeners();
    }
  }

  /// 设置种子颜色
  void setSeedColor(Color color) {
    if (_seedColor != color) {
      _seedColor = color;
      _storage.saveSeedColor(color.value);
      notifyListeners();
    }
  }

  /// 获取当前颜色的名称
  String get currentColorName {
    for (final option in ThemeColors.presetColors) {
      if (option.color.value == _seedColor.value) {
        return option.name;
      }
    }
    return '自定义';
  }
}