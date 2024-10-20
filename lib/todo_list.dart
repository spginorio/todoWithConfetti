import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:intl/intl.dart';
import 'package:todoapp/main.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';
import 'package:todoapp/add_todo_dialog.dart';
import 'package:google_fonts/google_fonts.dart';

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

  /// Shows a date time picker dialog to set a reminder date and time
  /// for the todo at [index].
  ///
  /// When the user selects a date and time, the todo at [index] is updated
  /// with that date and time, and a notification is scheduled for that
  /// date and time.
  void _setReminder(int index) {
    dateTimePicker(index);
  }

  Future<DateTime?> dateTimePicker(int index) {
    return DatePicker.showDateTimePicker(
      context,
      showTitleActions: true,
      minTime: DateTime.now(),
      maxTime: DateTime.now().add(const Duration(days: 365)),
      onConfirm: (date) {
        setState(() {
          _todos[index].reminderDateTime = date;
        });
        _saveTodos();
        _scheduleNotification(_todos[index]);
      },
      currentTime: DateTime.now(),
    );
  }

  /// Schedule a notification for the provided todo if a reminder date and time is set.
  ///
  /// If the reminder date and time for the todo is not null, this function creates a notification
  /// with the todo details to remind the user about the task.
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

  final bgColor = const Color.fromARGB(255, 255, 255, 255);
  final txtColor = const Color.fromARGB(255, 0, 0, 0);
  final smallTxtColor = const Color.fromARGB(255, 53, 52, 52);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Center(
            child: Text(
              'Todo List',
              style: GoogleFonts.russoOne(
                //TODO: adjust font
                textStyle: TextStyle(
                  color: const Color.fromARGB(
                      117, 108, 150, 146), //TODO: adjust color
                  fontSize: 39.0,
                ),
              ),
            ),
          ),
          backgroundColor: bgColor,
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ListView.builder(
            itemCount: _todos.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.all(5.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: _todos[index]
                            .isCompleted //TODO: Change Box Color when Completed
                        ? const Color.fromARGB(96, 167, 199, 177)
                        : const Color.fromARGB(88, 161, 193, 224),
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: ListTile(
                    title: Text(
                      _todos[index].content.length > 69
                          ? '${_todos[index].content.substring(0, 69)}...'
                          : _todos[index].content,
                      //STYLE Font for List Items
                      style: GoogleFonts.openSans(
                        //TODO: adjust font
                        textStyle: TextStyle(
                          fontSize: 21.0,
                          fontWeight: FontWeight.w600,
                          color: txtColor,
                          decoration: _todos[index].isCompleted
                              //TODO: Change text Color when Completed
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Created: ${DateFormat('yyyy-MM-dd').format(_todos[index].createdAt)}',
                          style: TextStyle(
                            //CREATED color
                            color: smallTxtColor,
                          ),
                        ),
                        if (_todos[index].reminderDateTime != null)
                          Text(
                            'Reminder: ${DateFormat('yyyy-MM-dd HH:mm').format(_todos[index].reminderDateTime!)}',
                            style: TextStyle(
                              //REMINDER color
                              color: smallTxtColor,
                            ),
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
                      itemBuilder: (BuildContext context) =>
                          <PopupMenuEntry<String>>[
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
                  ),
                ),
              );
            },
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _addTodo,
          child: const Icon(Icons.add),
        ),
        //BACKGROUND COLOR
        backgroundColor: bgColor);
  }
}
