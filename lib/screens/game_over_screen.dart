import 'package:flutter/material.dart';

class GameOverScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Game Over')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Game Over!'),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/gameplay'),
              child: Text('Play Again'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/home'),
              child: Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }
}
