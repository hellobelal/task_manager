import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/task.dart';

class TaskService {
  CollectionReference<Map<String, dynamic>> get _col => FirebaseFirestore.instance
      .collection('users')
      .doc(FirebaseAuth.instance.currentUser!.uid)
      .collection('tasks');

  Stream<List<Task>> watchTasks() => _col
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(Task.fromDoc).toList());

  Future<void> add(Task t) => _col.add(t.toMap());

  Future<void> update(Task t) => _col.doc(t.id).update(t.toMap());

  Future<void> setCompleted(String id, bool value) =>
      _col.doc(id).update({'isCompleted': value});

  Future<void> delete(String id) => _col.doc(id).delete();

  Future<Task?> getById(String id) async {
    final doc = await _col.doc(id).get();
    return doc.exists ? Task.fromDoc(doc) : null;
  }
}
