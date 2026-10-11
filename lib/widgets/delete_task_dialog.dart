import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/task.dart';
import '../theme.dart';

/// Delete confirmation dialog (matches the "Delete Confirmation" Figma screen).
/// Returns true if the user confirmed.
Future<bool> confirmDeleteTask(BuildContext context, Task task) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(
              radius: 24,
              backgroundColor: Color(0xFFFEE2E2),
              child: Icon(Icons.delete_outline, color: AppColors.high),
            ),
            const SizedBox(height: 16),
            const Text('Delete Task?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.dark)),
            const SizedBox(height: 8),
            const Text(
              'Are you sure you want to remove this task?\nThis action cannot be undone.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.muted, height: 1.4),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (task.course.isNotEmpty)
                        Text(task.course,
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary)),
                      const Spacer(),
                      PriorityTag(task.priority, label: '${task.priority} Priority'),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(task.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.hint),
                      const SizedBox(width: 4),
                      Text('Due ${DateFormat('MMM d, yyyy').format(task.dueDate)}',
                          style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            AppButton(
              label: 'Delete Task',
              icon: Icons.delete_outline,
              iconFirst: true,
              color: AppColors.high,
              onPressed: () => Navigator.pop(ctx, true),
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel', style: TextStyle(color: AppColors.dark)),
            ),
          ],
        ),
      ),
    ),
  );
  return result ?? false;
}
