import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../theme/neobrutal_theme.dart';
import '../providers/task_provider.dart';
import '../widgets/animated_task_card.dart';
import '../models/task.dart';
import '../app/routes.dart';
import 'task_screen/add_task_screen.dart';

class NeoBrutalTaskScreen extends ConsumerStatefulWidget {
  const NeoBrutalTaskScreen({super.key});

  @override
  ConsumerState<NeoBrutalTaskScreen> createState() => _NeoBrutalTaskScreenState();
}

class _NeoBrutalTaskScreenState extends ConsumerState<NeoBrutalTaskScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

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

  @override
  Widget build(BuildContext context) {
    final taskList = ref.watch(taskProvider);

    return Scaffold(
      backgroundColor: NeoBrutalTheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'TASKS',
          style: NeoBrutalTheme.textTheme.headlineMedium?.copyWith(
            letterSpacing: 2,
            fontWeight: FontWeight.w900,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: NeoBrutalTheme.secondary,
          indicatorWeight: 4,
          dividerColor: Colors.transparent,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
          tabs: const [
            Tab(text: 'ALL'),
            Tab(text: 'PENDING'),
            Tab(text: 'DONE'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTaskList(taskList),
                _buildTaskList(taskList.where((t) => t.status == TaskStatus.pending).toList()),
                _buildTaskList(taskList.where((t) => t.status == TaskStatus.completed).toList()),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.addTask),
        backgroundColor: NeoBrutalTheme.secondary,
        child: const Icon(Icons.add_task_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: TextField(
        onChanged: (val) => setState(() => _searchQuery = val),
        decoration: InputDecoration(
          hintText: 'SEARCH TASKS...',
          prefixIcon: const Icon(Icons.checklist_rtl_rounded, color: Colors.white24),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.05),
          border: OutlineInputBorder(
            borderRadius: NeoBrutalTheme.radiusMedium,
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildTaskList(List<Task> list) {
    final filtered = list.where((t) {
      final query = _searchQuery.toLowerCase();
      return t.title.toLowerCase().contains(query) || t.categoryName.toLowerCase().contains(query);
    }).toList();

    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (filtered.isEmpty) {
      return const Center(child: Text('NO TASKS FOUND', style: TextStyle(color: Colors.white24, fontWeight: FontWeight.bold)));
    }

    return AnimationLimiter(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final task = filtered[index];
          
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: AnimatedTaskCard(
                  title: task.title,
                  priority: task.priority.name.toUpperCase(),
                  dueTime: 'TODAY',
                  onToggle: () => ref.read(taskProvider.notifier).toggleTaskCompletion(task.id),
                  onTap: () {},
                  onEdit: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AddTaskScreen(existingTask: task)),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
