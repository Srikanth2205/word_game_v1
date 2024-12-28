import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Home')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/gameplay'),
              child: Text('Start Game'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/leaderboard'),
              child: Text('View Leaderboard'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}
