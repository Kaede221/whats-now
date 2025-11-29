import 'task_priority.dart';

/// 任务模型
/// 可扩展的任务数据结构，支持标题、详情、日期、优先级、分组等属性
class Task {
  /// 唯一标识符
  final String id;

  /// 任务标题（必填）
  final String title;

  /// 任务详情/描述（可选）
  final String? description;

  /// 优先级
  final TaskPriority priority;

  /// 所属分组ID
  final String groupId;

  /// 截止日期（可选）
  final DateTime? dueDate;

  /// 是否已完成
  final bool isCompleted;

  /// 完成时间
  final DateTime? completedAt;

  /// 创建时间
  final DateTime createdAt;

  /// 更新时间
  final DateTime updatedAt;

  // ===== 以下为可扩展字段，预留给未来功能 =====

  /// 提醒时间（可选）
  final DateTime? reminderAt;

  /// 重复规则（可选，预留）
  final String? repeatRule;

  /// 标签列表（可选，预留）
  final List<String>? tags;

  /// 附件列表（可选，预留）
  final List<String>? attachments;

  /// 子任务ID列表（可选，预留）
  final List<String>? subtaskIds;

  /// 父任务ID（可选，预留）
  final String? parentId;

  /// 排序顺序
  final int sortOrder;

  const Task({
    required this.id,
    required this.title,
    this.description,
    this.priority = TaskPriority.none,
    required this.groupId,
    this.dueDate,
    this.isCompleted = false,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
    this.reminderAt,
    this.repeatRule,
    this.tags,
    this.attachments,
    this.subtaskIds,
    this.parentId,
    this.sortOrder = 0,
  });

  /// 创建新任务的工厂方法
  factory Task.create({
    required String title,
    String? description,
    TaskPriority priority = TaskPriority.none,
    String groupId = 'inbox',
    DateTime? dueDate,
    DateTime? reminderAt,
    List<String>? tags,
  }) {
    final now = DateTime.now();
    return Task(
      id: _generateId(),
      title: title,
      description: description,
      priority: priority,
      groupId: groupId,
      dueDate: dueDate,
      createdAt: now,
      updatedAt: now,
      reminderAt: reminderAt,
      tags: tags,
    );
  }

  /// 生成唯一ID
  static String _generateId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
  }

  /// 复制并修改
  Task copyWith({
    String? id,
    String? title,
    String? description,
    TaskPriority? priority,
    String? groupId,
    DateTime? dueDate,
    bool? isCompleted,
    DateTime? completedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? reminderAt,
    String? repeatRule,
    List<String>? tags,
    List<String>? attachments,
    List<String>? subtaskIds,
    String? parentId,
    int? sortOrder,
    // 用于清除可选字段
    bool clearDescription = false,
    bool clearDueDate = false,
    bool clearCompletedAt = false,
    bool clearReminderAt = false,
    bool clearRepeatRule = false,
    bool clearTags = false,
    bool clearAttachments = false,
    bool clearSubtaskIds = false,
    bool clearParentId = false,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: clearDescription ? null : (description ?? this.description),
      priority: priority ?? this.priority,
      groupId: groupId ?? this.groupId,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      reminderAt: clearReminderAt ? null : (reminderAt ?? this.reminderAt),
      repeatRule: clearRepeatRule ? null : (repeatRule ?? this.repeatRule),
      tags: clearTags ? null : (tags ?? this.tags),
      attachments: clearAttachments ? null : (attachments ?? this.attachments),
      subtaskIds: clearSubtaskIds ? null : (subtaskIds ?? this.subtaskIds),
      parentId: clearParentId ? null : (parentId ?? this.parentId),
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  /// 标记为完成
  Task markAsCompleted() {
    return copyWith(isCompleted: true, completedAt: DateTime.now());
  }

  /// 标记为未完成
  Task markAsIncomplete() {
    return copyWith(isCompleted: false, clearCompletedAt: true);
  }

  /// 切换完成状态
  Task toggleCompleted() {
    return isCompleted ? markAsIncomplete() : markAsCompleted();
  }

  /// 转换为 Map（用于持久化）
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'priority': priority.value,
      'groupId': groupId,
      'dueDate': dueDate?.toIso8601String(),
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'reminderAt': reminderAt?.toIso8601String(),
      'repeatRule': repeatRule,
      'tags': tags,
      'attachments': attachments,
      'subtaskIds': subtaskIds,
      'parentId': parentId,
      'sortOrder': sortOrder,
    };
  }

  /// 从 Map 创建（用于持久化）
  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      priority: TaskPriority.fromValue(map['priority'] as int? ?? 0),
      groupId: map['groupId'] as String,
      dueDate: map['dueDate'] != null
          ? DateTime.parse(map['dueDate'] as String)
          : null,
      isCompleted: map['isCompleted'] as bool? ?? false,
      completedAt: map['completedAt'] != null
          ? DateTime.parse(map['completedAt'] as String)
          : null,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      reminderAt: map['reminderAt'] != null
          ? DateTime.parse(map['reminderAt'] as String)
          : null,
      repeatRule: map['repeatRule'] as String?,
      tags: (map['tags'] as List<dynamic>?)?.cast<String>(),
      attachments: (map['attachments'] as List<dynamic>?)?.cast<String>(),
      subtaskIds: (map['subtaskIds'] as List<dynamic>?)?.cast<String>(),
      parentId: map['parentId'] as String?,
      sortOrder: map['sortOrder'] as int? ?? 0,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Task && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Task(id: $id, title: $title, priority: ${priority.label}, isCompleted: $isCompleted)';
  }
}
