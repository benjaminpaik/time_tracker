import 'package:flutter/material.dart';
import 'package:time_tracker/models/task_list_model.dart';
import 'package:provider/provider.dart';
import 'package:tuple/tuple.dart';

// definitions
const String ADD_NEW_TASK = "Add a new task";
const String ENTER_TASK_NAME = "Enter the task name";
const String EDIT_TASK_NAME = "Edit task name";
const String ENTER_TASK_TIME = "Enter the task time - hh:mm:ss";
const String TIME_FORMAT = "Time must be formatted - hh:mm:ss";
const String EDIT_TASK_TIME = "Edit task time";
const String RESET_TASK_TIME = "Reset task time?";
const String EDIT_NAME_TIME = "Edit name or time?";
const String NAME_TAKEN = "This name is currently taken";
const String NAME_NULL = "The task name must contain at least one character";
const String ADD_TASK_TIP = "Click to add a new task";

class HomePage extends StatelessWidget {
  final String? title;

  const HomePage({Key? key, @required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title ?? ""),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: TaskListWidget(),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: ADD_TASK_TIP,
        child: Icon(Icons.add),
        onPressed: () {
          _addTaskDialog(context);
        },
      ),
    );
  }
}

class TaskListWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Selector<TaskListModel, int>(
      selector: (_, taskListModel) => taskListModel.taskList.length,
      builder: (context, listLength, child) {
        return ListView.builder(
            scrollDirection: Axis.vertical,
            shrinkWrap: true,
            padding: EdgeInsets.all(0.0),
            itemCount: listLength,
            itemBuilder: (BuildContext context, int index) {
              return GestureDetector(
                key: ObjectKey(index),
                onHorizontalDragEnd: (direction) {
                  _deleteTaskDialog(context, index);
                },
                onLongPress: () => _editTaskDialog(context, index),
                child: TaskWidget(index),
              );
            });
      },
    );
  }
}

void _addTaskDialog(BuildContext context) async {
  TextEditingController _textController = TextEditingController();

  await showDialog(
      context: context,
      builder: (_) => AlertDialog(
            title: Text(ADD_NEW_TASK),
            content: TextField(
              controller: _textController,
              decoration: InputDecoration(
                  border: InputBorder.none, hintText: ENTER_TASK_NAME),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text("CANCEL"),
                onPressed: () => Navigator.pop(context),
              ),
              TextButton(
                child: const Text("ADD"),
                onPressed: (() {
                  Navigator.pop(context);
                  final taskListModel =
                      Provider.of<TaskListModel>(context, listen: false);
                  final taskList = taskListModel.taskList;
                  final name = _textController.text;
                  // a task with the same title already exists
                  if (taskList.map((item) => item.name).contains(name)) {
                    showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                              title: Text(NAME_TAKEN),
                              actions: <Widget>[
                                TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text("OK")),
                              ],
                            ));
                  } else if (name.isEmpty) {
                    showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                              title: Text(NAME_NULL),
                              actions: <Widget>[
                                TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text("OK")),
                              ],
                            ));
                  } else {
                    // add the new task
                    taskListModel.addTask(_textController.text);
                  }
                }),
              )
            ],
          ));
}

void _deleteTaskDialog(BuildContext context, int index) async {
  final taskListModel = Provider.of<TaskListModel>(context, listen: false);
  final taskModel = taskListModel.taskList[index];

  await showDialog(
      context: context,
      builder: (_) => AlertDialog(
            title: Text("Delete " + taskModel.name + "?"),
            actions: <Widget>[
              TextButton(
                child: const Text("CANCEL"),
                onPressed: () => Navigator.pop(context),
              ),
              TextButton(
                child: const Text("DELETE"),
                onPressed: (() {
                  Navigator.pop(context);
                  taskListModel.removeTask(index);
                }),
              )
            ],
          ));
}

void _editTaskDialog(BuildContext context, int index) async {
  await showDialog(
      context: context,
      builder: (_) => AlertDialog(
            title: Text(EDIT_NAME_TIME),
            actions: <Widget>[
              TextButton(
                child: const Text("CANCEL"),
                onPressed: () => Navigator.pop(context),
              ),
              TextButton(
                child: const Text("NAME"),
                onPressed: (() {
                  Navigator.pop(context);
                  _renameTaskDialog(context, index);
                }),
              ),
              TextButton(
                child: const Text("TIME"),
                onPressed: (() {
                  Navigator.pop(context);
                  _setTaskTimeDialog(context, index);
                }),
              ),
            ],
          ));
}

void _renameTaskDialog(BuildContext context, int index) async {
  TextEditingController _textController = TextEditingController();

  await showDialog(
      context: context,
      builder: (_) => AlertDialog(
            title: Text(EDIT_TASK_NAME),
            content: TextField(
              controller: _textController,
              decoration: InputDecoration(
                  border: InputBorder.none, hintText: ENTER_TASK_NAME),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text("CANCEL"),
                onPressed: () => Navigator.pop(context),
              ),
              TextButton(
                child: const Text("SET"),
                onPressed: (() {
                  Navigator.pop(context);
                  String name = _textController.text;
                  final taskListModel =
                      Provider.of<TaskListModel>(context, listen: false);

                  // a task with the same title already exists
                  if (taskListModel.taskList
                      .map((item) => item.name)
                      .contains(name)) {
                    showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                              title: Text(NAME_TAKEN),
                              actions: <Widget>[
                                TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text("OK")),
                              ],
                            ));
                  } else if (name == null || name == "") {
                    showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                              title: Text(NAME_NULL),
                              actions: <Widget>[
                                TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text("OK")),
                              ],
                            ));
                  } else {
                    taskListModel.renameTask(index, name);
                  }
                }),
              )
            ],
          ));
}

void _setTaskTimeDialog(BuildContext context, int index) async {
  TextEditingController _textController = TextEditingController();

  await showDialog(
      context: context,
      builder: (_) => AlertDialog(
            title: Text(EDIT_TASK_TIME),
            content: TextField(
              keyboardType: TextInputType.datetime,
              controller: _textController,
              decoration: InputDecoration(
                  border: InputBorder.none, hintText: ENTER_TASK_TIME),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text("CANCEL"),
                onPressed: () => Navigator.pop(context),
              ),
              TextButton(
                child: const Text("RESET"),
                onPressed: (() {
                  Navigator.pop(context);
                  _resetTaskTimeDialog(context, index);
                }),
              ),
              TextButton(
                child: const Text("SET"),
                onPressed: (() {
                  Navigator.pop(context);
                  _setTaskTime(context, index, _textController.text);
                }),
              ),
            ],
          ));
}

void _resetTaskTimeDialog(BuildContext context, int index) async {
  await showDialog(
      context: context,
      builder: (_) => AlertDialog(
            title: Text(RESET_TASK_TIME),
            actions: <Widget>[
              TextButton(
                child: const Text("CANCEL"),
                onPressed: () => Navigator.pop(context),
              ),
              TextButton(
                child: const Text("RESET"),
                onPressed: (() {
                  Navigator.pop(context);
                  _setTaskTime(context, index, "0:0:0");
                }),
              )
            ],
          ));
}

void _setTaskTime(BuildContext context, int index, String time) async {
  int? elapsedTime;
  var timeUnits = time.split(":");

  // the input contains the correct amount of units
  if (timeUnits.length == 3) {
    // extract the time units
    int? hours = int.tryParse(timeUnits[0]);
    int? minutes = int.tryParse(timeUnits[1]);
    int? seconds = int.tryParse(timeUnits[2]);
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
              title: Text(TIME_FORMAT),
              actions: <Widget>[
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("OK")),
              ],
            ));
  } else {
    final taskListModel = Provider.of<TaskListModel>(context, listen: false);
    taskListModel.setTaskTime(index, elapsedTime);
  }
}

class TaskWidget extends StatelessWidget {
  static final _taskFont =
      const TextStyle(fontSize: 26.0, fontWeight: FontWeight.bold);
  final int index;

  TaskWidget(this.index);

  @override
  Widget build(BuildContext context) {
    return Column(children: <Widget>[
      Selector<TaskListModel, Tuple2<TaskListModel, int>>(
        selector: (_, taskListModel) {
          return Tuple2(taskListModel, taskListModel.taskList[index].updates);
        },
        builder: (_, selectorTuple, child) {
          final taskListModel = selectorTuple.item1;
          final taskModel = taskListModel.taskList[index];

          return Material(
            color: taskModel.color,
            child: ListTile(
              title: Column(children: <Widget>[
                Text(
                  taskModel.name,
                  style: _taskFont,
                  textAlign: TextAlign.center,
                ),
                Text(
                  taskModel.formattedTime,
                  style: _taskFont,
                  textAlign: TextAlign.center,
                ),
              ]),
              onTap: () {
                taskListModel.selectTask(index);
              },
            ),
          );
        },
      ),
      Divider(
        height: 0.0,
      ),
    ]);
  }
}
