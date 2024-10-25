// add todo dialog once the add button is pressed

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AddTodoDialog extends StatefulWidget {
  final String? initialValue;

  const AddTodoDialog({super.key, this.initialValue});

  @override
  AddTodoDialogState createState() => AddTodoDialogState();
}

class AddTodoDialogState extends State<AddTodoDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Center(
        child: Text(
          widget.initialValue == null ? 'Add Todo' : 'Edit Todo',
          style: GoogleFonts.openSans(
            textStyle: TextStyle(
                color: const Color.fromARGB(255, 49, 190, 148),
                fontSize: 26.0,
                fontWeight: FontWeight.w400,
                letterSpacing: -1),
          ),
        ),
      ),
      content: TextField(
        style: GoogleFonts.openSans(textStyle: const TextStyle(fontSize: 18.0)),
        controller: _controller,
        autofocus: true,
        maxLines: null,
        decoration: const InputDecoration(
            hintText: ' Enter todo..',
            hintStyle: TextStyle(color: Color.fromARGB(69, 110, 110, 110)),
            border: InputBorder.none),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('CANCEL',
              style: TextStyle(color: Color.fromARGB(200, 219, 139, 163))),
          onPressed: () => Navigator.of(context).pop(),
        ),
        TextButton(
          child: const Text('OK',
              style: TextStyle(color: Color.fromARGB(255, 49, 190, 148))),
          onPressed: () => Navigator.of(context).pop(
              _controller.text[0].toUpperCase() +
                  _controller.text.substring(1)),
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
