import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 存储服务
/// 提供数据持久化功能，使用 SharedPreferences 存储数据
class StorageService {
  static final StorageService _instance = StorageService._internal();
  
  factory StorageService() => _instance;
  
  StorageService._internal();

  SharedPreferences? _prefs;

  /// 存储键名常量
  static const String keyThemeMode = 'theme_mode';
  static const String keySeedColor = 'seed_color';
  static const String keyTasks = 'tasks';
  static const String keyGroups = 'groups';

  /// 初始化存储服务
  /// 必须在应用启动时调用
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// 确保已初始化
  void _ensureInitialized() {
    if (_prefs == null) {
      throw StateError('StorageService 未初始化，请先调用 init() 方法');
    }
  }

  // ===== 主题相关存储 =====

  /// 保存主题模式
  Future<bool> saveThemeMode(int modeIndex) async {
    _ensureInitialized();
    return await _prefs!.setInt(keyThemeMode, modeIndex);
  }

  /// 获取主题模式
  int? getThemeMode() {
    _ensureInitialized();
    return _prefs!.getInt(keyThemeMode);
  }

  /// 保存种子颜色
  Future<bool> saveSeedColor(int colorValue) async {
    _ensureInitialized();
    return await _prefs!.setInt(keySeedColor, colorValue);
  }

  /// 获取种子颜色
  int? getSeedColor() {
    _ensureInitialized();
    return _prefs!.getInt(keySeedColor);
  }

  // ===== 任务相关存储 =====

  /// 保存任务列表
  Future<bool> saveTasks(List<Map<String, dynamic>> tasks) async {
    _ensureInitialized();
    final jsonString = jsonEncode(tasks);
    return await _prefs!.setString(keyTasks, jsonString);
  }

  /// 获取任务列表
  List<Map<String, dynamic>>? getTasks() {
    _ensureInitialized();
    final jsonString = _prefs!.getString(keyTasks);
    if (jsonString == null) return null;
    
    try {
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      return null;
    }
  }

  /// 保存分组列表
  Future<bool> saveGroups(List<Map<String, dynamic>> groups) async {
    _ensureInitialized();
    final jsonString = jsonEncode(groups);
    return await _prefs!.setString(keyGroups, jsonString);
  }

  /// 获取分组列表
  List<Map<String, dynamic>>? getGroups() {
    _ensureInitialized();
    final jsonString = _prefs!.getString(keyGroups);
    if (jsonString == null) return null;
    
    try {
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      return null;
    }
  }

  // ===== 通用方法 =====

  /// 清除所有数据
  Future<bool> clearAll() async {
    _ensureInitialized();
    return await _prefs!.clear();
  }

  /// 删除指定键的数据
  Future<bool> remove(String key) async {
    _ensureInitialized();
    return await _prefs!.remove(key);
  }
}