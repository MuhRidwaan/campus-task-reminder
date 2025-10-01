import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:icalendar_parser/icalendar_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';

enum TaskFilter { all, upcoming, completed, overdue }

class TaskProvider with ChangeNotifier {
  List<Map<String, dynamic>> _tasks = [];
  Map<String, String> _courseNames = {};
  bool _isLoading = true;
  String? _error;
  Set<String> _completedTaskUids = {};
  TaskFilter _currentFilter = TaskFilter.upcoming;
  bool _isOffline = false;
  String _icsUrl = '';

  List<Map<String, dynamic>> get allTasks => _tasks;
  List<Map<String, dynamic>> get tasks {
    switch (_currentFilter) {
      case TaskFilter.upcoming:
        return _tasks.where((task) {
          final deadline = getDateTimeFromTask(task);
          return deadline != null && deadline.isAfter(DateTime.now()) && !_completedTaskUids.contains(task['uid']);
        }).toList();
      case TaskFilter.completed:
        return _tasks.where((task) => _completedTaskUids.contains(task['uid'])).toList();
      case TaskFilter.overdue:
        return _tasks.where((task) {
          final deadline = getDateTimeFromTask(task);
          return deadline != null && deadline.isBefore(DateTime.now()) && !_completedTaskUids.contains(task['uid']);
        }).toList();
      case TaskFilter.all:
      default:
        return _tasks;
    }
  }

  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isOffline => _isOffline;
  TaskFilter get currentFilter => _currentFilter;
  Map<String, String> get courseNames => _courseNames;
  Set<String> get uniqueCategories {
    final categories = <String>{};
    for (var task in _tasks) {
      final dynamic cats = task['categories'];
      if (cats is List) {
        categories.addAll(cats.whereType<String>());
      } else if (cats is String) {
        categories.add(cats);
      }
    }
    return categories;
  }

  TaskProvider() {
    _loadCompletedTasks();
  }

  // REVISI: Tambahkan error handling yang lebih kuat
  Future<void> loadInitialData(String url) async {
    _icsUrl = url;
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('task_cache');

      if (cachedData != null) {
        parseAndSetTasks(cachedData);
      }
    } catch (e) {
      _error = "Gagal memuat data cache: $e";
    } finally {
      // Apapun yang terjadi, pastikan spinner awal dimatikan
      _isLoading = false;
      notifyListeners();
    }

    // Setelah UI awal ditampilkan, ambil data baru dari server
    await refreshTasksFromServer();
  }

  Future<void> refreshTasksFromServer() async {
    if (_icsUrl.isEmpty) return;

    _isOffline = false;
    _error = null;
    notifyListeners(); // Beri tahu UI bahwa proses refresh dimulai

    try {
      final response = await http.get(Uri.parse(_icsUrl));
      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        final cachedData = prefs.getString('task_cache');

        if (response.body != cachedData) {
          await prefs.setString('task_cache', response.body);
          parseAndSetTasks(response.body);
        }
      } else {
        throw Exception('Gagal memuat: Status ${response.statusCode}');
      }
    } catch (e) {
      _isOffline = true;
      _error = 'Gagal memperbarui. Menampilkan data offline.';
      notifyListeners();
    }
  }


  void parseAndSetTasks(String icsData) {
    final iCalendar = ICalendar.fromString(icsData);
    final newTasks = (iCalendar.data).cast<Map<String, dynamic>>();

    newTasks.sort((a, b) {
      final DateTime aDate = getDateTimeFromTask(a) ?? DateTime(0);
      final DateTime bDate = getDateTimeFromTask(b) ?? DateTime(0);
      return aDate.compareTo(bDate);
    });

    _tasks = newTasks;
    loadCourseNames();
    NotificationService.scheduleAllNotifications(_tasks);
    notifyListeners();
  }

  Future<void> loadCourseNames() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, String> loadedNames = {};
    for (var category in uniqueCategories) {
      final savedName = prefs.getString('course_name_$category');
      if (savedName != null && savedName.isNotEmpty) {
        loadedNames[category] = savedName;
      }
    }
    _courseNames = loadedNames;
    notifyListeners();
  }

  void setFilter(TaskFilter filter) {
    _currentFilter = filter;
    notifyListeners();
  }

  Future<void> _loadCompletedTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final completed = prefs.getStringList('completed_tasks') ?? [];
    _completedTaskUids = completed.toSet();
    notifyListeners();
  }

  Future<void> toggleTaskCompletion(String uid) async {
    if (_completedTaskUids.contains(uid)) {
      _completedTaskUids.remove(uid);
    } else {
      _completedTaskUids.add(uid);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('completed_tasks', _completedTaskUids.toList());
    notifyListeners();
  }

  bool isTaskCompleted(String uid) {
    return _completedTaskUids.contains(uid);
  }

  DateTime? getDateTimeFromTask(Map<String, dynamic> task) {
    final dynamic dtValue = task['dtstart'];
    if (dtValue is IcsDateTime) {
      final dtString = dtValue.dt;
      if (dtString is String) {
        return DateTime.tryParse(dtString);
      }
    }
    return null;
  }
}

