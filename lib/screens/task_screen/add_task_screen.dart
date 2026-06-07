import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../models/task.dart';
import '../../models/category.dart';
import '../../providers/task_provider.dart';
import '../../providers/expense_provider.dart';
import '../../utils/constants_shared.dart';

class AddTaskScreen extends ConsumerStatefulWidget {
  final Task? existingTask;
  const AddTaskScreen({super.key, this.existingTask});

  @override
  ConsumerState<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends ConsumerState<AddTaskScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();
  final _subtaskController = TextEditingController();
  final _estimatedMinController = TextEditingController();

  DateTime _selectedDate = DateTime.now().add(const Duration(hours: 1));
  TimeOfDay? _selectedTime;
  TaskPriority _priority = TaskPriority.medium;
  Category? _selectedCategory;
  List<Subtask> _subtasks = [];
  bool _isRecurring = false;
  String? _recurringRule;
  bool _isSaving = false;
  final List<String> _tags = [];
  final _tagController = TextEditingController();

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  bool get isEditing => widget.existingTask != null;

  static const _recurringOptions = ['daily', 'weekly', 'monthly'];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();

    if (isEditing) {
      final t = widget.existingTask!;
      _titleController.text = t.title;
      _descriptionController.text = t.description;
      _notesController.text = t.notes ?? '';
      _selectedDate = t.dueDate;
      _selectedTime = t.dueTime;
      _priority = t.priority;
      _subtasks = List.from(t.subtasks);
      _isRecurring = t.isRecurring;
      _recurringRule = t.recurringRule;
      _tags.addAll(t.tags);
      if (t.estimatedMinutes != null) {
        _estimatedMinController.text = t.estimatedMinutes.toString();
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    _subtaskController.dispose();
    _estimatedMinController.dispose();
    _tagController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.fromSeed(seedColor: AppConstants.primaryColor),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  void _addSubtask() {
    final text = _subtaskController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _subtasks.add(Subtask(id: const Uuid().v4(), title: text));
      _subtaskController.clear();
    });
  }

  void _addTag() {
    final text = _tagController.text.trim();
    if (text.isEmpty || _tags.contains(text)) return;
    setState(() {
      _tags.add(text);
      _tagController.clear();
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final cats = ref.read(expenseProvider).categories;
    final taskCats = cats.where((c) => c.type == CategoryType.task).toList();
    final cat = _selectedCategory ??
        (taskCats.isNotEmpty ? taskCats.first : null);

    final task = Task(
      id: isEditing ? widget.existingTask!.id : const Uuid().v4(),
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      categoryId: cat?.id ?? 'task_general',
      categoryName: cat?.name ?? 'General',
      priority: _priority,
      status: isEditing ? widget.existingTask!.status : TaskStatus.pending,
      dueDate: _selectedDate,
      dueHour: _selectedTime?.hour,
      dueMinute: _selectedTime?.minute,
      subtasks: _subtasks,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      isRecurring: _isRecurring,
      recurringRule: _isRecurring ? _recurringRule : null,
      linkedExpenseIds: isEditing ? widget.existingTask!.linkedExpenseIds : [],
      createdAt: isEditing ? widget.existingTask!.createdAt : DateTime.now(),
      completedAt: isEditing ? widget.existingTask!.completedAt : null,
      tags: _tags,
      estimatedMinutes: int.tryParse(_estimatedMinController.text),
      actualMinutes: isEditing ? widget.existingTask!.actualMinutes : null,
    );

    if (isEditing) {
      await ref.read(taskProvider.notifier).updateTask(task);
    } else {
      await ref.read(taskProvider.notifier).addTask(task);
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing ? 'Task updated!' : 'Task created!'),
          backgroundColor: AppConstants.primaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final expenseState = ref.watch(expenseProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final taskCats = expenseState.categories.where((c) => c.type == CategoryType.task).toList();

    if (isEditing && _selectedCategory == null) {
      try {
        _selectedCategory = taskCats.firstWhere((c) => c.id == widget.existingTask!.categoryId);
      } catch (_) {
        if (taskCats.isNotEmpty) _selectedCategory = taskCats.first;
      }
    }

    return Scaffold(
      backgroundColor: isDark ? AppConstants.darkBgColor : AppConstants.lightBgColor,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Task' : 'New Task'),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppConstants.expenseColor),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete Task'),
                    content: const Text('Delete this task permanently?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Delete', style: TextStyle(color: AppConstants.expenseColor)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await ref.read(taskProvider.notifier).deleteTask(widget.existingTask!.id);
                  if (mounted) Navigator.pop(context);
                }
              },
            ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            children: [
              // Title
              _buildTextField(
                controller: _titleController,
                label: 'TASK TITLE',
                hint: 'What needs to be done?',
                icon: Icons.task_alt,
                isDark: isDark,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a title' : null,
              ),
              const SizedBox(height: 14),

              // Description
              _buildTextField(
                controller: _descriptionController,
                label: 'DESCRIPTION',
                hint: 'Describe the task (optional)',
                icon: Icons.description_outlined,
                isDark: isDark,
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Priority
              _SectionLabel(label: 'PRIORITY'),
              const SizedBox(height: 8),
              Row(
                children: TaskPriority.values.map((p) {
                  final isSelected = _priority == p;
                  final color = _priorityColor(p);
                  final label = _priorityLabel(p);
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _priority = p),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? color : (isDark ? AppConstants.darkCardColor : Colors.white),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: isSelected ? color : Colors.grey.shade300, width: 1.5),
                        ),
                        child: Column(
                          children: [
                            Icon(_priorityIcon(p), color: isSelected ? Colors.white : color, size: 20),
                            const SizedBox(height: 4),
                            Text(
                              label,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Category
              if (taskCats.isNotEmpty) ...[
                _SectionLabel(label: 'CATEGORY'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: taskCats.map((cat) {
                    final isSelected = _selectedCategory?.id == cat.id;
                    final catColor = Color(cat.colorValue);
                    return GestureDetector(
                      onTap: () => setState(() => _selectedCategory = cat),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? catColor : (isDark ? AppConstants.darkCardColor : Colors.white),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: isSelected ? catColor : Colors.grey.shade300, width: 1.5),
                        ),
                        child: Text(
                          cat.name,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],

              // Due Date & Time
              _SectionLabel(label: 'DUE DATE & TIME'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: GestureDetector(
                      onTap: _pickDate,
                      child: _DateTimeChip(
                        icon: Icons.calendar_today_outlined,
                        label: DateFormat('MMM d, y').format(_selectedDate),
                        color: AppConstants.primaryColor,
                        isDark: isDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: _pickTime,
                      child: _DateTimeChip(
                        icon: Icons.access_time_outlined,
                        label: _selectedTime != null
                            ? _selectedTime!.format(context)
                            : 'Set time',
                        color: _selectedTime != null
                            ? AppConstants.primaryColor
                            : Colors.grey,
                        isDark: isDark,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Subtasks
              _SectionLabel(label: 'SUBTASKS (${_subtasks.length})'),
              const SizedBox(height: 8),
              ..._subtasks.asMap().entries.map((entry) {
                final idx = entry.key;
                final sub = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? AppConstants.darkCardColor : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => setState(() => sub.isCompleted = !sub.isCompleted),
                          child: Icon(
                            sub.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                            color: sub.isCompleted ? AppConstants.secondaryColor : Colors.grey,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            sub.title,
                            style: TextStyle(
                              decoration: sub.isCompleted ? TextDecoration.lineThrough : null,
                              color: sub.isCompleted ? Colors.grey : null,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _subtasks.removeAt(idx)),
                          child: const Icon(Icons.close, size: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _subtaskController,
                      decoration: InputDecoration(
                        hintText: 'Add a subtask...',
                        hintStyle: const TextStyle(fontSize: 13),
                        filled: true,
                        fillColor: isDark ? AppConstants.darkCardColor : Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppConstants.primaryColor),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      onFieldSubmitted: (_) => _addSubtask(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _addSubtask,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppConstants.primaryColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.add, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Tags
              _SectionLabel(label: 'TAGS'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  ..._tags.map((tag) => Chip(
                        label: Text(tag, style: const TextStyle(fontSize: 12)),
                        deleteIcon: const Icon(Icons.close, size: 14),
                        onDeleted: () => setState(() => _tags.remove(tag)),
                        backgroundColor: AppConstants.primaryColor.withValues(alpha: 0.15),
                        deleteIconColor: AppConstants.primaryColor,
                        labelStyle: const TextStyle(color: AppConstants.primaryColor),
                        side: BorderSide.none,
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      )),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _tagController,
                      decoration: InputDecoration(
                        hintText: 'Add tag...',
                        hintStyle: const TextStyle(fontSize: 13),
                        filled: true,
                        fillColor: isDark ? AppConstants.darkCardColor : Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppConstants.primaryColor),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      onFieldSubmitted: (_) => _addTag(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _addTag,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppConstants.primaryColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.add, color: AppConstants.primaryColor, size: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Estimated minutes
              _buildTextField(
                controller: _estimatedMinController,
                label: 'ESTIMATED TIME (MINUTES)',
                hint: 'e.g. 30',
                icon: Icons.timer_outlined,
                isDark: isDark,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 14),

              // Notes
              _buildTextField(
                controller: _notesController,
                label: 'NOTES',
                hint: 'Additional notes...',
                icon: Icons.notes_outlined,
                isDark: isDark,
                maxLines: 3,
              ),
              const SizedBox(height: 14),

              // Recurring
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? AppConstants.darkCardColor : Colors.white,
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                  border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Recurring Task', style: TextStyle(fontWeight: FontWeight.w600)),
                      value: _isRecurring,
                      activeThumbColor: AppConstants.primaryColor,
                      onChanged: (v) => setState(() => _isRecurring = v),
                    ),
                    if (_isRecurring) ...[
                      const Divider(height: 1),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: _recurringOptions.map((opt) {
                          final isSelected = _recurringRule == opt;
                          return ChoiceChip(
                            label: Text(opt[0].toUpperCase() + opt.substring(1)),
                            selected: isSelected,
                            selectedColor: AppConstants.primaryColor,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : null,
                              fontWeight: FontWeight.w600,
                            ),
                            onSelected: (v) => setState(() => _recurringRule = v ? opt : null),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                        )
                      : Text(
                          isEditing ? 'Update Task' : 'Create Task',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(label: label),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 20, color: AppConstants.primaryColor),
            filled: true,
            fillColor: isDark ? AppConstants.darkCardColor : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
              borderSide: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
              borderSide: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
              borderSide: const BorderSide(color: AppConstants.primaryColor, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Color _priorityColor(TaskPriority p) {
    switch (p) {
      case TaskPriority.high: return AppConstants.expenseColor;
      case TaskPriority.medium: return AppConstants.warningLight;
      case TaskPriority.low: return AppConstants.secondaryColor;
    }
  }

  String _priorityLabel(TaskPriority p) {
    switch (p) {
      case TaskPriority.high: return 'High';
      case TaskPriority.medium: return 'Medium';
      case TaskPriority.low: return 'Low';
    }
  }

  IconData _priorityIcon(TaskPriority p) {
    switch (p) {
      case TaskPriority.high: return Icons.keyboard_double_arrow_up;
      case TaskPriority.medium: return Icons.drag_handle;
      case TaskPriority.low: return Icons.keyboard_double_arrow_down;
    }
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: Colors.grey,
        letterSpacing: 1.1,
      ),
    );
  }
}

class _DateTimeChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  const _DateTimeChip({required this.icon, required this.label, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppConstants.darkCardColor : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
