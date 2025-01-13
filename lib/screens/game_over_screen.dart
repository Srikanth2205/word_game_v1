import 'package:flutter/material.dart';
import './mode_selection_screen.dart';
import './leaderboard_screen.dart';

class GameOverScreen extends StatelessWidget {
  final int score;
  final String mode;
  final String token;
  final String message;
  final List<String> validWords;
  final int? finalStreak;
  final bool isHighScore;

  const GameOverScreen({
    Key? key,
    required this.score,
    required this.mode,
    required this.token,
    required this.message,
    required this.validWords,
    this.finalStreak,
    this.isHighScore = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => ModeSelectionScreen(token: token),
          ),
          (route) => false,
        );
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Game Over'),
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isHighScore) ...[
                    Text(
                      '🎉 New High Score! 🎉',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                  Text(
                    message,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Final Score: $score',
                    style: TextStyle(fontSize: 20),
                  ),
                  Text(
                    'Final Streak: $finalStreak',
                    style: TextStyle(fontSize: 20),
                  ),
                  if (validWords.isNotEmpty) ...[
                    SizedBox(height: 20),
                    Text(
                      'Valid Words:',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    Container(
                      constraints: BoxConstraints(maxHeight: 150),
                      child: SingleChildScrollView(
                        child: Column(
                          children: validWords.map((word) => Padding(
                            padding: EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              word,
                              style: TextStyle(fontSize: 16),
                            ),
                          )).toList(),
                        ),
                      ),
                    ),
                  ],
                  SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ModeSelectionScreen(token: token),
                            ),
                            (route) => false,
                          );
                        },
                        child: Text('Play Again'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/home',
                            (route) => false,
                            arguments: token,
                          );
                        },
                        child: Text('Home'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LeaderboardScreen(token: token),
                            ),
                            (route) => false,
                          );
                        },
                        child: Text('View Leaderboard'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
