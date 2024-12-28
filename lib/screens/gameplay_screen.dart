import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class GameplayScreen extends StatefulWidget {
  @override
  _GameplayScreenState createState() => _GameplayScreenState();
}

class _GameplayScreenState extends State<GameplayScreen> {
  String token = '';
  String jumbledWord = '';
  String wordToken = '';
  int score = 0;
  int streak = 0;

  final TextEditingController guessController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    token = ModalRoute.of(context)?.settings.arguments as String;
    fetchJumbledWord();
  }

  Future<void> fetchJumbledWord() async {
    final response = await http.get(
      Uri.parse('http://13.232.115.201:5000/api/start-round?score=$score'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        jumbledWord = data['jumbled'];
        wordToken = data['token'];
      });
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text('Failed to fetch word'),
        ),
      );
    }
  }

  Future<void> validateGuess() async {
    final response = await http.post(
      Uri.parse('http://13.232.115.201:5000/api/validate/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'userInput': guessController.text,
        'token': wordToken,
        'streak': streak,
        'timeTaken': 5, // Example time taken
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        score = data['score'];
        streak = data['streak'];
      });
      fetchJumbledWord();
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text('Incorrect guess or error occurred'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Gameplay')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Jumbled Word: $jumbledWord'),
            TextField(
              controller: guessController,
              decoration: InputDecoration(labelText: 'Your Guess'),
            ),
            ElevatedButton(
              onPressed: validateGuess,
              child: Text('Submit'),
            ),
            SizedBox(height: 20),
            Text('Score: $score'),
            Text('Streak: $streak'),
          ],
        ),
      ),
    );
  }
}
