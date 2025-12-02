import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';

/// 颜色选择对话框
/// 用于选择主题颜色
class ColorPickerDialog extends StatelessWidget {
  final Color selectedColor;
  final ValueChanged<Color> onColorSelected;

  const ColorPickerDialog({
    super.key,
    required this.selectedColor,
    required this.onColorSelected,
  });

  /// 显示颜色选择对话框
  static Future<void> show(
    BuildContext context, {
    required Color selectedColor,
    required ValueChanged<Color> onColorSelected,
  }) {
    return showDialog(
      context: context,
      builder: (context) => ColorPickerDialog(
        selectedColor: selectedColor,
        onColorSelected: onColorSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // 使用 AppConstants 中的颜色列表，确保与分组颜色一致
    // 另外加上默认的紫色（如果不在列表中）
    final List<Color> colors = [
      const Color(0xFF6750A4), // 默认紫色
      ...AppConstants.groupColors,
    ];
    
    // 去重
    final uniqueColors = colors.map((c) => c.value).toSet().map((v) => Color(v)).toList();

    return AlertDialog(
      title: const Text('选择主题颜色'),
      contentPadding: const EdgeInsets.all(16),
      content: SizedBox(
        width: double.maxFinite,
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: uniqueColors.map((color) {
            final isSelected = selectedColor.value == color.value;
            return _ColorButton(
              color: color,
              isSelected: isSelected,
              onTap: () {
                onColorSelected(color);
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
    );
  }
}

/// 颜色选择按钮
class _ColorButton extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorButton({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(color: theme.colorScheme.onSurface, width: 3)
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
            ? Icon(Icons.check, color: _getContrastColor(color), size: 24)
            : null,
      ),
    );
  }

  /// 获取对比色（用于勾选图标）
  Color _getContrastColor(Color color) {
    final luminance = color.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}