import 'package:flutter/material.dart';
import '../../../../core/theme/theme_controller.dart';
import '../models/models.dart';

/// 任务控制器
/// 管理任务和分组的状态，提供增删改查操作
class TaskController extends ChangeNotifier {
  static final TaskController _instance = TaskController._internal();

  factory TaskController() => _instance;

  final ThemeController _themeController = ThemeController();

  TaskController._internal() {
    // 监听主题变化，更新收集箱颜色
    _themeController.addListener(_onThemeChanged);
    // 初始化默认分组
    _initInbox();
  }

  // 任务列表
  final List<Task> _tasks = [];

  // 分组列表
  final List<TaskGroup> _groups = [];

  /// 初始化收集箱
  void _initInbox() {
    _groups.add(_createInbox());
  }

  /// 创建收集箱（使用当前主题颜色）
  TaskGroup _createInbox() {
    return TaskGroup(
      id: 'inbox',
      name: '收集箱',
      color: _themeController.seedColor,
      icon: Icons.inbox_outlined,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// 主题变化时更新收集箱颜色
  void _onThemeChanged() {
    final inboxIndex = _groups.indexWhere((g) => g.id == 'inbox');
    if (inboxIndex != -1) {
      _groups[inboxIndex] = _groups[inboxIndex].copyWith(
        color: _themeController.seedColor,
      );
      notifyListeners();
    }
  }

  /// 获取所有任务
  List<Task> get tasks => List.unmodifiable(_tasks);

  /// 获取所有分组
  List<TaskGroup> get groups => List.unmodifiable(_groups);

  /// 获取未完成的任务
  List<Task> get incompleteTasks =>
      _tasks.where((t) => !t.isCompleted).toList();

  /// 获取已完成的任务
  List<Task> get completedTasks => _tasks.where((t) => t.isCompleted).toList();

  /// 根据分组ID获取任务
  List<Task> getTasksByGroup(String groupId) {
    return _tasks.where((t) => t.groupId == groupId).toList();
  }

  /// 根据优先级获取任务
  List<Task> getTasksByPriority(TaskPriority priority) {
    return _tasks.where((t) => t.priority == priority).toList();
  }

  /// 获取今日任务（截止日期为今天）
  List<Task> get todayTasks {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    return _tasks.where((t) {
      if (t.dueDate == null) return false;
      return t.dueDate!.isAfter(today.subtract(const Duration(seconds: 1))) &&
          t.dueDate!.isBefore(tomorrow);
    }).toList();
  }

  /// 获取过期任务
  List<Task> get overdueTasks {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return _tasks.where((t) {
      if (t.dueDate == null || t.isCompleted) return false;
      return t.dueDate!.isBefore(today);
    }).toList();
  }

  /// 根据ID获取任务
  Task? getTaskById(String id) {
    try {
      return _tasks.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  /// 根据ID获取分组
  TaskGroup? getGroupById(String id) {
    try {
      return _groups.firstWhere((g) => g.id == id);
    } catch (_) {
      return null;
    }
  }

  // ===== 任务操作 =====

  /// 添加任务
  void addTask(Task task) {
    _tasks.add(task);
    _sortTasks();
    notifyListeners();
  }

  /// 创建并添加任务（便捷方法）
  Task createTask({
    required String title,
    String? description,
    TaskPriority priority = TaskPriority.none,
    String groupId = 'inbox',
    DateTime? dueDate,
    DateTime? reminderAt,
    List<String>? tags,
  }) {
    final task = Task.create(
      title: title,
      description: description,
      priority: priority,
      groupId: groupId,
      dueDate: dueDate,
      reminderAt: reminderAt,
      tags: tags,
    );
    addTask(task);
    return task;
  }

  /// 更新任务
  void updateTask(Task task) {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _tasks[index] = task.copyWith(updatedAt: DateTime.now());
      _sortTasks();
      notifyListeners();
    }
  }

  /// 删除任务
  void deleteTask(String taskId) {
    _tasks.removeWhere((t) => t.id == taskId);
    notifyListeners();
  }

  /// 切换任务完成状态
  void toggleTaskCompleted(String taskId) {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      _tasks[index] = _tasks[index].toggleCompleted();
      notifyListeners();
    }
  }

  /// 批量删除任务
  void deleteTasks(List<String> taskIds) {
    _tasks.removeWhere((t) => taskIds.contains(t.id));
    notifyListeners();
  }

  /// 清除所有已完成的任务
  void clearCompletedTasks() {
    _tasks.removeWhere((t) => t.isCompleted);
    notifyListeners();
  }

  // ===== 分组操作 =====

  /// 添加分组
  void addGroup(TaskGroup group) {
    _groups.add(group);
    notifyListeners();
  }

  /// 创建并添加分组（便捷方法）
  TaskGroup createGroup({required String name, Color? color, IconData? icon}) {
    final now = DateTime.now();
    final group = TaskGroup(
      id: 'group_${now.millisecondsSinceEpoch}',
      name: name,
      color: color ?? _themeController.seedColor,
      icon: icon ?? Icons.folder_outlined,
      createdAt: now,
      updatedAt: now,
    );
    addGroup(group);
    return group;
  }

  /// 更新分组
  void updateGroup(TaskGroup group) {
    final index = _groups.indexWhere((g) => g.id == group.id);
    if (index != -1) {
      _groups[index] = group.copyWith(updatedAt: DateTime.now());
      notifyListeners();
    }
  }

  /// 删除分组（将该分组下的任务移到收集箱）
  void deleteGroup(String groupId) {
    if (groupId == 'inbox') return; // 不能删除收集箱

    // 将该分组下的任务移到收集箱
    for (int i = 0; i < _tasks.length; i++) {
      if (_tasks[i].groupId == groupId) {
        _tasks[i] = _tasks[i].copyWith(groupId: 'inbox');
      }
    }

    _groups.removeWhere((g) => g.id == groupId);
    notifyListeners();
  }

  // ===== 私有方法 =====

  /// 排序任务（按优先级降序，然后按创建时间降序）
  void _sortTasks() {
    _tasks.sort((a, b) {
      // 未完成的任务排在前面
      if (a.isCompleted != b.isCompleted) {
        return a.isCompleted ? 1 : -1;
      }
      // 按优先级降序
      if (a.priority.value != b.priority.value) {
        return b.priority.value.compareTo(a.priority.value);
      }
      // 按创建时间降序
      return b.createdAt.compareTo(a.createdAt);
    });
  }
}
