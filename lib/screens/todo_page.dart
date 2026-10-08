import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/task.dart';
import '../services/auth_service.dart';
import '../widgets/task_dialog.dart';
import 'login_screen.dart';

class TodoPage extends StatefulWidget {
  const TodoPage({super.key});

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  static const _storageKey = 'tasks';

  final List<Task> _tasks = [];
  SortBy _sort = SortBy.dateNew;
  FilterBy _filter = FilterBy.all;

  final _auth = AuthService();
  bool get _isLoggedIn => _auth.isLoggedIn;

  // ---------- ЖИЗНЕННЫЙ ЦИКЛ ----------
  @override
  void initState() {
    super.initState();
    _load();
  }

  // ---------- СОХРАНЕНИЕ / ЗАГРУЗКА ----------
  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return;
    setState(() {
      _tasks
        ..clear()
        ..addAll(Task.decode(raw));
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, Task.encode(_tasks));
  }

  // ---------- ПРОВЕРКА АВТОРИЗАЦИИ ----------
  /// Если пользователь не залогинен — показывает диалог с предложением войти.
  /// Если залогинен — выполняет переданное действие.
  void _requireLogin(VoidCallback action) {
    if (!_isLoggedIn) {
      _showLoginPrompt();
      return;
    }
    action();
  }

  void _showLoginPrompt() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Нужен вход'),
        content: const Text(
          'Эта функция доступна только после входа в аккаунт.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _openLogin();
            },
            child: const Text('Войти'),
          ),
        ],
      ),
    );
  }

  void _openLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    ).then((_) => setState(() {})); // обновить экран после возврата
  }

  Future<void> _logout() async {
    await _auth.signOut();
    setState(() {});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Вы вышли из аккаунта')),
      );
    }
  }

  // ---------- ВИДИМЫЙ СПИСОК (фильтр + сортировка) ----------
  List<Task> get _visible {
    var list = _tasks.where((t) {
      if (_filter == FilterBy.active) return !t.done;
      if (_filter == FilterBy.done) return t.done;
      return true;
    }).toList();

    switch (_sort) {
      case SortBy.dateNew:
        break;
      case SortBy.priorityHigh:
        list.sort((a, b) => b.priority.compareTo(a.priority));
        break;
      case SortBy.titleAZ:
        list.sort(
            (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
    }
    return list;
  }

  // ---------- ОПЕРАЦИИ ----------
  Future<void> _addOrEdit([Task? task]) async {
    // Добавление — доступно всем. Редактирование — только залогиненным.
    if (task != null && !_isLoggedIn) {
      _showLoginPrompt();
      return;
    }

    final result = await showTaskDialog(context, initial: task);
    if (result == null) return;

    setState(() {
      if (task == null) {
        _tasks.add(Task(result.title, priority: result.priority));
      } else {
        task.title = result.title;
        task.priority = result.priority;
      }
    });
    await _save();
  }

  Future<void> _toggle(Task t) async {
    setState(() => t.done = !t.done);
    await _save();
  }

  Future<void> _delete(Task t) async {
    final index = _tasks.indexOf(t);
    setState(() => _tasks.remove(t));
    await _save();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Удалено: ${t.title}'),
        action: SnackBarAction(
          label: 'Отменить',
          onPressed: () {
            setState(() => _tasks.insert(index, t));
            _save();
          },
        ),
      ),
    );
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    final visible = _visible;
    final done = _tasks.where((t) => t.done).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Список дел'),
        actions: [
          // Сортировка — только после входа
          PopupMenuButton<SortBy>(
            icon: const Icon(Icons.sort),
            tooltip: 'Сортировка',
            onSelected: (v) => _requireLogin(() => setState(() => _sort = v)),
            itemBuilder: (_) => const [
              PopupMenuItem(
                  value: SortBy.dateNew, child: Text('Сначала новые')),
              PopupMenuItem(
                  value: SortBy.priorityHigh, child: Text('По важности')),
              PopupMenuItem(value: SortBy.titleAZ, child: Text('По алфавиту')),
            ],
          ),

          // Меню пользователя
          PopupMenuButton<String>(
            icon: Icon(
              _isLoggedIn ? Icons.account_circle : Icons.person_outline,
            ),
            tooltip: _isLoggedIn ? 'Аккаунт' : 'Войти',
            onSelected: (v) {
              if (v == 'login') _openLogin();
              if (v == 'logout') _logout();
            },
            itemBuilder: (_) => [
              if (!_isLoggedIn)
                const PopupMenuItem(
                  value: 'login',
                  child: Text('Войти / Зарегистрироваться'),
                )
              else ...[
                PopupMenuItem(
                  enabled: false,
                  child: Text(
                    _auth.currentUser?.email ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'logout',
                  child: Text('Выйти'),
                ),
              ],
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: SegmentedButton<FilterBy>(
              segments: const [
                ButtonSegment(value: FilterBy.all, label: Text('Все')),
                ButtonSegment(value: FilterBy.active, label: Text('Активные')),
                ButtonSegment(value: FilterBy.done, label: Text('Готово')),
              ],
              selected: {_filter},
              onSelectionChanged: (s) => setState(() => _filter = s.first),
            ),
          ),
        ),
      ),
      body: visible.isEmpty
          ? const Center(child: Text('Задач нет'))
          : ListView.builder(
              itemCount: visible.length,
              itemBuilder: (_, i) {
                final t = visible[i];
                return Dismissible(
                  key: ObjectKey(t),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) => _delete(t),
                  child: CheckboxListTile(
                    value: t.done,
                    onChanged: (_) => _toggle(t),
                    title: Text(
                      t.title,
                      style: TextStyle(
                        decoration: t.done ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    subtitle:
                        Text(['Низкая', 'Средняя', 'Высокая'][t.priority]),
                    secondary: IconButton(
                      icon: const Icon(Icons.edit),
                      // Редактирование — только после входа
                      onPressed: () => _addOrEdit(t),
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(8),
        child: Text(
          _isLoggedIn
              ? 'Выполнено $done из ${_tasks.length} • ${_auth.currentUser?.email}'
              : 'Выполнено $done из ${_tasks.length} • Гостевой режим',
          textAlign: TextAlign.center,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEdit(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
