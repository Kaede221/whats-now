import 'package:flutter/material.dart';
import '../../domain/models/models.dart';
import '../../domain/controllers/task_controller.dart';
import '../../domain/controllers/view_settings_controller.dart';
import '../widgets/task_list_item.dart';
import '../widgets/task_drawer.dart';
import '../widgets/sort_group_dialog.dart';
import 'add_task_page.dart';

/// 任务页面
/// 显示用户的任务列表，支持添加、编辑、删除任务
class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  final TaskController _taskController = TaskController();
  final ViewSettingsController _viewSettingsController =
      ViewSettingsController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // 当前筛选器，默认显示收集箱
  late TaskFilter _currentFilter;

  @override
  void initState() {
    super.initState();
    _taskController.addListener(_onTasksChanged);
    _viewSettingsController.addListener(_onViewSettingsChanged);
    // 初始化为收集箱筛选器
    final inbox = _taskController.getGroupById('inbox') ?? TaskGroup.inbox;
    _currentFilter = TaskFilter.fromGroup(
      groupId: inbox.id,
      name: inbox.name,
      icon: inbox.icon,
      color: inbox.color,
    );
  }

  @override
  void dispose() {
    _taskController.removeListener(_onTasksChanged);
    _viewSettingsController.removeListener(_onViewSettingsChanged);
    super.dispose();
  }

  void _onTasksChanged() {
    setState(() {
      // 如果当前筛选器是分组，更新分组信息（颜色可能变化）
      if (_currentFilter.type == TaskFilterType.group &&
          _currentFilter.groupId != null) {
        final group = _taskController.getGroupById(_currentFilter.groupId!);
        if (group != null) {
          _currentFilter = TaskFilter.fromGroup(
            groupId: group.id,
            name: group.name,
            icon: group.icon,
            color: group.color,
          );
        }
      }
    });
  }

  void _onViewSettingsChanged() {
    setState(() {});
  }

  /// 获取当前筛选后的任务列表
  List<Task> _getFilteredTasks() {
    final allTasks = _taskController.tasks;

    List<Task> filtered;
    switch (_currentFilter.type) {
      case TaskFilterType.all:
        filtered = List.from(allTasks);
        break;

      case TaskFilterType.group:
        if (_currentFilter.groupId != null) {
          filtered =
              allTasks.where((t) => t.groupId == _currentFilter.groupId).toList();
        } else {
          filtered = List.from(allTasks);
        }
        break;

      case TaskFilterType.dateRange:
        if (_currentFilter.daysRange != null) {
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final endDate = today.add(Duration(days: _currentFilter.daysRange!));

          filtered = allTasks.where((t) {
            if (t.dueDate == null) return false;
            final dueDate = DateTime(
              t.dueDate!.year,
              t.dueDate!.month,
              t.dueDate!.day,
            );
            return dueDate.isAfter(today.subtract(const Duration(days: 1))) &&
                dueDate.isBefore(endDate.add(const Duration(days: 1)));
          }).toList();
        } else {
          filtered = List.from(allTasks);
        }
        break;
    }

    // 应用排序
    _sortTasks(filtered);

    return filtered;
  }

  /// 对任务列表进行排序
  void _sortTasks(List<Task> tasks) {
    final sortBy = _viewSettingsController.sortBy;
    final sortOrder = _viewSettingsController.sortOrder;
    final isAscending = sortOrder == SortOrder.ascending;

    tasks.sort((a, b) {
      // 未完成的任务排在前面
      if (a.isCompleted != b.isCompleted) {
        return a.isCompleted ? 1 : -1;
      }

      int comparison;
      switch (sortBy) {
        case SortBy.createdAt:
          comparison = a.createdAt.compareTo(b.createdAt);
          break;
        case SortBy.dueDate:
          // 没有截止日期的排在后面
          if (a.dueDate == null && b.dueDate == null) {
            comparison = a.createdAt.compareTo(b.createdAt);
          } else if (a.dueDate == null) {
            comparison = 1;
          } else if (b.dueDate == null) {
            comparison = -1;
          } else {
            comparison = a.dueDate!.compareTo(b.dueDate!);
          }
          break;
        case SortBy.priority:
          comparison = a.priority.value.compareTo(b.priority.value);
          break;
      }

      return isAscending ? comparison : -comparison;
    });
  }

  /// 根据分组方式对任务进行分组
  Map<String, List<Task>> _groupTasks(List<Task> tasks) {
    final groupBy = _viewSettingsController.groupBy;

    if (groupBy == GroupBy.none) {
      return {'': tasks};
    }

    final Map<String, List<Task>> grouped = {};

    for (final task in tasks) {
      String key;
      switch (groupBy) {
        case GroupBy.none:
          key = '';
          break;
        case GroupBy.group:
          final group = _taskController.getGroupById(task.groupId);
          key = group?.name ?? '未分组';
          break;
        case GroupBy.dueDate:
          key = _getDateGroupKey(task.dueDate);
          break;
        case GroupBy.priority:
          key = task.priority.label;
          break;
      }

      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(task);
    }

    return grouped;
  }

  /// 获取日期分组的键名
  String _getDateGroupKey(DateTime? dueDate) {
    if (dueDate == null) return '无截止日期';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final nextWeek = today.add(const Duration(days: 7));
    final taskDate = DateTime(dueDate.year, dueDate.month, dueDate.day);

    if (taskDate.isBefore(today)) {
      return '已过期';
    } else if (taskDate == today) {
      return '今天';
    } else if (taskDate == tomorrow) {
      return '明天';
    } else if (taskDate.isBefore(nextWeek)) {
      return '本周';
    } else {
      return '以后';
    }
  }

  /// 获取分组的排序优先级
  int _getGroupSortPriority(String groupKey, GroupBy groupBy) {
    switch (groupBy) {
      case GroupBy.none:
        return 0;
      case GroupBy.group:
        // 分组按名称排序
        return 0;
      case GroupBy.dueDate:
        // 日期分组按时间顺序
        switch (groupKey) {
          case '已过期':
            return 0;
          case '今天':
            return 1;
          case '明天':
            return 2;
          case '本周':
            return 3;
          case '以后':
            return 4;
          case '无截止日期':
            return 5;
          default:
            return 6;
        }
      case GroupBy.priority:
        // 优先级分组按优先级排序
        switch (groupKey) {
          case '高':
            return 0;
          case '中':
            return 1;
          case '低':
            return 2;
          case '无':
            return 3;
          default:
            return 4;
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredTasks = _getFilteredTasks();
    final incompleteTasks = filteredTasks.where((t) => !t.isCompleted).toList();
    final completedTasks = filteredTasks.where((t) => t.isCompleted).toList();
    final hasAnyTasks = incompleteTasks.isNotEmpty || completedTasks.isNotEmpty;
    final hideDetails = _viewSettingsController.hideDetails;

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        title: Text(_currentFilter.name),
        titleSpacing: 0,
        actions: [
          // 三点菜单
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'toggle_details':
                  _viewSettingsController.toggleHideDetails();
                  break;
                case 'sort_group':
                  SortGroupDialog.show(context);
                  break;
                case 'clear_completed':
                  _showClearCompletedDialog(context);
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'toggle_details',
                child: Row(
                  children: [
                    Icon(hideDetails
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined),
                    const SizedBox(width: 8),
                    Text(hideDetails ? '显示详情' : '隐藏详情'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'sort_group',
                child: Row(
                  children: [
                    Icon(Icons.sort_outlined),
                    SizedBox(width: 8),
                    Text('排序方式'),
                  ],
                ),
              ),
              if (completedTasks.isNotEmpty)
                const PopupMenuItem(
                  value: 'clear_completed',
                  child: Row(
                    children: [
                      Icon(Icons.delete_sweep_outlined),
                      SizedBox(width: 8),
                      Text('清除已完成'),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
      drawer: TaskDrawer(
        currentFilter: _currentFilter,
        onFilterChanged: (filter) {
          setState(() {
            _currentFilter = filter;
          });
        },
      ),
      body: hasAnyTasks
          ? _buildTaskList(context, incompleteTasks, completedTasks, hideDetails)
          : _buildEmptyState(context),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddTask(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  /// 构建空状态
  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    String emptyMessage;
    IconData emptyIcon;

    switch (_currentFilter.type) {
      case TaskFilterType.dateRange:
        emptyMessage = '${_currentFilter.name}内没有任务';
        emptyIcon = Icons.event_available;
        break;
      case TaskFilterType.group:
        emptyMessage = '该分组暂无任务';
        emptyIcon = Icons.folder_open_outlined;
        break;
      case TaskFilterType.all:
        emptyMessage = '暂无任务';
        emptyIcon = Icons.task_alt;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(emptyIcon, size: 64, color: theme.colorScheme.outline),
          const SizedBox(height: 16),
          Text(
            emptyMessage,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击下方按钮添加新任务',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建任务列表
  Widget _buildTaskList(
    BuildContext context,
    List<Task> incompleteTasks,
    List<Task> completedTasks,
    bool hideDetails,
  ) {
    final groupBy = _viewSettingsController.groupBy;

    // 如果有分组，按分组显示
    if (groupBy != GroupBy.none) {
      return _buildGroupedTaskList(
        context,
        incompleteTasks,
        completedTasks,
        hideDetails,
      );
    }

    // 无分组，直接显示列表
    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 88),
      children: [
        // 未完成的任务
        ...incompleteTasks.map(
          (task) => TaskListItem(
            key: Key(task.id),
            task: task,
            hideDetails: hideDetails,
            onTap: () => _navigateToEditTask(context, task),
            onToggleCompleted: () =>
                _taskController.toggleTaskCompleted(task.id),
            onDelete: () => _deleteTask(context, task),
            groupName: _taskController.getGroupById(task.groupId)?.name,
          ),
        ),

        // 已完成的任务（可折叠）
        if (completedTasks.isNotEmpty)
          _buildCompletedSection(context, completedTasks, hideDetails),
      ],
    );
  }

  /// 构建分组任务列表
  Widget _buildGroupedTaskList(
    BuildContext context,
    List<Task> incompleteTasks,
    List<Task> completedTasks,
    bool hideDetails,
  ) {
    final theme = Theme.of(context);
    final groupBy = _viewSettingsController.groupBy;
    final groupedTasks = _groupTasks(incompleteTasks);

    // 对分组进行排序
    final sortedGroups = groupedTasks.keys.toList()
      ..sort((a, b) {
        final priorityA = _getGroupSortPriority(a, groupBy);
        final priorityB = _getGroupSortPriority(b, groupBy);
        if (priorityA != priorityB) {
          return priorityA.compareTo(priorityB);
        }
        return a.compareTo(b);
      });

    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 88),
      children: [
        // 分组显示未完成的任务
        for (final groupKey in sortedGroups) ...[
          if (groupedTasks[groupKey]!.isNotEmpty) ...[
            // 分组标题
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                groupKey.isEmpty ? '任务' : groupKey,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            // 分组内的任务
            ...groupedTasks[groupKey]!.map(
              (task) => TaskListItem(
                key: Key(task.id),
                task: task,
                hideDetails: hideDetails,
                onTap: () => _navigateToEditTask(context, task),
                onToggleCompleted: () =>
                    _taskController.toggleTaskCompleted(task.id),
                onDelete: () => _deleteTask(context, task),
                groupName: _taskController.getGroupById(task.groupId)?.name,
              ),
            ),
          ],
        ],

        // 已完成的任务（可折叠）
        if (completedTasks.isNotEmpty)
          _buildCompletedSection(context, completedTasks, hideDetails),
      ],
    );
  }

  /// 构建已完成任务分组
  Widget _buildCompletedSection(
    BuildContext context,
    List<Task> completedTasks,
    bool hideDetails,
  ) {
    final theme = Theme.of(context);

    return ExpansionTile(
      initiallyExpanded: false,
      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
      title: Text(
        '已完成 (${completedTasks.length})',
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.outline,
        ),
      ),
      children: completedTasks
          .map(
            (task) => TaskListItem(
              key: Key(task.id),
              task: task,
              hideDetails: hideDetails,
              onTap: () => _navigateToEditTask(context, task),
              onToggleCompleted: () =>
                  _taskController.toggleTaskCompleted(task.id),
              onDelete: () => _deleteTask(context, task),
              groupName: _taskController.getGroupById(task.groupId)?.name,
            ),
          )
          .toList(),
    );
  }

  /// 导航到添加任务页面
  Future<void> _navigateToAddTask(BuildContext context) async {
    // 如果当前是分组筛选，传递分组ID
    String? defaultGroupId;
    if (_currentFilter.type == TaskFilterType.group &&
        _currentFilter.groupId != null) {
      defaultGroupId = _currentFilter.groupId;
    }

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddTaskPage(defaultGroupId: defaultGroupId),
      ),
    );

    // 如果返回 true，表示任务已添加
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('任务已添加'), duration: Duration(seconds: 2)),
      );
    }
  }

  /// 导航到编辑任务页面
  Future<void> _navigateToEditTask(BuildContext context, Task task) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => AddTaskPage(task: task)),
    );

    // 如果返回 true，表示任务已更新
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('任务已更新'), duration: Duration(seconds: 2)),
      );
    }
  }

  /// 删除任务
  void _deleteTask(BuildContext context, Task task) {
    _taskController.deleteTask(task.id);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已删除 "${task.title}"'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  /// 显示清除已完成任务对话框
  void _showClearCompletedDialog(BuildContext context) {
    final filteredTasks = _getFilteredTasks();
    final completedCount = filteredTasks.where((t) => t.isCompleted).length;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清除已完成任务'),
        content: Text('确定要删除当前视图中 $completedCount 个已完成的任务吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              // 只删除当前筛选视图中的已完成任务
              final tasksToDelete = filteredTasks
                  .where((t) => t.isCompleted)
                  .map((t) => t.id)
                  .toList();
              _taskController.deleteTasks(tasksToDelete);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('已清除已完成任务'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}
