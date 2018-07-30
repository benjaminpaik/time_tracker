import 'package:flutter/material.dart';
import 'package:time_tracker/task_db.dart';
import 'task.dart';

class HomePage extends StatefulWidget {
  HomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<TaskListItem> _taskList;

  void _addTaskDialog() async {
    TextEditingController _textController = TextEditingController();

    await showDialog(
        context: context,
        builder: (_) => AlertDialog(
              title: Text("Add A New Task"),
              content: TextField(
                controller: _textController,
                decoration: InputDecoration(
                    border: InputBorder.none, hintText: 'Enter the task name'),
              ),
              actions: <Widget>[
                FlatButton(
                  child: const Text("CANCEL"),
                  onPressed: () => Navigator.pop(context),
                ),
                FlatButton(
                  child: const Text("ADD"),
                  onPressed: (() {
                    Navigator.pop(context);
                    _addTask(_textController.text);
                  }),
                )
              ],
            ));
  }

  void _deleteTaskDialog(int index) async {
    await showDialog(
        context: context,
        builder: (_) => AlertDialog(
              title: Text("Delete " + _taskList[index].widget.state.name + "?"),
              actions: <Widget>[
                FlatButton(
                  child: const Text("CANCEL"),
                  onPressed: () => Navigator.pop(context),
                ),
                FlatButton(
                  child: const Text("DELETE"),
                  onPressed: (() {
                    Navigator.pop(context);
                    if (this.mounted) {
                      // add the task to the database
                      var taskData = TaskData();
                      taskData.name = _taskList[index].widget.state.name;
                      taskData.seconds = 0;

                      var dbHelper = DbHelper();
                      dbHelper.deleteTask(taskData);

                      setState(() {
                        _taskList.removeAt(index);
                      });
                    }
                  }),
                )
              ],
            ));
  }

  void _renameTaskDialog(int index) async {
    TextEditingController _textController = TextEditingController();

    await showDialog(
        context: context,
        builder: (_) => AlertDialog(
              title: Text("Edit Task Name"),
              content: TextField(
                controller: _textController,
                decoration: InputDecoration(
                    border: InputBorder.none, hintText: 'Enter the task name'),
              ),
              actions: <Widget>[
                FlatButton(
                  child: const Text("CANCEL"),
                  onPressed: () => Navigator.pop(context),
                ),
                FlatButton(
                  child: const Text("SET"),
                  onPressed: (() {
                    Navigator.pop(context);
                    _renameTask(index, _textController.text);
                  }),
                )
              ],
            ));
  }

  void _setTaskTimeDialog(int index) async {
    TextEditingController _textController = TextEditingController();

    await showDialog(
        context: context,
        builder: (_) => AlertDialog(
              title: Text("Edit Task Time"),
              content: TextField(
                keyboardType: TextInputType.datetime,
                controller: _textController,
                decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Enter the task time - hh:mm:ss'),
              ),
              actions: <Widget>[
                FlatButton(
                  child: const Text("CANCEL"),
                  onPressed: () => Navigator.pop(context),
                ),
                FlatButton(
                  child: const Text("SET"),
                  onPressed: (() {
                    Navigator.pop(context);
                    _setTaskTime(index, _textController.text);
                  }),
                )
              ],
            ));
  }

  void _editTaskDialog(int index) async {
    await showDialog(
        context: context,
        builder: (_) => AlertDialog(
              title: Text("Edit Name or Time?"),
              actions: <Widget>[
                FlatButton(
                  child: const Text("CANCEL"),
                  onPressed: () => Navigator.pop(context),
                ),
                FlatButton(
                  child: const Text("NAME"),
                  onPressed: (() {
                    Navigator.pop(context);
                    _renameTaskDialog(index);
                  }),
                ),
                FlatButton(
                  child: const Text("TIME"),
                  onPressed: (() {
                    Navigator.pop(context);
                    _setTaskTimeDialog(index);
                  }),
                )
              ],
            ));
  }

  void _addTask(String name) async {
    // a task with the same title already exists
    if (_taskList.map((item) => item.widget.state.name).contains(name)) {
      await showDialog(
          context: context,
          builder: (_) => AlertDialog(
                title: Text("This name is currently taken"),
                actions: <Widget>[
                  FlatButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("OK")),
                ],
              ));
    } else {
      // create a database entry for the new task
      var taskData = TaskData(
        name: name,
      );
      // add the entry to the database
      var dbHelper = DbHelper();
      int id = await dbHelper.insertTask(taskData);
      // create the new task
      var task = TaskListItem(
        id: id,
        name: name,
      );
      // add the new task to the list
      setState(() {
        // add the new task
        _taskList.add(task);
      });
    }
  }

  void _renameTask(int index, String name) async {
    // a task with the same title already exists
    if (_taskList.map((item) => item.widget.state.name).contains(name)) {
      await showDialog(
          context: context,
          builder: (_) => AlertDialog(
                title: Text("This name is currently taken"),
                actions: <Widget>[
                  FlatButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("OK")),
                ],
              ));
    } else {
      // change the task name and reload the widget
      _taskList[index].name = name;
      _taskList[index].reload();
    }
  }

  void _setTaskTime(int index, String time) async {
    int elapsedTime;
    var timeUnits = time.split(":");

    // the input contains the correct amount of units
    if (timeUnits.length == 3) {
      // extract the time units
      int hours = int.tryParse(timeUnits[0]);
      int minutes = int.tryParse(timeUnits[1]);
      int seconds = int.tryParse(timeUnits[2]);
      // the parsing was successful
      if (hours != null && minutes != null && seconds != null) {
        // each unit has a valid range
        if (hours >= 0 &&
            minutes >= 0 &&
            minutes < Duration.minutesPerHour &&
            seconds >= 0 &&
            seconds < Duration.secondsPerMinute) {
          // set the elapsed time based on the units
          elapsedTime = hours * Duration.secondsPerHour;
          elapsedTime += minutes * Duration.secondsPerMinute;
          elapsedTime += seconds;
        }
      }
    }

    if (elapsedTime == null) {
      await showDialog(
          context: context,
          builder: (_) => AlertDialog(
                title: Text("Time must be formatted - hh:mm:ss"),
                actions: <Widget>[
                  FlatButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("OK")),
                ],
              ));
    } else {
      // change the task time and reload the widget
      _taskList[index].elapsedTime = elapsedTime;
      _taskList[index].reload();
    }
  }

  void _getTasks() async {
    try {
      TaskListItem.recoverPrefs();
      var dbHelper = DbHelper();
      List<TaskData> tasks = await dbHelper.getTasks();
      _taskList = List<TaskListItem>();

      for (var task in tasks) {
        _taskList.add(TaskListItem(
          id: task.id,
          name: task.name,
          elapsedTime: task.seconds,
        ));
      }
    } catch (e) {
      _taskList = List<TaskListItem>();
      print(e.toString());
    }
    setState(() {});
  }

  @override
  void initState() {
    _taskList = List<TaskListItem>();
    _getTasks();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ListView.builder(
            padding: EdgeInsets.all(0.0),
            itemCount: _taskList.length,
            itemBuilder: (BuildContext context, int index) {
              if (index < _taskList.length) {
                return GestureDetector(
                  key: ObjectKey(_taskList[index]),
                  onHorizontalDragEnd: (direction) {
                    _deleteTaskDialog(index);
                  },
                  onLongPress: () => _editTaskDialog(index),
                  child: _taskList[index].widget,
                );
              }
            }),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTaskDialog,
        tooltip: 'Click to add a new task',
        child: Icon(Icons.add),
      ),
    );
  }
}
