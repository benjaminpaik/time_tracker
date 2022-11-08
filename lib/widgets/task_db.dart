import 'dart:async';
import 'dart:io' as io;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class DbHelper {
  static const _dbName = "TaskData";
  static Database? _db;

  Future<Database?> get db async {
    _db ??= await _initDb();
    return _db;
  }

  // creating a database with name test.db in your directory
  Future<Database> _initDb() async {
    io.Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _dbName + ".db");
    var database = await openDatabase(path, version: 1, onCreate: _onCreate);
    return database;
  }

  void _onCreate(Database db, int version) async {
    // when creating the db, create the table
    await db.execute(
        "CREATE TABLE " + _dbName + "(id INTEGER PRIMARY KEY, name TEXT, seconds INTEGER )");
  }

  Future<int> insertTask(TaskData taskData) async {
    var dbClient = await db;
    // the number of SQL entries with the same name
    var count = Sqflite.firstIntValue(await dbClient!.rawQuery(
        "SELECT COUNT(*) FROM " + _dbName + " WHERE name = ?", [taskData.name]));
    // the task is already in the database
    if (count! > 0) {
      // return an error code
      return -1;
    }
    // the task is not yet in the database
    else {
      // add the task data and return the database ID
      taskData.id = await dbClient.insert(_dbName, taskData.toMap());
      return taskData.id ?? -1;
    }
  }

  Future<int> updateTask(TaskData taskData) async {
    var dbClient = await db;
    // the number of SQL entries with the same name
    var count = Sqflite.firstIntValue(await dbClient!.rawQuery(
        "SELECT COUNT(*) FROM " + _dbName + " WHERE id = ?", [taskData.id]));
    // the task is already in the database
    if (count! > 0) {
      // update the task data
      await dbClient.update(_dbName, taskData.toMap(),
          where: "id = ?", whereArgs: [taskData.id]);
      return taskData.id ?? -1;
    }
    // the task is not yet in the database
    else {
      // return an error code
      return -1;
    }
  }

  void deleteTask(TaskData taskData) async {
    var dbClient = await db;
    // the number of SQL entries with the same name
    var count = Sqflite.firstIntValue(await dbClient!.rawQuery(
        "SELECT COUNT(*) FROM " + _dbName + " WHERE name = ?", [taskData.name]));

    // the task is already in the database
    if (count! > 0) {
      // delete the task data
      await dbClient
          .delete(_dbName, where: "name = ?", whereArgs: [taskData.name]);
    }
  }

  // retrieving tasks from task tables
  Future<List<TaskData>> getTasks() async {
    var dbClient = await db;
    List<Map> results =
        await dbClient!.query(_dbName, columns: TaskData.columns);
    List<TaskData> taskDataList = [];

    for (var result in results) {
      TaskData task = TaskData.fromMap(result);
      taskDataList.add(task);
    }
    return taskDataList;
  }
}

class TaskData {

  TaskData({this.id, this.name = "", this.seconds = 0});

  int? id;
  String name;
  int seconds;

  static final columns = ["id", "name", "seconds"];

  Map<String, Object> toMap() {
    Map<String, Object> map = {
      "name": name,
      "seconds": seconds,
    };
    if (id != null) {
      map["id"] = id!;
    }
    return map;
  }

  static fromMap(Map map) {
    TaskData taskData = TaskData();
    taskData.id = map["id"];
    taskData.name = map["name"];
    taskData.seconds = map["seconds"];
    return taskData;
  }
}
