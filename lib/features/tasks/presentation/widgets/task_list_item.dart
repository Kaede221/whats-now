import 'package:flutter/material.dart';
import '../../domain/models/models.dart';

/// 任务列表项组件
/// 显示单个任务的信息，支持完成状态切换和点击编辑
/// 完成按钮在右侧，点击时有划线动画效果
class TaskListItem extends StatefulWidget {
  final Task task;
  final VoidCallback? onTap;
  final VoidCallback? onToggleCompleted;
  final VoidCallback? onDelete;

  const TaskListItem({
    super.key,
    required this.task,
    this.onTap,
    this.onToggleCompleted,
    this.onDelete,
  });

  @override
  State<TaskListItem> createState() => _TaskListItemState();
}

class _TaskListItemState extends State<TaskListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _strikethroughAnimation;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _strikethroughAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// 处理完成按钮点击
  void _handleToggleCompleted() {
    if (_isAnimating) return;

    if (!widget.task.isCompleted) {
      // 未完成 -> 完成：播放动画后触发回调
      setState(() => _isAnimating = true);
      _animationController.forward().then((_) {
        widget.onToggleCompleted?.call();
        setState(() => _isAnimating = false);
      });
    } else {
      // 已完成 -> 未完成：直接触发回调
      _animationController.value = 0.0;
      widget.onToggleCompleted?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dismissible(
      key: Key(widget.task.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => widget.onDelete?.call(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: theme.colorScheme.error,
        child: Icon(Icons.delete_outline, color: theme.colorScheme.onError),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 任务内容（左侧）
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 标题（带动画划线效果）
                      _buildAnimatedTitle(context),

                      // 详情
                      if (widget.task.description != null &&
                          widget.task.description!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: _buildAnimatedDescription(context),
                        ),

                      // 底部信息行（日期等）
                      if (widget.task.dueDate != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: _buildDueDateChip(context),
                        ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // 完成状态复选框（右侧，垂直居中）
                _buildCheckbox(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建带动画的标题
  Widget _buildAnimatedTitle(BuildContext context) {
    final theme = Theme.of(context);
    final isCompleted = widget.task.isCompleted;

    return AnimatedBuilder(
      animation: _strikethroughAnimation,
      builder: (context, child) {
        return CustomPaint(
          foregroundPainter: _isAnimating
              ? _StrikethroughPainter(
                  progress: _strikethroughAnimation.value,
                  color: theme.colorScheme.outline,
                )
              : null,
          child: Text(
            widget.task.title,
            style: theme.textTheme.bodyLarge?.copyWith(
              decoration: isCompleted && !_isAnimating
                  ? TextDecoration.lineThrough
                  : null,
              color: isCompleted ? theme.colorScheme.outline : null,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        );
      },
    );
  }

  /// 构建带动画的描述
  Widget _buildAnimatedDescription(BuildContext context) {
    final theme = Theme.of(context);
    final isCompleted = widget.task.isCompleted;

    return AnimatedBuilder(
      animation: _strikethroughAnimation,
      builder: (context, child) {
        return CustomPaint(
          foregroundPainter: _isAnimating
              ? _StrikethroughPainter(
                  progress: _strikethroughAnimation.value,
                  color: theme.colorScheme.outline.withOpacity(0.5),
                )
              : null,
          child: Text(
            widget.task.description!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
              decoration: isCompleted && !_isAnimating
                  ? TextDecoration.lineThrough
                  : null,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );
      },
    );
  }

  /// 构建复选框
  Widget _buildCheckbox(BuildContext context) {
    final theme = Theme.of(context);
    final isCompleted = widget.task.isCompleted;
    final showCompleted = isCompleted || _isAnimating;

    return GestureDetector(
      onTap: _handleToggleCompleted,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: showCompleted
                ? theme.colorScheme.primary
                : widget.task.priority.color,
            width: 2,
          ),
          color: showCompleted ? theme.colorScheme.primary : Colors.transparent,
        ),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: showCompleted ? 1.0 : 0.0,
          child: Icon(
            Icons.check,
            size: 18,
            color: theme.colorScheme.onPrimary,
          ),
        ),
      ),
    );
  }

  /// 构建截止日期标签
  Widget _buildDueDateChip(BuildContext context) {
    final theme = Theme.of(context);
    final isOverdue = _isOverdue();
    final isToday = _isToday();

    Color chipColor;
    Color textColor;

    if (widget.task.isCompleted) {
      chipColor = theme.colorScheme.surfaceContainerHighest;
      textColor = theme.colorScheme.outline;
    } else if (isOverdue) {
      chipColor = theme.colorScheme.errorContainer;
      textColor = theme.colorScheme.error;
    } else if (isToday) {
      chipColor = theme.colorScheme.primaryContainer;
      textColor = theme.colorScheme.primary;
    } else {
      chipColor = theme.colorScheme.surfaceContainerHighest;
      textColor = theme.colorScheme.onSurfaceVariant;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.calendar_today_outlined, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            _formatDueDate(),
            style: theme.textTheme.labelSmall?.copyWith(color: textColor),
          ),
        ],
      ),
    );
  }

  /// 检查是否过期
  bool _isOverdue() {
    if (widget.task.dueDate == null || widget.task.isCompleted) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return widget.task.dueDate!.isBefore(today);
  }

  /// 检查是否是今天
  bool _isToday() {
    if (widget.task.dueDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDate = DateTime(
      widget.task.dueDate!.year,
      widget.task.dueDate!.month,
      widget.task.dueDate!.day,
    );
    return dueDate == today;
  }

  /// 格式化截止日期
  String _formatDueDate() {
    if (widget.task.dueDate == null) return '';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final yesterday = today.subtract(const Duration(days: 1));
    final dueDate = DateTime(
      widget.task.dueDate!.year,
      widget.task.dueDate!.month,
      widget.task.dueDate!.day,
    );

    if (dueDate == today) {
      return '今天';
    } else if (dueDate == tomorrow) {
      return '明天';
    } else if (dueDate == yesterday) {
      return '昨天';
    } else if (widget.task.dueDate!.year == now.year) {
      return '${widget.task.dueDate!.month}月${widget.task.dueDate!.day}日';
    } else {
      return '${widget.task.dueDate!.year}年${widget.task.dueDate!.month}月${widget.task.dueDate!.day}日';
    }
  }
}

/// 划线动画绘制器
class _StrikethroughPainter extends CustomPainter {
  final double progress;
  final Color color;

  _StrikethroughPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final startY = size.height / 2;
    final endX = size.width * progress;

    canvas.drawLine(Offset(0, startY), Offset(endX, startY), paint);
  }

  @override
  bool shouldRepaint(_StrikethroughPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
