import 'package:flutter/material.dart';
import '../constants/neu_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  List<TodoItem> _todaysTasks = [];
  final _taskController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    final tasksJson = prefs.getStringList('tasks_$today') ?? [];
    
    setState(() {
      _todaysTasks = tasksJson
          .map((task) => TodoItem.fromJson(jsonDecode(task)))
          .toList();
    });
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    final tasksJson = _todaysTasks
        .map((task) => jsonEncode(task.toJson()))
        .toList();
    
    await prefs.setStringList('tasks_$today', tasksJson);
  }

  void _addTask() {
    if (_taskController.text.isEmpty || _todaysTasks.any((task) => task.title == _taskController.text)) return;

    setState(() {
      _todaysTasks.add(TodoItem(
        title: _taskController.text,
        isCompleted: false,
      ));
      _taskController.clear();
    });
    _saveTasks();
  }

  void _toggleTask(int index) {
    setState(() {
      _todaysTasks[index].isCompleted = !_todaysTasks[index].isCompleted;
    });
    _saveTasks();
  }

  void _removeTask(int index) {
    setState(() {
      _todaysTasks.removeAt(index);
    });
    _saveTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: NeuConstants.neuBrutalismBoxDecoration(
              color: Colors.white,
            ),
            child: Row(
              children: [
                const Icon(Icons.today, size: 24),
                const SizedBox(width: 12),
                Text(
                  "Today's Tasks",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: NeuConstants.neuBrutalismBoxDecoration(
                    color: NeuConstants.primaryColor,
                    offsetX: 2,
                    offsetY: 2,
                  ),
                  child: Text(
                    '${_todaysTasks.where((task) => task.isCompleted).length}/${_todaysTasks.length}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: NeuConstants.neuBrutalismBoxDecoration(
              color: Colors.white,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _taskController,
                    decoration: const InputDecoration(
                      hintText: 'Add a task for today',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onSubmitted: (_) => _addTask(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addTask,
                  style: IconButton.styleFrom(
                    backgroundColor: NeuConstants.secondaryColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _todaysTasks.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No tasks for today',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: _todaysTasks.length,
                          itemBuilder: (context, index) {
                            final task = _todaysTasks[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Container(
                                decoration: NeuConstants.neuBrutalismBoxDecoration(
                                  color: task.isCompleted
                                      ? Colors.green.shade50
                                      : Colors.white,
                                ),
                                child: ListTile(
                                  leading: IconButton(
                                    icon: Icon(
                                      task.isCompleted
                                          ? Icons.check_circle
                                          : Icons.circle_outlined,
                                      color: task.isCompleted
                                          ? Colors.green
                                          : Colors.grey,
                                    ),
                                    onPressed: () => _toggleTask(index),
                                  ),
                                  title: Text(
                                    task.title,
                                    style: TextStyle(
                                      decoration: task.isCompleted
                                          ? TextDecoration.lineThrough
                                          : null,
                                      color:
                                          task.isCompleted ? Colors.grey : Colors.black,
                                    ),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () => _removeTask(index),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }
}

class TodoItem {
  String title;
  bool isCompleted;

  TodoItem({
    required this.title,
    required this.isCompleted,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'isCompleted': isCompleted,
    };
  }

  factory TodoItem.fromJson(Map<String, dynamic> json) {
    return TodoItem(
      title: json['title'],
      isCompleted: json['isCompleted'],
    );
  }
}