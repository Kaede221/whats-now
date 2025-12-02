import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/controllers/task_controller.dart';
import '../../domain/models/models.dart';

/// 创建分组对话框
class CreateGroupDialog extends StatefulWidget {
  const CreateGroupDialog({super.key});

  /// 显示创建分组对话框
  /// 返回创建的分组，如果取消则返回 null
  static Future<TaskGroup?> show(BuildContext context) {
    return showDialog<TaskGroup>(
      context: context,
      builder: (context) => const CreateGroupDialog(),
    );
  }

  @override
  State<CreateGroupDialog> createState() => _CreateGroupDialogState();
}

class _CreateGroupDialogState extends State<CreateGroupDialog> {
  final TaskController _taskController = TaskController();
  final TextEditingController _nameController = TextEditingController();
  Color? _selectedColor;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 如果未选择颜色，默认使用主题主色
    _selectedColor ??= theme.colorScheme.primary;

    // 预设颜色列表
    final presetColors = [
      theme.colorScheme.primary,
      ...AppConstants.groupColors,
    ];

    return AlertDialog(
      title: const Text('新建分组'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: '分组名称',
              hintText: '输入分组名称',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),

          const SizedBox(height: 16),

          Text(
            '选择颜色',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: presetColors.map((color) {
              final isSelected = _selectedColor!.value == color.value;
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedColor = color);
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(
                            color: theme.colorScheme.onSurface,
                            width: 3,
                          )
                        : null,
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check,
                          color: _getContrastColor(color),
                          size: 20,
                        )
                      : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        TextButton(onPressed: _createGroup, child: const Text('创建')),
      ],
    );
  }

  void _createGroup() {
    final name = _nameController.text.trim();
    if (name.isNotEmpty && _selectedColor != null) {
      final newGroup = _taskController.createGroup(
        name: name,
        color: _selectedColor!,
      );
      Navigator.pop(context, newGroup);
    }
  }

  /// 获取对比色
  Color _getContrastColor(Color color) {
    final luminance = color.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}
