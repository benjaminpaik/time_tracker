import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:time_tracker/task_db.dart';

class TaskListItem {
  static const String _NAME_KEY = "selectedTask";
  static const String _START_TIME_KEY = "startTime";
  static SharedPreferences _prefs;
  static String _selectedTask;
  static int _startTime;

  _TaskWidget _widget;

  VoidCallback reload = () {};
  int id;
  String name;
  int elapsedTime;
  Color _color;
  Timer _timer;

  TaskListItem({int id, String name: "", int elapsedTime: 0}) {
    // initialize state data
    this.id = id;
    this.name = name;
    this._color = Colors.transparent;
    this.elapsedTime = elapsedTime;

    _widget = _TaskWidget(
      state: this,
    );
  }

  static void recoverPrefs() async {
    if (_prefs == null) {
      _prefs = await SharedPreferences.getInstance();
      _selectedTask = _prefs.getString(_NAME_KEY);
      _startTime = _prefs.getInt(_START_TIME_KEY);
    }
  }

  static void storePrefs(String name) async {
    if (_prefs == null) {
      _prefs = await SharedPreferences.getInstance();
    }
    _selectedTask = name;
    await _prefs.setString(_NAME_KEY, _selectedTask);
    await _prefs.setInt(_START_TIME_KEY, _startTime);
  }

  _TaskWidget get widget => _widget;
}

class _TaskWidget extends StatefulWidget {
  final TaskListItem state;

  _TaskWidget({Key key, this.state}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _TaskWidgetState();
}

class _TaskWidgetState extends State<_TaskWidget> {
  static final _taskFont =
      const TextStyle(fontSize: 26.0, fontWeight: FontWeight.bold);
  static VoidCallback _previousTaskReset = () {};

  void _timerCallback(Timer t) {
    int currentTime =
        DateTime.now().millisecondsSinceEpoch ~/ Duration.millisecondsPerSecond;

    if (this.mounted) {
      setState(() {
        widget.state.elapsedTime = currentTime - TaskListItem._startTime;
      });

      // update the task in the database
      var taskData = TaskData(
          id: widget.state.id,
          name: widget.state.name,
          seconds: widget.state.elapsedTime);
      var dbHelper = DbHelper();
      dbHelper.updateTask(taskData);
    }
  }

  void _updateTaskSelection() {
    // the selected task is not yet running
    if (widget.state._timer == null || widget.state._timer.isActive == false) {
      // reset the previous task
      _previousTaskReset();

      // update the current task
      setState(() {
        // highlight the selected task
        widget.state._color = Colors.greenAccent;
      });

      // initialize the start time when the task is selected
      TaskListItem._startTime = DateTime.now().millisecondsSinceEpoch ~/
          Duration.millisecondsPerSecond;
      // offset the start time in case the task is being restarted
      TaskListItem._startTime -= widget.state.elapsedTime;
      // save the selected state and start time to shared preferences
      TaskListItem.storePrefs(widget.state.name);
      // start the timer
      widget.state._timer =
          Timer.periodic(Duration(seconds: 1), this._timerCallback);
    }
    // the selected task is already running
    else {
      _taskReset();
      // save the selected state and start time to shared preferences
      TaskListItem.storePrefs(null);
    }

    // store a reference to the previous task and reset callback
    _previousTaskReset = this._taskReset;
  }

  void _taskReset() {
    // stop the task timer and reset the background color
    widget.state._timer.cancel();
    if (this.mounted) {
      setState(() {
        widget.state._color = Colors.transparent;
      });
    }
  }

  String _getTime() {
    int seconds = widget.state.elapsedTime;
    int hours = seconds ~/ Duration.secondsPerHour;
    seconds -= (hours * Duration.secondsPerHour);
    int minutes = seconds ~/ Duration.secondsPerMinute;
    seconds -= (minutes * Duration.secondsPerMinute);

    String time = hours.toString() + ":";
    time += (_formatTimeUnit(minutes) + ":");
    time += (_formatTimeUnit(seconds));
    return time;
  }

  static String _formatTimeUnit(int unit) {
    String formattedUnit = unit.toString();

    if (formattedUnit.length == 1) {
      formattedUnit = "0" + formattedUnit;
    }
    return formattedUnit;
  }

  void _reloadCallback() {
    // update the task in the database
    var taskData = TaskData(
        id: widget.state.id,
        name: widget.state.name,
        seconds: widget.state.elapsedTime);
    var dbHelper = DbHelper();
    dbHelper.updateTask(taskData);

    // the start time must be initialized if the task is currently running
    if (TaskListItem._selectedTask == widget.state.name) {
      // seconds since epoch
      int currentTime = DateTime.now().millisecondsSinceEpoch ~/
          Duration.millisecondsPerSecond;
      // seconds since task started
      TaskListItem._startTime = currentTime - widget.state.elapsedTime;
      // save the selected state and start time to shared preferences
      TaskListItem.storePrefs(widget.state.name);
    }
    // update task rendering
    setState(() {});
  }

  @override
  void initState() {
    // this restores/restarts the selected task on app resume or task rebuild
    if (TaskListItem._selectedTask == widget.state.name) {
      // seconds since epoch
      int currentTime = DateTime.now().millisecondsSinceEpoch ~/
          Duration.millisecondsPerSecond;
      // seconds since task started
      widget.state.elapsedTime = currentTime - TaskListItem._startTime;
      // highlight the task
      widget.state._color = Colors.greenAccent;
      // restart the timer
      widget.state._timer = Timer.periodic(Duration(seconds: 1), (Timer timer) {
        _timerCallback(timer);
      });
      // store a reference to the previous task and reset callback
      _previousTaskReset = this._taskReset;
    }
    // store a callback to use set state outside this class
    widget.state.reload = _reloadCallback;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: <Widget>[
      Material(
        color: widget.state._color,
        child: ListTile(
          title: Column(children: <Widget>[
            Text(
              widget.state.name,
              style: _taskFont,
              textAlign: TextAlign.center,
            ),
            Text(
              _getTime(),
              style: _taskFont,
              textAlign: TextAlign.center,
            ),
          ]),
          onTap: () {
            setState(() {
              _updateTaskSelection();
            });
          },
        ),
      ),
      Divider(
        height: 0.0,
      ),
    ]);
  }
}
