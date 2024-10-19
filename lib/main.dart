import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  tz.initializeTimeZones();

  var initializationSettingsAndroid =
      const AndroidInitializationSettings('app_icon');
  var initializationSettingsDarwin = const DarwinInitializationSettings();
  var initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin);

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  runApp(const TodoApp());
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
  DateTime? reminderDateTime;

  Todo({
    required this.content,
    required this.createdAt,
    this.isCompleted = false,
    this.reminderDateTime,
  });
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

  void _setReminder(int index) async {
    DatePicker.showDateTimePicker(
      context,
      showTitleActions: true,
      minTime: DateTime.now(),
      maxTime: DateTime.now().add(const Duration(days: 365)),
      onConfirm: (date) {
        setState(() {
          _todos[index].reminderDateTime = date;
        });
        _scheduleNotification(_todos[index], index);
      },
      currentTime: DateTime.now(),
    );
  }

  Future<void> _scheduleNotification(Todo todo, int index) async {
    var androidNotificationDetails = const AndroidNotificationDetails(
      'todo_reminders',
      'Todo Reminders',
      channelDescription: 'Channel for Todo app reminders',
      importance: Importance.max,
      priority: Priority.high,
    );
    var iosNotificationDetails = const DarwinNotificationDetails();
    var notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: iosNotificationDetails,
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      index,
      'Todo Reminder',
      todo.content,
      tz.TZDateTime.from(todo.reminderDateTime!, tz.local),
      notificationDetails,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
              'Reminder set for ${DateFormat('yyyy-MM-dd HH:mm').format(todo.reminderDateTime!)}')),
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
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    'Created: ${DateFormat('yyyy-MM-dd').format(_todos[index].createdAt)}'),
                if (_todos[index].reminderDateTime != null)
                  Text(
                      'Reminder: ${DateFormat('yyyy-MM-dd HH:mm').format(_todos[index].reminderDateTime!)}'),
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
