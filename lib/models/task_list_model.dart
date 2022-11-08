import 'dart:async';
import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:time_tracker/widgets/task_db.dart';

class TaskListModel extends ChangeNotifier {
  static const String _NAME_KEY = "selectedTask";
  static const String _START_TIME_KEY = "startTime";
  late SharedPreferences _prefs;
  final List<TaskModel> _taskList;
  TaskModel? _selectedTask;
  int _startTime;
  Timer? _timer;

  TaskListModel()
      : _taskList = [],
        _selectedTask = null,
        _startTime = 0,
        _timer = null {
    _initTasks();
  }

  UnmodifiableListView<TaskModel> get taskList =>
      UnmodifiableListView(_taskList);

  void addTask(String name) async {
    // create a database entry for the new task
    var taskData = TaskData(
      name: name,
    );
    // add the entry to the database
    var dbHelper = DbHelper();
    int id = await dbHelper.insertTask(taskData);
    // create the new task
    _taskList.add(TaskModel(id, name, 0));
    notifyListeners();
  }

  void removeTask(int index) {
    if (index >= 0 && index < _taskList.length) {
      // create an instance of the database item for the task
      var taskData = TaskData();
      taskData.name = _taskList[index].name;
      taskData.seconds = 0;
      // remove the task from the database
      var dbHelper = DbHelper();
      dbHelper.deleteTask(taskData);

      // the currently running task is being deleted
      if (_selectedTask == _taskList[index]) {
        _storePrefs("");
        _selectedTask!.color = Colors.transparent;
        _timer?.cancel();
        _selectedTask = null;
      }
      _taskList.removeAt(index);
      notifyListeners();
    }
  }

  void renameTask(int index, String name) {
    if (index >= 0 && index < _taskList.length) {
      _taskList[index].name = name;
      notifyListeners();
    }
  }

  void setTaskTime(int index, int elapsedTime) {
    if (index >= 0 && index < _taskList.length) {
      _taskList[index].elapsedTime = elapsedTime;
      notifyListeners();
    }
  }

  void selectTask(int index) {
    // index is in range
    if (index >= 0 && index < _taskList.length) {
      // task selection has changed
      if (_taskList[index] != _selectedTask) {
        // reset the previous task
        _selectedTask?.color = Colors.transparent;
        _timer?.cancel();
        // update task selection
        _selectedTask = _taskList[index];

        // initialize the start time when the task is selected
        _startTime = DateTime.now().millisecondsSinceEpoch ~/
            Duration.millisecondsPerSecond;
        // offset the start time in case the task is being restarted
        _startTime -= _selectedTask!.elapsedTime;
        // save the selected state and start time to shared preferences
        _storePrefs(_selectedTask!.name);
        // set the selected task color and timer
        _selectedTask!.color = Colors.greenAccent;
        _timer = Timer.periodic(Duration(seconds: 1), _timerCallback);
      }
      // the task is being unselected
      else {
        _taskList[index].color = Colors.transparent;
        _timer?.cancel();
        _storePrefs("");
        _selectedTask = null;
      }
      notifyListeners();
    }
  }

  void _timerCallback(Timer t) {
    if (_selectedTask != null) {
      int currentTime = DateTime.now().millisecondsSinceEpoch ~/
          Duration.millisecondsPerSecond;

      _selectedTask!.elapsedTime = currentTime - _startTime;
      notifyListeners();

      // update the task in the database
      var taskData = TaskData(
          id: _selectedTask!.id,
          name: _selectedTask!.name,
          seconds: _selectedTask!.elapsedTime);
      var dbHelper = DbHelper();
      dbHelper.updateTask(taskData);
    }
  }

  TaskModel _getTask(String name) {
    return _taskList.firstWhere((taskModel) => taskModel.name == name);
  }

  Future<void> _recoverPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    final taskName = _prefs.getString(_NAME_KEY) ?? "";

    if (taskName.isNotEmpty) {
      _selectedTask = _getTask(taskName);
      _startTime = _prefs.getInt(_START_TIME_KEY)!;
    }
  }

  void _storePrefs(String name) async {
    await _prefs.setString(_NAME_KEY, name);
    await _prefs.setInt(_START_TIME_KEY, _startTime);
  }

  Future<void> _loadTasksFromDb() async {
    try {
      var dbHelper = DbHelper();
      List<TaskData> tasks = await dbHelper.getTasks();

      for (var task in tasks) {
        _taskList.add(TaskModel(task.id!, task.name, task.seconds));
      }
    } catch (e) {
      print(e.toString());
    }
  }

  void _initTasks() async {
    await _loadTasksFromDb();
    await _recoverPrefs();

    if(_selectedTask != null) {
      _selectedTask!.color = Colors.greenAccent;
      _timer = Timer.periodic(Duration(seconds: 1), _timerCallback);
    }
    notifyListeners();
  }
}

class TaskModel {
  final int _id;
  String _name;
  int _elapsedTime;
  int _updates;
  Color _color;

  TaskModel(int id, String name, int elapsedTime)
      : _id = id,
        _updates = 0,
        _name = name,
        _elapsedTime = elapsedTime,
        _color = Colors.transparent;

  // getters
  int get updates => _updates;
  int get id => _id;
  String get name => _name;
  Color get color => _color;
  int get elapsedTime => _elapsedTime;
  String get formattedTime {
    int seconds = _elapsedTime;
    int hours = seconds ~/ Duration.secondsPerHour;
    seconds -= (hours * Duration.secondsPerHour);
    int minutes = seconds ~/ Duration.secondsPerMinute;
    seconds -= (minutes * Duration.secondsPerMinute);

    String time = hours.toString() + ":";
    time += (_formatTimeUnit(minutes) + ":");
    time += (_formatTimeUnit(seconds));
    return time;
  }

  // setters
  set name(String name) {
    this._name = name;
    _updates++;
  }

  set elapsedTime(int time) {
    _elapsedTime = time;
    _updates++;
  }

  set color(Color color) {
    _color = color;
    _updates++;
  }
}

String _formatTimeUnit(int unit) {
  String formattedUnit = unit.toString();
  if (formattedUnit.length == 1) {
    formattedUnit = "0" + formattedUnit;
  }
  return formattedUnit;
}
