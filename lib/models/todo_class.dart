import 'package:flutter/material.dart';

class Todo {
  String content;
  DateTime createdAt;
  bool isCompleted;
  DateTime? reminderDateTime;
  IconData? icon;

  Todo({
    required this.content,
    required this.createdAt,
    this.isCompleted = false,
    this.reminderDateTime,
    this.icon,
  });

  // Convert the Todo object into a JSON map.
  //
  // keys:
  // content: the content of the Todo
  // createdAt: the ISO8601-formatted string of the Todo's creation time
  // isCompleted: a boolean indicating whether the Todo is completed
  // reminderDateTime: the ISO8601-formatted string of the Todo's reminder
  // time, or null if there is no reminder.
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
