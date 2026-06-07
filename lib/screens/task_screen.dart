import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app/routes.dart';
import '../models/task.dart';
import '../models/category.dart';
import '../providers/task_provider.dart';
import '../providers/expense_provider.dart';
import '../widgets/task_card.dart';
import '../widgets/empty_state_widget.dart';
import '../utils/constants_shared.dart';
import 'task_screen/task_detail_screen.dart';

class TaskScreen extends ConsumerStatefulWidget {
  const TaskScreen({super.key});

  @override
  ConsumerState<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends ConsumerState<TaskScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  TaskPriority? _selectedPriority;
  String? _selectedCategoryId;
  String _sortBy = 'due_date_asc'; // due_date_asc, priority_desc, created_desc
  String _dateFilter = 'all'; // all, today, week, overdue

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Task> _filterAndSort(List<Task> list) {
    var result = List<Task>.from(list);

    // 1. Search Query Filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result.where((item) =>
          item.title.toLowerCase().contains(query) ||
          item.description.toLowerCase().contains(query) ||
          item.categoryName.toLowerCase().contains(query)).toList();
    }

    // 2. Priority Filter
    if (_selectedPriority != null) {
      result = result.where((item) => item.priority == _selectedPriority).toList();
    }

    // 3. Category Filter
    if (_selectedCategoryId != null) {
      result = result.where((item) => item.categoryId == _selectedCategoryId).toList();
    }

    // 4. Date filter (Today, Week, Overdue)
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayEnd = DateTime(today.year, today.month, today.day, 23, 59, 59);

    if (_dateFilter == 'today') {
      result = result.where((item) =>
          item.dueDate.isAfter(todayStart.subtract(const Duration(seconds: 1))) &&
          item.dueDate.isBefore(todayEnd)).toList();
    } else if (_dateFilter == 'week') {
      final weekEnd = todayStart.add(const Duration(days: 7));
      result = result.where((item) =>
          item.dueDate.isAfter(todayStart.subtract(const Duration(seconds: 1))) &&
          item.dueDate.isBefore(weekEnd)).toList();
    } else if (_dateFilter == 'overdue') {
      result = result.where((item) =>
          item.status == TaskStatus.pending &&
          item.dueDate.isBefore(todayStart)).toList();
    }

    // 5. Sorting
    result.sort((a, b) {
      switch (_sortBy) {
        case 'due_date_asc':
          return a.dueDate.compareTo(b.dueDate);
        case 'priority_desc':
          return a.priority.index.compareTo(b.priority.index); // high is 0, medium is 1, low is 2
        case 'created_desc':
          return b.createdAt.compareTo(a.createdAt);
        default:
          return a.dueDate.compareTo(b.dueDate);
      }
    });

    return result;
  }

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Sort Tasks', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const Divider(height: 1),
              _buildSortOption('Due Date (Soonest first)', 'due_date_asc'),
              _buildSortOption('Priority (Highest first)', 'priority_desc'),
              _buildSortOption('Created Date (Newest first)', 'created_desc'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortOption(String label, String value) {
    final active = _sortBy == value;
    return ListTile(
      title: Text(
        label,
        style: TextStyle(
          fontWeight: active ? FontWeight.bold : FontWeight.normal,
          color: active ? AppConstants.primaryColor : null,
        ),
      ),
      trailing: active ? const Icon(Icons.check, color: AppConstants.primaryColor) : null,
      onTap: () {
        setState(() {
          _sortBy = value;
        });
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(taskProvider);
    final expenseState = ref.watch(expenseProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final taskCategories = expenseState.categories
        .where((c) => c.type == CategoryType.task)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks Checklist'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppConstants.primaryColor,
          labelColor: AppConstants.primaryColor,
          unselectedLabelColor: isDark ? Colors.white60 : Colors.grey.shade600,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Pending'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.addTask),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add_task),
      ),
      body: Column(
        children: [
          // Filter & Search Controls
          Padding(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: isDark ? AppConstants.darkCardColor : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? Colors.grey.shade900 : Colors.grey.shade200, width: 1),
                        ),
                        child: TextField(
                          onChanged: (val) {
                            setState(() {
                              _searchQuery = val;
                            });
                          },
                          decoration: const InputDecoration(
                            hintText: 'Search tasks...',
                            prefixIcon: Icon(Icons.search, color: Colors.grey),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Sort Trigger
                    GestureDetector(
                      onTap: _showSortSheet,
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isDark ? AppConstants.darkCardColor : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? Colors.grey.shade900 : Colors.grey.shade200, width: 1),
                        ),
                        child: const Icon(Icons.sort, color: AppConstants.primaryColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Filter Chips List (Priority, Category, Due Timeline)
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    children: [
                      // Date/Overdue Chips
                      DropdownButton<String>(
                        value: _dateFilter,
                        hint: const Text('Timeline', style: TextStyle(fontSize: 12)),
                        onChanged: (val) {
                          setState(() {
                            _dateFilter = val ?? 'all';
                          });
                        },
                        underline: const SizedBox.shrink(),
                        items: const [
                          DropdownMenuItem<String>(value: 'all', child: Text('All Time', style: TextStyle(fontSize: 12))),
                          DropdownMenuItem<String>(value: 'today', child: Text('Due Today', style: TextStyle(fontSize: 12))),
                          DropdownMenuItem<String>(value: 'week', child: Text('Due This Week', style: TextStyle(fontSize: 12))),
                          DropdownMenuItem<String>(value: 'overdue', child: Text('Overdue Only', style: TextStyle(fontSize: 12))),
                        ],
                      ),
                      const SizedBox(width: 12),

                      // Priority filter
                      DropdownButton<TaskPriority?>(
                        value: _selectedPriority,
                        hint: const Text('Priority', style: TextStyle(fontSize: 12)),
                        onChanged: (val) {
                          setState(() {
                            _selectedPriority = val;
                          });
                        },
                        underline: const SizedBox.shrink(),
                        items: [
                          const DropdownMenuItem<TaskPriority?>(
                            value: null,
                            child: Text('All Priorities', style: TextStyle(fontSize: 12)),
                          ),
                          ...TaskPriority.values.map((p) => DropdownMenuItem<TaskPriority?>(
                                value: p,
                                child: Text(p.name.toUpperCase(), style: const TextStyle(fontSize: 12)),
                              )),
                        ],
                      ),
                      const SizedBox(width: 12),

                      // Task Category Filter
                      DropdownButton<String>(
                        value: _selectedCategoryId,
                        hint: const Text('Category', style: TextStyle(fontSize: 12)),
                        onChanged: (val) {
                          setState(() {
                            _selectedCategoryId = val;
                          });
                        },
                        underline: const SizedBox.shrink(),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('All Categories', style: TextStyle(fontSize: 12)),
                          ),
                          ...taskCategories.map((c) => DropdownMenuItem<String>(
                                value: c.id,
                                child: Text(c.name, style: const TextStyle(fontSize: 12)),
                              )),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Lists Tab View
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTaskList(tasks, 'No tasks added yet.', Icons.task_outlined),
                _buildTaskList(tasks.where((t) => t.status == TaskStatus.pending).toList(), 'No pending tasks.', Icons.check_circle_outline),
                _buildTaskList(tasks.where((t) => t.status == TaskStatus.completed).toList(), 'No completed tasks.', Icons.done_all_outlined),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList(List<Task> source, String emptyMessage, IconData emptyIcon) {
    final filtered = _filterAndSort(source);

    if (filtered.isEmpty) {
      return EmptyStateWidget(
        icon: emptyIcon,
        title: 'No Tasks Found',
        message: _searchQuery.isNotEmpty || _selectedPriority != null || _selectedCategoryId != null || _dateFilter != 'all'
            ? 'No tasks matched your active search and filter choices.'
            : emptyMessage,
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final t = filtered[index];
        return RepaintBoundary(
          child: TaskCard(
            task: t,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TaskDetailScreen(taskId: t.id),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
