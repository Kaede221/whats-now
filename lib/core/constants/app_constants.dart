import 'package:package_info_plus/package_info_plus.dart';

/// 应用常量配置
/// 集中管理应用中使用的常量，便于国际化和统一修改
class AppConstants {
  AppConstants._();

  // 应用信息（动态获取）
  static PackageInfo? _packageInfo;
  
  /// 初始化应用信息（在 main.dart 中调用）
  static Future<void> init() async {
    _packageInfo = await PackageInfo.fromPlatform();
  }
  
  /// 获取应用版本号（从 pubspec.yaml 自动读取）
  static String get appVersion => _packageInfo?.version ?? 'Unknown';
  
  /// 获取应用构建号
  static String get appBuildNumber => _packageInfo?.buildNumber ?? '';
  
  /// 获取完整版本信息
  static String get fullVersion => _packageInfo != null
      ? '${_packageInfo!.version}+${_packageInfo!.buildNumber}'
      : 'Unknown';

  // 应用信息（静态配置）
  static const String appName = 'Whats Now';
  static const String appSlogan = 'Manage Now';
  static const String appAuthor = 'KaedeShimizu';
  static const String appGithubUrl = 'https://github.com/Kaede221/whats-now.git';

  // 导航项标签
  static const String navTasks = '任务';
  static const String navSettings = '设置';

  // 页面标题
  static const String titleTasks = '我的任务';
  static const String titleSettings = '设置';

  // 通用文本
  static const String noTasks = '暂无任务';
  static const String addTask = '添加任务';
}