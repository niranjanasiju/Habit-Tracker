// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/habit_provider.dart';
import 'screens/habit_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HabitProvider()..loadAllData(),
      child: MaterialApp(
        title: 'Loop Habit Tracker',
        theme: ThemeData(
          primarySwatch: Colors.teal,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: Colors.grey[900],
          cardColor: Colors.grey[850],
          useMaterial3: true,
        ),
        home: HabitListScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}