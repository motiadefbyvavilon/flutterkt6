import 'package:flutter/material.dart';

import '../models/task.dart';

Future<({String title, int priority})?> showTaskDialog(
  BuildContext context, {
  Task? initial,
}) {
  final controller = TextEditingController(text: initial?.title ?? '');
  var priority = initial?.priority ?? 1;

  return showDialog<({String title, int priority})>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSt) => AlertDialog(
        title: Text(initial == null ? 'Новая задача' : 'Редактировать'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Текст задачи'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: priority,
              decoration: const InputDecoration(labelText: 'Важность'),
              items: const [
                DropdownMenuItem(value: 0, child: Text('Низкая')),
                DropdownMenuItem(value: 1, child: Text('Средняя')),
                DropdownMenuItem(value: 2, child: Text('Высокая')),
              ],
              onChanged: (v) => setSt(() => priority = v ?? 1),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isEmpty) return;
              Navigator.pop(ctx, (title: text, priority: priority));
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    ),
  );
}
