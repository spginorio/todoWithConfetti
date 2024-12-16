import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:intl/intl.dart';
import 'package:todoapp/models/todo_class.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';
import 'package:todoapp/widgets/add_todo_dialog.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart';
import "package:todoapp/animations/confetti.dart";

class TodoList extends StatefulWidget {
  const TodoList({super.key});

  @override
  TodoListState createState() => TodoListState();
}

// list of todos
class TodoListState extends State<TodoList> {
  List<Todo> _todos = [];

  //confetti controller
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _loadTodos();
    _requestNotificationPermissions();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 1));
    // Load the saved text style preference
    _loadTextStylePreference();
  }

  // Loads the user saved text style preference from SharedPreferences.
  // If the user has previously saved a preference, it will be loaded and
  // used to update the UI. Otherwise the default text style will be used.
  void _loadTextStylePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final bool? savedStyle = prefs.getBool('isHandWrittenStyle');
    if (savedStyle != null) {
      setState(() {
        isHandWrittenStyle = savedStyle;
      });
    }
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
    //delets the notification for the todo if it exists
    if (_todos[index].reminderDateTime != null) {
      AwesomeNotifications().cancel(_todos[index].hashCode);
    }

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

  // Displays a date and time picker dialog to set a reminder for a todo item.
  // the flutter_datetime_picker_plus looks better and is easier to use.
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

  /* Schedule a notification for the [Todo] item at the scheduled time.
   If the todo item has no reminder date, no notification is scheduled.

   The notification is given an ID that is the hashcode of the todo item, so
  that if the user changes the reminder date for the todo item and then
   schedules the notification again, the previous notification is canceled.

   The notification is scheduled on the channel with key 'scheduled_channel'.
  */
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

  // Toggle the text style between handwritten and computer format
  bool isHandWrittenStyle = true;
  void toggleTextStyle() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isHandWrittenStyle = !isHandWrittenStyle;
    });
    // Save the current text style choice to SharedPreferences
    await prefs.setBool('isHandWrittenStyle', isHandWrittenStyle);
  }

  //Copy to clipboard
  void _copyToClipboard(int index) {
    Clipboard.setData(ClipboardData(text: _todos[index].content));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color.fromARGB(255, 255, 255, 255),
        content: Center(
            child: Text(
          'Copied to clipboard!',
          style: TextStyle(color: Color.fromARGB(255, 106, 121, 189)),
        )),
        duration: Duration(milliseconds: 1300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
//!-----------------Colors text------------------
    final bgColor = const Color.fromARGB(255, 255, 255, 255);
    final txtColor = const Color.fromARGB(221, 10, 22, 180);
    final smallTxtColor = const Color.fromARGB(193, 53, 52, 52);

//!-----------------Text Styles for the PopUp Menu------------------
    TextStyle popUpMenuTextStyle() {
      return TextStyle(
        color: Color.fromARGB(188, 106, 106, 235),
        fontSize: 14.0,
        fontFamily: GoogleFonts.aBeeZee().fontFamily,
      );
    }

//!-----------------Text Styles Fonts for the Todo List------------------
    var todosTextStyleHandWritten =
        GoogleFonts.caveat(fontWeight: FontWeight.w600, wordSpacing: 2.0);
    var todosTextStyleCompFormat = GoogleFonts.roboto(
      fontWeight: FontWeight.normal,
      fontSize: 18.0,
      letterSpacing: 0.3,
    );

//!-----------------Scaffold---------------------------------------
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
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
        backgroundColor: bgColor,
        actions: [
          //! POPUP MENU
          Padding(
            padding: const EdgeInsets.only(right: 8.0, top: 8.0),
            child: PopupMenuButton<String>(
              color: const Color.fromARGB(255, 255, 255, 255),
              iconColor: const Color.fromARGB(255, 189, 189, 189),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
              icon: const Icon(
                Icons.menu_rounded,
                size: 22,
              ),
              elevation: 5,
              iconSize: 27,
              onSelected: (value) {
                // Handle menu item selection
                if (value == 'Reset') {
                  toggleTextStyle();
                } else if (value == 'Option 2') {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      //! ALERT DIALOG
                      return AlertDialog(
                        scrollable: true,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        title: Text(
                          'About this app: ',
                          style: TextStyle(
                            color: const Color.fromARGB(255, 117, 116, 116),
                            fontSize: 20.0,
                          ),
                        ),
                        content: GestureDetector(
                          onTap: () {
                            // Dismiss the dialog when tapped anywhere inside it
                            Navigator.pop(context);
                          },
                          child: Text(
                            '''A simple to-do/notes app that celebrates with confetti across your screen when you mark a task as completed.\n  \nYou can set reminders, edit or update your to-dos, change the font, copy the content to your clipboard and long-press to drag and rearrange tasks.\n  \nMore features will be added in future updates.\n \nThank you for using this app!''',
                            style: TextStyle(
                                color:
                                    const Color.fromARGB(255, 117, 115, 115)),
                          ),
                        ),
                      );
                    },
                  );
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                PopupMenuItem<String>(
                  value: 'Reset',
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 10.0),
                        child: Icon(
                          Icons.compare_arrows_rounded,
                          color: const Color.fromARGB(255, 198, 198, 198),
                        ),
                      ),
                      Text('Font Style',
                          style: TextStyle(
                            color: const Color.fromARGB(255, 148, 148, 148),
                          )),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'Option 2',
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 4.0, right: 10.0),
                        child: Icon(Icons.info_outlined,
                            color: const Color.fromARGB(255, 198, 198, 198),
                            size: 20),
                      ),
                      Text('About',
                          style: TextStyle(
                            color: const Color.fromARGB(255, 148, 148, 148),
                          )),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 60),
            child: ReorderableListView.builder(
              itemCount: _todos.length,
              itemBuilder: (context, index) {
                return Padding(
                  key: ValueKey(_todos[index].hashCode),
                  padding: const EdgeInsets.all(5.0),
                  // Wrap the ListTile in a GestureDetector to detect long press
                  // and copy the todo content to the clipboard
                  child: Container(
                    decoration: BoxDecoration(
                      color: _todos[index].isCompleted
                          ? const Color.fromARGB(29, 143, 143, 143)
                          : const Color.fromARGB(125, 255, 241, 117),
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: Row(
                      children: [
                        // Add a checkmark icon if the todo is completed
                        Container(
                          child: _todos[index].isCompleted
                              ? Padding(
                                  padding: const EdgeInsets.only(left: 12.0),
                                  child: Icon(Icons.check_rounded,
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
                              style: isHandWrittenStyle
                                  ? todosTextStyleHandWritten.copyWith(
                                      fontSize: 25.0,
                                      color: _todos[index].isCompleted
                                          ? Colors.grey
                                          : txtColor,
                                    )
                                  : todosTextStyleCompFormat.copyWith(
                                      color: _todos[index].isCompleted
                                          ? Colors.grey
                                          : txtColor,
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
                        // Popup Menu properties for the icon and the menu itself
                        PopupMenuButton<String>(
                          color: Colors.white,
                          elevation: 3,
                          iconColor: const Color.fromARGB(129, 143, 140, 140),
                          onSelected: (value) {
                            switch (value) {
                              case 'delete':
                                deleteWithConfirmation(context, index);
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
                              case 'copy':
                                _copyToClipboard(index);
                                break;
                            }
                          },
                          itemBuilder: (BuildContext context) =>
                              <PopupMenuEntry<String>>[
                            PopupMenuItem<String>(
                                value: 'copy',
                                child: Text(
                                  "Copy",
                                  style: popUpMenuTextStyle(),
                                )),
                            PopupMenuItem<String>(
                              value: 'edit',
                              child: Text(
                                'Edit',
                                style: popUpMenuTextStyle(),
                              ),
                            ),
                            PopupMenuItem<String>(
                              value: 'delete',
                              child: Text(
                                'Delete',
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
              onReorder: (int oldIndex, int newIndex) {
                setState(() {
                  // Adjust newIndex if dragging an item from earlier to later position
                  if (oldIndex < newIndex) {
                    newIndex -= 1;
                  }

                  // Remove the item from the old position
                  final Todo item = _todos.removeAt(oldIndex);

                  // Insert the item at the new position
                  _todos.insert(newIndex, item);

                  // Save the updated todo list order
                  _saveTodos();
                });
              },
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            //------------------Confetti widget------------------
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

  /// Shows an alert dialog to confirm the deletion of a todo at [index].
  ///
  /// The dialog displays the title "Delete Todo:" and two buttons: "Cancel" and
  /// "Delete". The "Cancel" button simply closes the dialog when pressed.
  /// The "Delete" button calls [_deleteTodo] with [index] and then closes the
  /// dialog.
  ///
  /// Returns a [Future] that resolves when the dialog is closed.
  ///
  /// See also:
  ///
  ///  [_deleteTodo], which is called when the "Delete" button is pressed.
  Future<dynamic> deleteWithConfirmation(BuildContext context, int index) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Center(
          child: Text(
            'Delete To-do:',
            style: TextStyle(
              color: const Color.fromARGB(255, 210, 138, 133),
            ),
          ),
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Cancel',
                ),
              ),
              TextButton(
                onPressed: () {
                  _deleteTodo(index);
                  Navigator.of(context).pop();
                },
                child: Text(
                  'Delete',
                  style: TextStyle(
                      color: const Color.fromARGB(255, 228, 115, 107)),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
