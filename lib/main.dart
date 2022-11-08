import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:time_tracker/models/task_list_model.dart';
import 'screens/home_page.dart';

void main() => runApp(const TimeTrackerApp());

class TimeTrackerApp extends StatelessWidget {
  const TimeTrackerApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<TaskListModel>(create: (context) => TaskListModel()),
      ],
      child: MaterialApp(
        title: 'Time Tracker',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const HomePage(title: 'Task List'),
        },
      ),
    );
  }
}

