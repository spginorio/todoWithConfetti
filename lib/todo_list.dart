import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:intl/intl.dart';
import 'package:todoapp/main.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';
import 'package:todoapp/add_todo_dialog.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart';
import "package:todoapp/confetti.dart";

class TodoList extends StatefulWidget {
  const TodoList({super.key});

  @override
  TodoListState createState() => TodoListState();
}

class TodoListState extends State<TodoList> {
  List<Todo> _todos = [];
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _loadTodos();
    _requestNotificationPermissions();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 1));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
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
      if (_todos[index].isCompleted) {
        _confettiController.play();
      }
    });
    _saveTodos();
  }

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
    final bgColor = const Color.fromARGB(255, 255, 255, 255);
    final txtColor = const Color.fromARGB(221, 10, 22, 180);
    final smallTxtColor = const Color.fromARGB(193, 53, 52, 52);

//-----------------Text Styles for the PopUp Menu------------------
    TextStyle popUpMenuTextStyle() {
      return TextStyle(
        color: Color.fromARGB(188, 106, 106, 235),
        fontSize: 14.0,
        fontFamily: GoogleFonts.aBeeZee().fontFamily,
      );
    }

//-----------------Scaffold------------------
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
            'Todo List',
            style: GoogleFonts.openSansCondensed(
              decoration: TextDecoration.lineThrough,
              letterSpacing: 3,
              textStyle: TextStyle(
                color: const Color.fromARGB(221, 12, 26, 226),
                fontSize: 29.0,
              ),
            ),
          ),
        ),
        backgroundColor: bgColor,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ListView.builder(
              itemCount: _todos.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: _todos[index].isCompleted
                          ? const Color.fromARGB(29, 143, 143, 143)
                          : const Color.fromARGB(125, 255, 241, 117),
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: Row(
                      children: [
                        Container(
                          child: _todos[index].isCompleted
                              ? Padding(
                                  padding: const EdgeInsets.only(left: 12.0),
                                  child: Icon(Icons.check,
                                      color: const Color.fromARGB(
                                          151, 32, 134, 23),
                                      size: 30.0),
                                )
                              : null,
                        ),
                        Expanded(
                          child: ListTile(
                            title: Text(
                              _todos[index].content.length > 1000
                                  ? '${_todos[index].content.substring(0, 1000)}...'
                                  : _todos[index].content,
                              style: GoogleFonts.caveat(
                                textStyle: TextStyle(
                                  fontSize: 23.0,
                                  fontWeight: FontWeight.w600,
                                  color: _todos[index].isCompleted
                                      ? Colors.grey
                                      : txtColor,
                                ),
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Created: ${DateFormat('yyyy-MM-dd').format(_todos[index].createdAt)}',
                                  style: TextStyle(
                                    color: smallTxtColor,
                                    fontFamily:
                                        GoogleFonts.openSans().fontFamily,
                                    fontSize: 12,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                if (_todos[index].reminderDateTime != null)
                                  Text(
                                    'Reminder: ${DateFormat('yyyy-MM-dd HH:mm').format(_todos[index].reminderDateTime!)}',
                                    style: TextStyle(
                                        color: smallTxtColor,
                                        fontFamily:
                                            GoogleFonts.openSans().fontFamily,
                                        fontSize: 12,
                                        letterSpacing: -0.3),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        GestureDetector(
                          child: Icon(
                            Icons.copy,
                            color: const Color.fromARGB(129, 143, 140, 140),
                            size: 22.0,
                          ),
                          onTap: () {
                            Clipboard.setData(
                                ClipboardData(text: _todos[index].content));
                            ScaffoldMessenger.of(context)
                                .showSnackBar(const SnackBar(
                              content: Text('Copied to Clipboard'),
                            ));
                          },
                        ),

                        // Popup Menu properties for the icon and the menu itself
                        PopupMenuButton<String>(
                          color: Colors.white,
                          elevation: 3,
                          iconColor: const Color.fromARGB(129, 143, 140, 140),
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
                            PopupMenuItem<String>(
                              value: 'delete',
                              child: Text(
                                'Delete',
                                style: popUpMenuTextStyle(),
                              ),
                            ),
                            PopupMenuItem<String>(
                              value: 'edit',
                              child: Text(
                                'Edit',
                                style: popUpMenuTextStyle(),
                              ),
                            ),
                            PopupMenuItem<String>(
                              value: 'complete',
                              child: Text(
                                _todos[index].isCompleted
                                    ? 'Mark as Incomplete'
                                    : 'Mark as Complete',
                                style: popUpMenuTextStyle(),
                              ),
                            ),
                            PopupMenuItem<String>(
                              value: 'reminder',
                              child: Text(
                                'Set Reminder',
                                style: popUpMenuTextStyle(),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              blastDirection: 180, // straight up
              emissionFrequency: 0.2,
              numberOfParticles: 25,
              maxBlastForce: 40,
              minBlastForce: 20,
              gravity: 0.2,
              shouldLoop: false,
              colors: const [
                Color.fromARGB(255, 19, 168, 51),
                Color.fromARGB(255, 68, 70, 230),
                Color.fromARGB(255, 255, 230, 0),
                Color.fromARGB(255, 233, 100, 100),
                Color.fromARGB(255, 239, 116, 255),
                Color.fromARGB(255, 240, 147, 7),
              ],

              createParticlePath: drawStar,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTodo,
        child: const Icon(Icons.add),
      ),
      backgroundColor: bgColor,
    );
  }
}
