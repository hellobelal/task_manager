import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/task.dart';
import '../services/task_service.dart';
import '../theme.dart';

/// "New Task" (task == null) and "Edit Task" (task != null) screens from Figma.
class TaskFormScreen extends StatefulWidget {
  final Task? task;
  const TaskFormScreen({super.key, this.task});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  static const _courses = ['', 'CS 101', 'CS 304', 'CS 421', 'CS 450'];
  static const _priorities = ['Low', 'Medium', 'High'];

  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  DateTime _dueDate = DateTime.now();
  String _priority = 'Medium';
  bool _completed = false;
  String _course = '';
  bool _saving = false;

  bool get _isEdit => widget.task != null;

  @override
  void initState() {
    super.initState();
    _applyInitial();
  }

  void _applyInitial() {
    final t = widget.task;
    _title.text = t?.title ?? '';
    _description.text = t?.description ?? '';
    _dueDate = t?.dueDate ?? DateTime.now().add(const Duration(days: 1));
    _priority = t?.priority ?? 'Medium';
    _completed = t?.isCompleted ?? false;
    _course = t?.course ?? '';
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final service = TaskService();
    final task = Task(
      id: widget.task?.id ?? '',
      title: _title.text.trim(),
      description: _description.text.trim(),
      dueDate: _dueDate,
      priority: _priority,
      isCompleted: _completed,
      createdAt: widget.task?.createdAt ?? DateTime.now(),
      course: _course,
    );
    try {
      _isEdit ? await service.update(task) : await service.add(task);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  // ---------- small UI helpers ----------

  /// Add screen: UPPERCASE grey label. Edit screen: normal dark label.
  Widget _label(String addText, String editText, {Widget? trailing}) {
    if (!_isEdit) return FieldLabel(addText);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(editText,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.dark)),
          const Spacer(),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _dateField() => InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _pickDate,
        child: InputDecorator(
          decoration: fieldDecoration(
            suffix: _isEdit
                ? null
                : const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.muted),
          ),
          child: Row(
            children: [
              if (_isEdit) ...[
                const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.muted),
                const SizedBox(width: 8),
              ],
              Text(DateFormat('MM/dd/yyyy').format(_dueDate),
                  style: const TextStyle(fontSize: 14)),
            ],
          ),
        ),
      );

  Widget _courseDropdown() {
    final courses = [
      ..._courses,
      if (_course.isNotEmpty && !_courses.contains(_course)) _course,
    ];
    return DropdownButtonFormField<String>(
      value: _course,
      isExpanded: true,
      decoration: fieldDecoration(),
      items: courses
          .map((c) => DropdownMenuItem(
                value: c,
                child: Text(c.isEmpty ? 'None' : c, style: const TextStyle(fontSize: 14)),
              ))
          .toList(),
      onChanged: (v) => setState(() => _course = v ?? ''),
    );
  }

  /// Add screen priority: three bordered chips with a colored dot.
  Widget _priorityChips() => Row(
        children: _priorities.map((p) {
          final selected = _priority == p;
          final c = AppColors.priority(p);
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: p == 'High' ? 0 : 10),
              child: GestureDetector(
                onTap: () => setState(() => _priority = p),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: selected ? c.withAlpha(25) : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: selected ? c : AppColors.border, width: selected ? 1.5 : 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(color: c, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Text(p,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: selected ? c : AppColors.dark)),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      );

  /// Edit screen priority: segmented control (grey track, white selected pill).
  Widget _prioritySegment() => Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F1F5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: _priorities.map((p) {
            final selected = _priority == p;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _priority = p),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: selected
                        ? const [BoxShadow(color: Colors.black12, blurRadius: 4)]
                        : null,
                  ),
                  child: Text(p,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                          color: selected ? AppColors.dark : AppColors.muted)),
                ),
              ),
            );
          }).toList(),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: !_isEdit,
        title: Text(_isEdit ? 'Edit Task' : 'New Task',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        actions: [
          if (_isEdit)
            TextButton(
              onPressed: () => setState(_applyInitial),
              child: const Text('Reset', style: TextStyle(color: AppColors.muted, fontSize: 12)),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                children: [
                  _label('Title', 'Task Title',
                      trailing: Text('${_title.text.length}/60',
                          style: const TextStyle(fontSize: 10, color: AppColors.hint))),
                  TextFormField(
                    controller: _title,
                    maxLength: 60,
                    onChanged: (_) => setState(() {}),
                    decoration: fieldDecoration(
                      hint: 'e.g. Complete Flutter Assignment',
                      suffix: (_isEdit && _title.text.isNotEmpty)
                          ? IconButton(
                              icon: const Icon(Icons.close, size: 18, color: AppColors.muted),
                              onPressed: () => setState(_title.clear),
                            )
                          : null,
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Title is required' : null,
                  ),
                  const SizedBox(height: 18),
                  _label('Notes', 'Description & Milestones'),
                  TextFormField(
                    controller: _description,
                    maxLines: 4,
                    decoration: fieldDecoration(hint: 'Add details, links, or notes...'),
                  ),
                  const SizedBox(height: 18),
                  if (_isEdit)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [_label('', 'Due Date'), _dateField()],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [_label('', 'Course Bucket'), _courseDropdown()],
                          ),
                        ),
                      ],
                    )
                  else ...[
                    const FieldLabel('Due date'),
                    _dateField(),
                  ],
                  const SizedBox(height: 18),
                  _label('Priority', 'Priority'),
                  _isEdit ? _prioritySegment() : _priorityChips(),
                  if (_isEdit) ...[
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Completed',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                SizedBox(height: 2),
                                Text('Mark task as done',
                                    style: TextStyle(fontSize: 11, color: AppColors.muted)),
                              ],
                            ),
                          ),
                          Switch(
                            value: _completed,
                            activeColor: AppColors.primary,
                            onChanged: (v) => setState(() => _completed = v),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppButton(
                      label: _isEdit ? 'Save Changes' : 'Save Task',
                      icon: _isEdit ? Icons.check : null,
                      iconFirst: true,
                      color: _isEdit ? AppColors.dark : AppColors.primary,
                      loading: _saving,
                      onPressed: _save,
                    ),
                    const SizedBox(height: 4),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel',
                          style: TextStyle(color: AppColors.muted, fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
