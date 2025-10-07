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

  Set<String> _priorityTaskUids = {};
  Set<String> _intensiveStudyUids = {};

  List<Map<String, dynamic>> get allTasks => _tasks;
  Set<String> get priorityTaskUids => _priorityTaskUids;
  Set<String> get intensiveStudyUids => _intensiveStudyUids;

  List<Map<String, dynamic>> get tasks {
    List<Map<String, dynamic>> filteredTasks;
    switch (_currentFilter) {
      case TaskFilter.upcoming:
        filteredTasks = _tasks.where((task) {
          final deadline = getDateTimeFromTask(task);
          return deadline != null && deadline.isAfter(DateTime.now()) && !_completedTaskUids.contains(task['uid']);
        }).toList();
        break;
      case TaskFilter.completed:
        filteredTasks = _tasks.where((task) => _completedTaskUids.contains(task['uid'])).toList();
        break;
      case TaskFilter.overdue:
        filteredTasks = _tasks.where((task) {
          final deadline = getDateTimeFromTask(task);
          return deadline != null && deadline.isBefore(DateTime.now()) && !_completedTaskUids.contains(task['uid']);
        }).toList();
        break;
      case TaskFilter.all:
      default:
        filteredTasks = _tasks;
    }
    filteredTasks.sort((a, b) {
      final isAPriority = _priorityTaskUids.contains(a['uid']);
      final isBPriority = _priorityTaskUids.contains(b['uid']);
      if (isAPriority && !isBPriority) return -1;
      if (!isAPriority && isBPriority) return 1;

      final aDate = getDateTimeFromTask(a) ?? DateTime(0);
      final bDate = getDateTimeFromTask(b) ?? DateTime(0);
      return aDate.compareTo(bDate);
    });
    return filteredTasks;
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
    _loadPriorityTasks();
    _loadIntensiveStudyTasks();
  }

  Future<void> loadInitialData(String url) async {
    _icsUrl = url;
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('task_cache');
      if (cachedData != null) {
        await parseAndSetTasks(cachedData);
      }
    } catch (e) {
      _error = "Gagal memuat data cache: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    await refreshTasksFromServer();
  }

  Future<void> refreshTasksFromServer() async {
    if (_icsUrl.isEmpty) return;
    _isOffline = false;
    _error = null;
    notifyListeners();

    try {
      final response = await http.get(Uri.parse(_icsUrl));
      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        final cachedData = prefs.getString('task_cache');
        if (response.body != cachedData) {
          await prefs.setString('task_cache', response.body);
          await parseAndSetTasks(response.body);
        }
      } else {
        throw Exception('Gagal memuat: Status ${response.statusCode}');
      }
    } catch (e) {
      _isOffline = true;
      _error = 'Gagal memperbarui. Menampilkan data offline.';
    }
    notifyListeners();
  }

  Future<void> parseAndSetTasks(String icsData) async {
    final iCalendar = ICalendar.fromString(icsData);
    final newTasks = (iCalendar.data).cast<Map<String, dynamic>>();

    _tasks = newTasks;
    await loadCourseNames();
    await NotificationService.scheduleAllNotifications(_tasks, _courseNames, _priorityTaskUids, _intensiveStudyUids);
    notifyListeners();
  }

  Future<void> _loadPriorityTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final priority = prefs.getStringList('priority_tasks') ?? [];
    _priorityTaskUids = priority.toSet();
    notifyListeners();
  }

  Future<void> _loadIntensiveStudyTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final intensive = prefs.getStringList('intensive_study_tasks') ?? [];
    _intensiveStudyUids = intensive.toSet();
    notifyListeners();
  }

  Future<void> toggleTaskPriority(String uid) async {
    _priorityTaskUids.contains(uid) ? _priorityTaskUids.remove(uid) : _priorityTaskUids.add(uid);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('priority_tasks', _priorityTaskUids.toList());
    await NotificationService.scheduleAllNotifications(_tasks, _courseNames, _priorityTaskUids, _intensiveStudyUids);
    notifyListeners();
  }

  Future<void> toggleIntensiveStudy(String uid) async {
    _intensiveStudyUids.contains(uid) ? _intensiveStudyUids.remove(uid) : _intensiveStudyUids.add(uid);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('intensive_study_tasks', _intensiveStudyUids.toList());
    await NotificationService.scheduleAllNotifications(_tasks, _courseNames, _priorityTaskUids, _intensiveStudyUids);
    notifyListeners();
  }

  bool isTaskPriority(String uid) => _priorityTaskUids.contains(uid);
  bool isIntensiveStudy(String uid) => _intensiveStudyUids.contains(uid);

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

