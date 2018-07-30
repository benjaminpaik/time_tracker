import 'package:flutter/material.dart';
import 'package:time_tracker/home_page.dart';

void main() => runApp(new TimeTrackerApp());

class TimeTrackerApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Time Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(title: 'Task List'),
    );
  }
}
