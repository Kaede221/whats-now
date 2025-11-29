import 'package:flutter/material.dart';
import '../../domain/models/models.dart';
import '../../domain/controllers/task_controller.dart';

/// 任务侧边栏抽屉
/// 显示筛选器和分组列表，用于切换任务视图
class TaskDrawer extends StatefulWidget {
  final TaskFilter currentFilter;
  final ValueChanged<TaskFilter> onFilterChanged;

  const TaskDrawer({
    super.key,
    required this.currentFilter,
    required this.onFilterChanged,
  });

  @override
  State<TaskDrawer> createState() => _TaskDrawerState();
}

class _TaskDrawerState extends State<TaskDrawer> {
  final TaskController _taskController = TaskController();

  @override
  void initState() {
    super.initState();
    _taskController.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    _taskController.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final groups = _taskController.groups;
    
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 头部
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '筛选',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            const Divider(height: 1),
            
            // 筛选器列表
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  // 时间筛选器
                  _buildSectionHeader(context, '按时间'),
                  ...TaskFilter.presetFilters.map((filter) => 
                    _buildFilterTile(context, filter),
                  ),
                  
                  const SizedBox(height: 8),
                  const Divider(),
                  
                  // 分组筛选器
                  _buildSectionHeader(context, '分组'),
                  ...groups.map((group) => _buildGroupTile(context, group)),
                  
                  // 新建分组按钮
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: ListTile(
                      leading: Icon(
                        Icons.add,
                        color: theme.colorScheme.primary,
                      ),
                      title: Text(
                        '新建分组',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      onTap: () => _showCreateGroupDialog(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建分组标题
  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        title,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.outline,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// 构建筛选器列表项
  Widget _buildFilterTile(BuildContext context, TaskFilter filter) {
    final theme = Theme.of(context);
    final isSelected = widget.currentFilter.id == filter.id;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListTile(
        leading: Icon(
          filter.icon,
          color: isSelected 
              ? theme.colorScheme.primary 
              : theme.colorScheme.onSurfaceVariant,
        ),
        title: Text(
          filter.name,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected 
                ? theme.colorScheme.primary 
                : null,
          ),
        ),
        selected: isSelected,
        selectedTileColor: theme.colorScheme.primaryContainer.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        onTap: () {
          widget.onFilterChanged(filter);
          Navigator.pop(context);
        },
      ),
    );
  }

  /// 构建分组列表项
  Widget _buildGroupTile(BuildContext context, TaskGroup group) {
    final theme = Theme.of(context);
    final filter = TaskFilter.fromGroup(
      groupId: group.id,
      name: group.name,
      icon: group.icon,
      color: group.color,
    );
    final isSelected = widget.currentFilter.id == filter.id;
    
    // 获取该分组的任务数量
    final taskCount = _taskController.getTasksByGroup(group.id)
        .where((t) => !t.isCompleted)
        .length;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListTile(
        leading: Icon(
          group.icon,
          color: isSelected ? group.color : group.color.withOpacity(0.7),
        ),
        title: Text(
          group.name,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected 
                ? theme.colorScheme.primary 
                : null,
          ),
        ),
        trailing: taskCount > 0
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$taskCount',
                  style: theme.textTheme.labelSmall,
                ),
              )
            : null,
        selected: isSelected,
        selectedTileColor: theme.colorScheme.primaryContainer.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        onTap: () {
          widget.onFilterChanged(filter);
          Navigator.pop(context);
        },
      ),
    );
  }

  /// 显示创建分组对话框
  void _showCreateGroupDialog(BuildContext context) {
    final theme = Theme.of(context);
    final nameController = TextEditingController();
    Color selectedColor = theme.colorScheme.primary;
    
    // 预设颜色列表
    final presetColors = [
      theme.colorScheme.primary,
      const Color(0xFF2196F3),
      const Color(0xFF4CAF50),
      const Color(0xFFFF9800),
      const Color(0xFFF44336),
      const Color(0xFFE91E63),
      const Color(0xFF00BCD4),
      const Color(0xFF795548),
    ];
    
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('新建分组'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameController,
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
                  final isSelected = selectedColor.value == color.value;
                  return GestureDetector(
                    onTap: () {
                      setDialogState(() => selectedColor = color);
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
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  final newGroup = _taskController.createGroup(
                    name: name,
                    color: selectedColor,
                  );
                  Navigator.pop(dialogContext);
                  // 切换到新创建的分组
                  final filter = TaskFilter.fromGroup(
                    groupId: newGroup.id,
                    name: newGroup.name,
                    icon: newGroup.icon,
                    color: newGroup.color,
                  );
                  widget.onFilterChanged(filter);
                  Navigator.pop(context); // 关闭抽屉
                }
              },
              child: const Text('创建'),
            ),
          ],
        ),
      ),
    );
  }

  /// 获取对比色
  Color _getContrastColor(Color color) {
    final luminance = color.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}