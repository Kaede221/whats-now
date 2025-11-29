import 'package:flutter/material.dart';
import '../../domain/models/models.dart';
import '../../domain/controllers/task_controller.dart';
import '../widgets/task_list_item.dart';
import '../widgets/task_drawer.dart';
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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  // 当前筛选器，默认显示收集箱
  late TaskFilter _currentFilter;

  @override
  void initState() {
    super.initState();
    _taskController.addListener(_onTasksChanged);
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
    super.dispose();
  }

  void _onTasksChanged() {
    setState(() {
      // 如果当前筛选器是分组，更新分组信息（颜色可能变化）
      if (_currentFilter.type == TaskFilterType.group && _currentFilter.groupId != null) {
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

  /// 获取当前筛选后的任务列表
  List<Task> _getFilteredTasks() {
    final allTasks = _taskController.tasks;
    
    switch (_currentFilter.type) {
      case TaskFilterType.all:
        return allTasks;
      
      case TaskFilterType.group:
        if (_currentFilter.groupId != null) {
          return allTasks.where((t) => t.groupId == _currentFilter.groupId).toList();
        }
        return allTasks;
      
      case TaskFilterType.dateRange:
        if (_currentFilter.daysRange != null) {
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final endDate = today.add(Duration(days: _currentFilter.daysRange!));
          
          return allTasks.where((t) {
            if (t.dueDate == null) return false;
            final dueDate = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
            return dueDate.isAfter(today.subtract(const Duration(days: 1))) &&
                   dueDate.isBefore(endDate.add(const Duration(days: 1)));
          }).toList();
        }
        return allTasks;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filteredTasks = _getFilteredTasks();
    final incompleteTasks = filteredTasks.where((t) => !t.isCompleted).toList();
    final completedTasks = filteredTasks.where((t) => t.isCompleted).toList();
    final hasAnyTasks = incompleteTasks.isNotEmpty || completedTasks.isNotEmpty;
    
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
          if (completedTasks.isNotEmpty)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'clear_completed') {
                  _showClearCompletedDialog(context);
                }
              },
              itemBuilder: (context) => [
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
          ? _buildTaskList(context, incompleteTasks, completedTasks)
          : _buildEmptyState(context),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddTask(context),
        icon: const Icon(Icons.add),
        label: const Text('添加任务'),
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
      default:
        emptyMessage = '暂无任务';
        emptyIcon = Icons.task_alt;
    }
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            emptyIcon,
            size: 64,
            color: theme.colorScheme.outline,
          ),
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
  ) {
    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 88),
      children: [
        // 未完成的任务
        ...incompleteTasks.map((task) => TaskListItem(
          key: Key(task.id),
          task: task,
          onTap: () => _navigateToEditTask(context, task),
          onToggleCompleted: () => _taskController.toggleTaskCompleted(task.id),
          onDelete: () => _deleteTask(context, task),
        )),
        
        // 已完成的任务（可折叠）
        if (completedTasks.isNotEmpty)
          _buildCompletedSection(context, completedTasks),
      ],
    );
  }

  /// 构建已完成任务分组
  Widget _buildCompletedSection(BuildContext context, List<Task> completedTasks) {
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
      children: completedTasks.map((task) => TaskListItem(
        key: Key(task.id),
        task: task,
        onTap: () => _navigateToEditTask(context, task),
        onToggleCompleted: () => _taskController.toggleTaskCompleted(task.id),
        onDelete: () => _deleteTask(context, task),
      )).toList(),
    );
  }

  /// 导航到添加任务页面
  Future<void> _navigateToAddTask(BuildContext context) async {
    // 如果当前是分组筛选，传递分组ID
    String? defaultGroupId;
    if (_currentFilter.type == TaskFilterType.group && _currentFilter.groupId != null) {
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
        const SnackBar(
          content: Text('任务已添加'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// 导航到编辑任务页面
  Future<void> _navigateToEditTask(BuildContext context, Task task) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddTaskPage(task: task),
      ),
    );
    
    // 如果返回 true，表示任务已更新
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('任务已更新'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// 删除任务
  void _deleteTask(BuildContext context, Task task) {
    _taskController.deleteTask(task.id);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已删除 "${task.title}"'),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: '撤销',
          onPressed: () {
            _taskController.addTask(task);
          },
        ),
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