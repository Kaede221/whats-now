import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_constants.dart';

/// 关于页面
/// 显示应用版本、作者和GitHub链接信息
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  /// 复制文本到剪贴板并显示提示
  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label 已复制到剪贴板'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('关于'),
      ),
      body: ListView(
        children: [
          // 应用图标和名称
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    'assets/icons/app_icon.png',
                    width: 80,
                    height: 80,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  AppConstants.appName,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppConstants.appSlogan,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),

          const Divider(),

          // 版本信息
          _buildInfoTile(
            context,
            icon: Icons.info_outline,
            title: '版本',
            value: AppConstants.appVersion,
            onTap: () => _copyToClipboard(
              context,
              AppConstants.appVersion,
              '版本号',
            ),
          ),

          // 作者信息
          _buildInfoTile(
            context,
            icon: Icons.person_outline,
            title: '作者',
            value: AppConstants.appAuthor,
            onTap: () => _copyToClipboard(
              context,
              AppConstants.appAuthor,
              '作者名',
            ),
          ),

          // GitHub链接
          _buildInfoTile(
            context,
            icon: Icons.code,
            title: 'GitHub',
            value: AppConstants.appGithubUrl,
            onTap: () => _copyToClipboard(
              context,
              AppConstants.appGithubUrl,
              'GitHub链接',
            ),
          ),

          const SizedBox(height: 32),

          // 提示文字
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '点击任意条目可复制内容',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建信息条目
  Widget _buildInfoTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.onSurfaceVariant),
      title: Text(title),
      subtitle: Text(
        value,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
      trailing: Icon(
        Icons.copy,
        size: 20,
        color: theme.colorScheme.outline,
      ),
      onTap: onTap,
    );
  }
}