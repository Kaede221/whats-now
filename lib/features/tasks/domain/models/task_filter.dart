import 'package:flutter/material.dart';

/// 任务筛选器类型
enum TaskFilterType {
  /// 所有任务
  all,
  /// 按分组
  group,
  /// 按时间范围
  dateRange,
}

/// 任务筛选器
/// 用于定义任务列表的筛选条件
class TaskFilter {
  final String id;
  final String name;
  final IconData icon;
  final TaskFilterType type;
  final Color? color;
  
  /// 分组ID（当 type 为 group 时使用）
  final String? groupId;
  
  /// 天数范围（当 type 为 dateRange 时使用）
  final int? daysRange;

  const TaskFilter({
    required this.id,
    required this.name,
    required this.icon,
    required this.type,
    this.color,
    this.groupId,
    this.daysRange,
  });

  /// 预设筛选器：近七天
  static const TaskFilter next7Days = TaskFilter(
    id: 'next_7_days',
    name: '近七天',
    icon: Icons.date_range_outlined,
    type: TaskFilterType.dateRange,
    daysRange: 7,
  );

  /// 预设筛选器：近一个月
  static const TaskFilter next30Days = TaskFilter(
    id: 'next_30_days',
    name: '近一个月',
    icon: Icons.calendar_month_outlined,
    type: TaskFilterType.dateRange,
    daysRange: 30,
  );

  /// 预设筛选器：所有任务
  static const TaskFilter allTasks = TaskFilter(
    id: 'all',
    name: '所有任务',
    icon: Icons.list_alt_outlined,
    type: TaskFilterType.all,
  );

  /// 获取所有预设筛选器
  static List<TaskFilter> get presetFilters => [
    next7Days,
    next30Days,
    allTasks,
  ];

  /// 从分组创建筛选器
  static TaskFilter fromGroup({
    required String groupId,
    required String name,
    required IconData icon,
    Color? color,
  }) {
    return TaskFilter(
      id: 'group_$groupId',
      name: name,
      icon: icon,
      type: TaskFilterType.group,
      color: color,
      groupId: groupId,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TaskFilter && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}