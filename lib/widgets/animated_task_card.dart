import 'package:flutter/material.dart';
import '../theme/neobrutal_theme.dart';

class AnimatedTaskCard extends StatefulWidget {
  final String title;
  final String priority;
  final String dueTime;
  final VoidCallback onToggle;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  
  const AnimatedTaskCard({
    super.key,
    required this.title,
    required this.priority,
    required this.dueTime,
    required this.onToggle,
    required this.onTap,
    this.onEdit,
  });

  @override
  State<AnimatedTaskCard> createState() => _AnimatedTaskCardState();
}

class _AnimatedTaskCardState extends State<AnimatedTaskCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  bool _isCompleted = false;

  @override
  Widget build(BuildContext context) {
    Color priorityColor;
    switch (widget.priority) {
      case 'High':
        priorityColor = NeoBrutalTheme.error;
        break;
      case 'Medium':
        priorityColor = NeoBrutalTheme.warning;
        break;
      default:
        priorityColor = NeoBrutalTheme.success;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      transform: Matrix4.identity()..scale(_isHovered ? 1.02 : 1.0),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isHovered = true),
        onTapUp: (_) => setState(() => _isHovered = false),
        onTapCancel: () => setState(() => _isHovered = false),
        onLongPress: widget.onEdit,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                NeoBrutalTheme.surface,
                _isCompleted
                    ? NeoBrutalTheme.success.withValues(alpha: 0.1)
                    : NeoBrutalTheme.surfaceVariant,
              ],
            ),
            borderRadius: NeoBrutalTheme.radiusMedium,
            border: Border.all(
              color: priorityColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: NeoBrutalTheme.radiusMedium,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Transform.scale(
                      scale: 1.3,
                      child: Checkbox(
                        value: _isCompleted,
                        onChanged: (val) {
                          setState(() => _isCompleted = val ?? false);
                          widget.onToggle();
                        },
                        shape: const RoundedRectangleBorder(
                          borderRadius: NeoBrutalTheme.radiusSmall,
                        ),
                        activeColor: NeoBrutalTheme.success,
                        side: BorderSide(color: priorityColor, width: 2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: NeoBrutalTheme.textTheme.titleMedium?.copyWith(
                              decoration: _isCompleted ? TextDecoration.lineThrough : null,
                              color: _isCompleted ? NeoBrutalTheme.textSecondary : NeoBrutalTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _buildPriorityDot(priorityColor),
                              const SizedBox(width: 6),
                              Text(widget.priority, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              const SizedBox(width: 16),
                              const Icon(Icons.access_time, size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(widget.dueTime, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (_isCompleted)
                      const Icon(Icons.check_circle, color: NeoBrutalTheme.success, size: 24)
                    else if (widget.onEdit != null)
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: widget.onEdit,
                        color: NeoBrutalTheme.primary,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityDot(Color color) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 6),
        ],
      ),
    );
  }
}
