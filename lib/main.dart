import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(TodoApp());
}

class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Todo App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: TodoList(),
    );
  }
}

class Todo {
  String content;
  DateTime createdAt;
  bool isCompleted;

  Todo(
      {required this.content,
      required this.createdAt,
      this.isCompleted = false});
}

class TodoList extends StatefulWidget {
  const TodoList({super.key});

  @override
  _TodoListState createState() => _TodoListState();
}

class _TodoListState extends State<TodoList> {
  final List<Todo> _todos = [];

  void _addTodo() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AddTodoDialog(),
    );
    if (result != null && result.isNotEmpty) {
      setState(() {
        _todos.add(Todo(content: result, createdAt: DateTime.now()));
      });
    }
  }

  void _deleteTodo(int index) {
    setState(() {
      _todos.removeAt(index);
    });
  }

  void _editTodo(int index) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AddTodoDialog(initialValue: _todos[index].content),
    );
    if (result != null && result.isNotEmpty) {
      setState(() {
        _todos[index].content = result;
      });
    }
  }

  void _setReminder(int index) {
    // Implement reminder functionality here
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Reminder set for todo ${index + 1}')),
    );
  }

  void _toggleComplete(int index) {
    setState(() {
      _todos[index].isCompleted = !_todos[index].isCompleted;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Todo List'),
      ),
      body: ListView.builder(
        itemCount: _todos.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(
              _todos[index].content.length > 20
                  ? '${_todos[index].content.substring(0, 20)}...'
                  : _todos[index].content,
              style: TextStyle(
                decoration: _todos[index].isCompleted
                    ? TextDecoration.lineThrough
                    : null,
              ),
            ),
            subtitle:
                Text(DateFormat('yyyy-MM-dd').format(_todos[index].createdAt)),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'delete':
                    _deleteTodo(index);
                    break;
                  case 'edit':
                    _editTodo(index);
                    break;
                  case 'reminder':
                    _setReminder(index);
                    break;
                  case 'complete':
                    _toggleComplete(index);
                    break;
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: Text('Delete'),
                ),
                const PopupMenuItem<String>(
                  value: 'edit',
                  child: Text('Edit'),
                ),
                const PopupMenuItem<String>(
                  value: 'reminder',
                  child: Text('Set Reminder'),
                ),
                PopupMenuItem<String>(
                  value: 'complete',
                  child: Text(_todos[index].isCompleted
                      ? 'Mark as Incomplete'
                      : 'Mark as Complete'),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTodo,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class AddTodoDialog extends StatefulWidget {
  final String? initialValue;

  const AddTodoDialog({super.key, this.initialValue});

  @override
  _AddTodoDialogState createState() => _AddTodoDialogState();
}

class _AddTodoDialogState extends State<AddTodoDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialValue == null ? 'Add Todo' : 'Edit Todo'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(hintText: 'Enter todo'),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('CANCEL'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        TextButton(
          child: const Text('OK'),
          onPressed: () => Navigator.of(context).pop(_controller.text),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
