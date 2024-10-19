import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AwesomeNotifications().initialize(
    null,
    [
      NotificationChannel(
        channelKey: 'scheduled_channel',
        channelName: 'Scheduled Notifications',
        channelDescription: 'Notifications for scheduled todos',
        defaultColor: Colors.blue,
        ledColor: Colors.blue,
        importance: NotificationImportance.High,
      ),
    ],
  );
  runApp(const TodoApp());
}

class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Todo App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const TodoList(),
    );
  }
}

class Todo {
  String content;
  DateTime createdAt;
  bool isCompleted;
  DateTime? reminderDateTime;

  Todo({
    required this.content,
    required this.createdAt,
    this.isCompleted = false,
    this.reminderDateTime,
  });

  Map<String, dynamic> toJson() => {
        'content': content,
        'createdAt': createdAt.toIso8601String(),
        'isCompleted': isCompleted,
        'reminderDateTime': reminderDateTime?.toIso8601String(),
      };

  factory Todo.fromJson(Map<String, dynamic> json) => Todo(
        content: json['content'],
        createdAt: DateTime.parse(json['createdAt']),
        isCompleted: json['isCompleted'],
        reminderDateTime: json['reminderDateTime'] != null
            ? DateTime.parse(json['reminderDateTime'])
            : null,
      );
}

class TodoList extends StatefulWidget {
  const TodoList({super.key});

  @override
  TodoListState createState() => TodoListState();
}

class TodoListState extends State<TodoList> {
  List<Todo> _todos = [];

  @override
  void initState() {
    super.initState();
    _loadTodos();
    _requestNotificationPermissions();
  }

  void _requestNotificationPermissions() async {
    await AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });
  }

  void _loadTodos() async {
    final prefs = await SharedPreferences.getInstance();
    final String? todosJson = prefs.getString('todos');
    if (todosJson != null) {
      final List<dynamic> decodedJson = jsonDecode(todosJson);
      setState(() {
        _todos = decodedJson.map((item) => Todo.fromJson(item)).toList();
      });
    }
  }

  void _saveTodos() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedTodos =
        jsonEncode(_todos.map((todo) => todo.toJson()).toList());
    await prefs.setString('todos', encodedTodos);
  }

  void _addTodo() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => const AddTodoDialog(),
    );
    if (result != null && result.isNotEmpty) {
      setState(() {
        _todos.add(Todo(content: result, createdAt: DateTime.now()));
      });
      _saveTodos();
    }
  }

  void _deleteTodo(int index) {
    setState(() {
      _todos.removeAt(index);
    });
    _saveTodos();
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
      _saveTodos();
    }
  }

  void _toggleComplete(int index) {
    setState(() {
      _todos[index].isCompleted = !_todos[index].isCompleted;
    });
    _saveTodos();
  }

  void _setReminder(int index) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (pickedTime != null) {
        final DateTime reminderDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        setState(() {
          _todos[index].reminderDateTime = reminderDateTime;
        });
        _saveTodos();
        _scheduleNotification(_todos[index]);
      }
    }
  }

  void _scheduleNotification(Todo todo) async {
    if (todo.reminderDateTime != null) {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: todo.hashCode,
          channelKey: 'scheduled_channel',
          title: 'Todo Reminder',
          body: todo.content,
        ),
        schedule: NotificationCalendar.fromDate(date: todo.reminderDateTime!),
      );
    }
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
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Created: ${DateFormat('yyyy-MM-dd').format(_todos[index].createdAt)}',
                ),
                if (_todos[index].reminderDateTime != null)
                  Text(
                    'Reminder: ${DateFormat('yyyy-MM-dd HH:mm').format(_todos[index].reminderDateTime!)}',
                  ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'delete':
                    _deleteTodo(index);
                    break;
                  case 'edit':
                    _editTodo(index);
                    break;
                  case 'complete':
                    _toggleComplete(index);
                    break;
                  case 'reminder':
                    _setReminder(index);
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
                PopupMenuItem<String>(
                  value: 'complete',
                  child: Text(_todos[index].isCompleted
                      ? 'Mark as Incomplete'
                      : 'Mark as Complete'),
                ),
                const PopupMenuItem<String>(
                  value: 'reminder',
                  child: Text('Set Reminder'),
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
