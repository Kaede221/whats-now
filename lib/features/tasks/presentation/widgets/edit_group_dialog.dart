import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/controllers/task_controller.dart';
import '../../domain/models/models.dart';

/// 编辑分组对话框
class EditGroupDialog extends StatefulWidget {
  final TaskGroup group;

  const EditGroupDialog({super.key, required this.group});

  /// 显示编辑分组对话框
  /// 返回更新后的分组，如果取消则返回 null
  /// 如果删除分组，返回一个特殊标记
  static Future<EditGroupResult?> show(BuildContext context, TaskGroup group) {
    return showDialog<EditGroupResult>(
      context: context,
      builder: (context) => EditGroupDialog(group: group),
    );
  }

  @override
  State<EditGroupDialog> createState() => _EditGroupDialogState();
}

/// 编辑分组对话框的结果
class EditGroupResult {
  final TaskGroup? updatedGroup;
  final bool isDeleted;

  const EditGroupResult({this.updatedGroup, this.isDeleted = false});

  /// 更新结果
  factory EditGroupResult.updated(TaskGroup group) =>
      EditGroupResult(updatedGroup: group);

  /// 删除结果
  factory EditGroupResult.deleted() => const EditGroupResult(isDeleted: true);
}

class _EditGroupDialogState extends State<EditGroupDialog> {
  final TaskController _taskController = TaskController();
  late TextEditingController _nameController;
  late Color _selectedColor;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.group.name);
    _selectedColor = widget.group.color;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isInbox = widget.group.id == 'inbox';

    // 预设颜色列表
    final presetColors = [
      theme.colorScheme.primary,
      ...AppConstants.groupColors,
    ];

    return AlertDialog(
      title: Text(isInbox ? '收集箱设置' : '编辑分组'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
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
                enabled: !isInbox, // 收集箱名称不可修改
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
                  final isSelected = _selectedColor.value == color.value;
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
              // 显示分组信息
              const SizedBox(height: 16),
              _buildInfoRow(
                context,
                '创建时间',
                _formatDateTime(widget.group.createdAt),
              ),
              const SizedBox(height: 4),
              _buildInfoRow(
                context,
                '任务数量',
                '${_taskController.getTasksByGroup(widget.group.id).length} 个任务',
              ),
            ],
          ),
        ),
      ),
      actions: [
        // 删除按钮（收集箱不可删除）
        if (!isInbox)
          TextButton(
            onPressed: _confirmDelete,
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        TextButton(onPressed: _saveGroup, child: const Text('保存')),
      ],
      actionsAlignment: isInbox ? MainAxisAlignment.end : MainAxisAlignment.spaceBetween,
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(
          '$label: ',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
        Text(value, style: theme.textTheme.bodySmall),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _saveGroup() {
    final name = _nameController.text.trim();
    if (name.isNotEmpty) {
      final updatedGroup = widget.group.copyWith(
        name: name,
        color: _selectedColor,
      );
      _taskController.updateGroup(updatedGroup);
      Navigator.pop(context, EditGroupResult.updated(updatedGroup));
    }
  }

  void _confirmDelete() {
    final taskCount = _taskController.getTasksByGroup(widget.group.id).length;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text(
          taskCount > 0
              ? '该分组下有 $taskCount 个任务，删除后这些任务将移至收集箱。确定要删除吗？'
              : '确定要删除分组"${widget.group.name}"吗？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              _taskController.deleteGroup(widget.group.id);
              Navigator.pop(context); // 关闭确认对话框
              Navigator.pop(
                this.context,
                EditGroupResult.deleted(),
              ); // 关闭编辑对话框
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  /// 获取对比色
  Color _getContrastColor(Color color) {
    final luminance = color.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}