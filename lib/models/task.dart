import 'package:cloud_firestore/cloud_firestore.dart';

class Task {
  final String id;
  final String title;
  final String description;
  final DateTime dueDate;
  final String priority; // Low, Medium, High
  final bool isCompleted;
  final DateTime createdAt;
  final String course; // optional "Course Bucket" from the Figma edit screen

  const Task({
    this.id = '',
    required this.title,
    required this.description,
    required this.dueDate,
    required this.priority,
    this.isCompleted = false,
    required this.createdAt,
    this.course = '',
  });

  factory Task.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data()!;
    return Task(
      id: doc.id,
      title: m['title'] ?? '',
      description: m['description'] ?? '',
      dueDate: (m['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      priority: m['priority'] ?? 'Medium',
      isCompleted: m['isCompleted'] ?? false,
      createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      course: m['course'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'description': description,
        'dueDate': Timestamp.fromDate(dueDate),
        'priority': priority,
        'isCompleted': isCompleted,
        'createdAt': Timestamp.fromDate(createdAt),
        'course': course,
      };
}
