import 'package:flutter/material.dart';
import 'screens/welcome_screen.dart';
import 'screens/mode_selection_screen.dart';
import 'screens/leaderboard_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/gameplay_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Word Game',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const WelcomeScreen(),
        '/home': (context) => HomeScreen(
          token: ModalRoute.of(context)?.settings.arguments as String,
        ),
        '/mode-selection': (context) => ModeSelectionScreen(
          token: ModalRoute.of(context)?.settings.arguments as String,
        ),
        '/gameplay': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;
          return GameplayScreen(
            mode: args['mode'] as String,
            token: args['token'] as String,
          );
        },
        '/leaderboard': (context) => LeaderboardScreen(
          token: ModalRoute.of(context)?.settings.arguments as String,
        ),
      },
    );
  }
}
