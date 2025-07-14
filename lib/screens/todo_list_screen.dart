import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TaskStatus { incomplete, complete }

class TodoListScreen extends StatefulWidget {
  const TodoListScreen({super.key});

  @override
  State<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  final TextEditingController _taskController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<Map<String, dynamic>> _tasks = [];

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  @override
  void dispose() {
    _taskController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? tasksString = prefs.getStringList('tasks');
    if (tasksString != null) {
      setState(() {
        _tasks = tasksString
            .map((e) => Map<String, dynamic>.from(_decodeTask(e)))
            .toList();
      });
    }
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> tasksString = _tasks.map((e) => _encodeTask(e)).toList();
    await prefs.setStringList('tasks', tasksString);
  }

  Map<String, dynamic> _decodeTask(String s) {
    final parts = s.split('|');
    return {
      'title': parts[0],
      'status': parts[1] == '1' ? TaskStatus.complete : TaskStatus.incomplete,
    };
  }

  String _encodeTask(Map<String, dynamic> task) {
    return '${task['title']}|${task['status'] == TaskStatus.complete ? '1' : '0'}';
  }

  void _addTask() {
    final text = _taskController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _tasks.add({'title': text, 'status': TaskStatus.incomplete});
        _taskController.clear();
      });
      _saveTasks();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task added!'),
          duration: Duration(milliseconds: 800),
        ),
      );
      _focusNode.requestFocus();
    }
  }

  void _deleteTask(int index) {
    setState(() {
      _tasks.removeAt(index);
    });
    _saveTasks();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Task deleted!'),
        duration: Duration(milliseconds: 800),
      ),
    );
  }

  void _toggleComplete(int index) {
    setState(() {
      _tasks[index]['status'] = _tasks[index]['status'] == TaskStatus.complete
          ? TaskStatus.incomplete
          : TaskStatus.complete;
    });
    _saveTasks();
  }

  void _clearAllTasks() {
    setState(() {
      _tasks.clear();
    });
    _saveTasks();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All tasks cleared!'),
        duration: Duration(milliseconds: 800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('To-Do List'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Clear All',
            onPressed: _tasks.isNotEmpty ? _clearAllTasks : null,
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF283593), Color(0xFF5C6BC0), Color(0xFF90CAF9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _taskController,
                      focusNode: _focusNode,
                      decoration: InputDecoration(
                        labelText: 'Add a task',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.95),
                      ),
                      onSubmitted: (_) => _addTask(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: const Color(0xFF283593),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _addTask,
                      child: const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: Icon(Icons.add, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _tasks.isEmpty
                  ? const Center(
                      child: Text(
                        'No tasks yet.',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    )
                  : ListView.separated(
                      itemCount: _tasks.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemBuilder: (context, index) {
                        final task = _tasks[index];
                        return Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          color: Colors.white.withOpacity(0.95),
                          child: ListTile(
                            leading: IconButton(
                              icon: Icon(
                                task['status'] == TaskStatus.complete
                                    ? Icons.check_box
                                    : Icons.check_box_outline_blank,
                                color: task['status'] == TaskStatus.complete
                                    ? Colors.green
                                    : const Color(0xFF283593),
                              ),
                              onPressed: () => _toggleComplete(index),
                            ),
                            title: Text(
                              task['title'],
                              style: TextStyle(
                                fontSize: 18,
                                decoration:
                                    task['status'] == TaskStatus.complete
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: task['status'] == TaskStatus.complete
                                    ? Colors.grey
                                    : const Color(0xFF283593),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteTask(index),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTask,
        backgroundColor: const Color(0xFF283593),
        child: const Icon(Icons.add),
        tooltip: 'Add Task',
      ),
    );
  }
}
