import 'package:flutter/material.dart';
import 'screens/welcome_screen.dart';
import 'screens/home_screen.dart';
import 'screens/gameplay_screen.dart';
import 'screens/leaderboard_screen.dart';
import 'screens/game_over_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Word Game',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => WelcomeScreen(),
        '/home': (context) => HomeScreen(),
        '/gameplay': (context) => GameplayScreen(),
        '/leaderboard': (context) => LeaderboardScreen(),
        '/game-over': (context) => GameOverScreen(),
      },
    );
  }
}
