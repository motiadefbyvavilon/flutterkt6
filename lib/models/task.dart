import 'dart:convert';

class Task {
  String title;
  bool done;
  int priority;

  Task(this.title, {this.done = false, this.priority = 1});

  Map<String, dynamic> toJson() => {
        'title': title,
        'done': done,
        'priority': priority,
      };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        json['title'] as String,
        done: json['done'] as bool? ?? false,
        priority: json['priority'] as int? ?? 1,
      );

  static String encode(List<Task> tasks) =>
      jsonEncode(tasks.map((t) => t.toJson()).toList());

  static List<Task> decode(String raw) {
    final list = jsonDecode(raw) as List;
    return list.map((e) => Task.fromJson(e as Map<String, dynamic>)).toList();
  }
}

enum SortBy { dateNew, priorityHigh, titleAZ }

enum FilterBy { all, active, done }
