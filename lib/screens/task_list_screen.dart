import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../models/task.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../services/task_service.dart';
import '../theme.dart';
import '../widgets/delete_task_dialog.dart';
import 'task_form_screen.dart';

enum TaskFilter { all, pending, completed }

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final _service = TaskService();
  late final Stream<List<Task>> _stream = _service.watchTasks();
  final _searchCtrl = TextEditingController();

  String _query = '';
  bool _searching = false;
  TaskFilter _filter = TaskFilter.all;
  String _priority = 'All';

  @override
  void initState() {
    super.initState();
    NotificationService.instance.saveTokenForCurrentUser();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openForm([Task? task]) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => TaskFormScreen(task: task)));
  }

  Future<void> _delete(Task task) async {
    if (await confirmDeleteTask(context, task)) {
      await _service.delete(task.id);
    }
  }

  Future<void> _copyToken() async {
    final token = await NotificationService.instance.getToken();
    if (token == null || !mounted) return;
    await Clipboard.setData(ClipboardData(text: token));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('FCM token copied to clipboard')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: AppColors.dark,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        icon: const Icon(Icons.add, size: 18),
        label: const Text('New Task',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: StreamBuilder<List<Task>>(
          stream: _stream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final all = snapshot.data!;
            final pendingCount = all.where((t) => !t.isCompleted).length;
            final doneCount = all.length - pendingCount;

            final tasks = all.where((t) {
              final q = _query.toLowerCase();
              final matchesSearch = q.isEmpty ||
                  t.title.toLowerCase().contains(q) ||
                  t.description.toLowerCase().contains(q);
              final matchesFilter = _filter == TaskFilter.all ||
                  (_filter == TaskFilter.completed && t.isCompleted) ||
                  (_filter == TaskFilter.pending && !t.isCompleted);
              final matchesPriority = _priority == 'All' || t.priority == _priority;
              return matchesSearch && matchesFilter && matchesPriority;
            }).toList();

            return Column(
              children: [
                _buildHeader(all.length),
                if (_searching)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                    child: TextField(
                      controller: _searchCtrl,
                      autofocus: true,
                      decoration: fieldDecoration(hint: 'Search tasks...'),
                      onChanged: (v) => setState(() => _query = v),
                    ),
                  ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'All',
                        count: all.length,
                        selected: _filter == TaskFilter.all,
                        onTap: () => setState(() => _filter = TaskFilter.all),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Pending',
                        count: pendingCount,
                        selected: _filter == TaskFilter.pending,
                        onTap: () => setState(() => _filter = TaskFilter.pending),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Completed',
                        count: doneCount,
                        selected: _filter == TaskFilter.completed,
                        onTap: () => setState(() => _filter = TaskFilter.completed),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: tasks.isEmpty
                      ? const Center(
                          child: Text('No tasks found', style: TextStyle(color: AppColors.muted)))
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 96),
                          itemCount: tasks.length,
                          itemBuilder: (context, i) {
                            final t = tasks[i];
                            return _TaskCard(
                              task: t,
                              onToggle: () => _service.setCompleted(t.id, !t.isCompleted),
                              onEdit: () => _openForm(t),
                              onDelete: () => _delete(t),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(int total) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 8, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Tasks',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.dark)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.chip,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('$total TOTAL',
                          style: const TextStyle(
                              fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.muted)),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Today • ${DateFormat('EEEE, MMM d').format(DateTime.now())}',
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Search',
            icon: Icon(_searching ? Icons.close : Icons.search),
            onPressed: () => setState(() {
              _searching = !_searching;
              if (!_searching) {
                _query = '';
                _searchCtrl.clear();
              }
            }),
          ),
          PopupMenuButton<String>(
            tooltip: 'Filter by priority',
            icon: Icon(Icons.tune, color: _priority == 'All' ? null : AppColors.primary),
            onSelected: (v) => setState(() => _priority = v),
            itemBuilder: (_) => ['All', 'High', 'Medium', 'Low']
                .map((p) => CheckedPopupMenuItem<String>(
                      value: p,
                      checked: _priority == p,
                      child: Text(p == 'All' ? 'All priorities' : p),
                    ))
                .toList(),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (v) {
              if (v == 'token') {
                _copyToken();
              } else {
                AuthService().signOut();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'token', child: Text('Copy FCM token')),
              PopupMenuItem(value: 'logout', child: Text('Sign out')),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.dark : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.dark : AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : AppColors.muted)),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: selected ? Colors.white24 : AppColors.chip,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('$count',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : AppColors.muted)),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TaskCard({
    required this.task,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final done = task.isCompleted;
    final fmt = DateFormat('MMM d');
    return Opacity(
      opacity: done ? 0.55 : 1,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: onToggle,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: done ? AppColors.dark : Colors.transparent,
                      border: Border.all(
                          color: done ? AppColors.dark : const Color(0xFFD1D5DB), width: 1.5),
                    ),
                    child: done ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                  ),
                ),
                const SizedBox(width: 10),
                PriorityTag(task.priority),
                if (done) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.low.withAlpha(30),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('Done',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.low)),
                  ),
                ],
                const Spacer(),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.hint),
                  onPressed: onEdit,
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.hint),
                  onPressed: onDelete,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(task.title,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.dark)),
                  if (task.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(task.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                  ],
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: AppColors.border),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 13, color: AppColors.hint),
                      const SizedBox(width: 4),
                      Text('Due ${fmt.format(task.dueDate)}',
                          style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                      const SizedBox(width: 16),
                      const Icon(Icons.schedule, size: 13, color: AppColors.hint),
                      const SizedBox(width: 4),
                      Text(fmt.format(task.createdAt),
                          style: const TextStyle(fontSize: 11, color: AppColors.hint)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
