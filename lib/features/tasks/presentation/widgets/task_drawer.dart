import 'package:flutter/material.dart';
import '../../domain/models/models.dart';
import '../../domain/controllers/task_controller.dart';
import 'create_group_dialog.dart';

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
                  ...TaskFilter.presetFilters.map(
                    (filter) => _buildFilterTile(context, filter),
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
                        style: TextStyle(color: theme.colorScheme.primary),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      onTap: () async {
                        final newGroup = await CreateGroupDialog.show(context);
                        if (newGroup != null && mounted) {
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
            color: isSelected ? theme.colorScheme.primary : null,
          ),
        ),
        selected: isSelected,
        selectedTileColor: theme.colorScheme.primaryContainer.withOpacity(0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
    final taskCount = _taskController
        .getTasksByGroup(group.id)
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
            color: isSelected ? theme.colorScheme.primary : null,
          ),
        ),
        trailing: taskCount > 0
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('$taskCount', style: theme.textTheme.labelSmall),
              )
            : null,
        selected: isSelected,
        selectedTileColor: theme.colorScheme.primaryContainer.withOpacity(0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        onTap: () {
          widget.onFilterChanged(filter);
          Navigator.pop(context);
        },
      ),
    );
  }
}
