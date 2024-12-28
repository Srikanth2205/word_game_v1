import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LeaderboardScreen extends StatefulWidget {
  @override
  _LeaderboardScreenState createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  String token = '';
  List leaderboard = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    token = ModalRoute.of(context)?.settings.arguments as String;
    fetchLeaderboard();
  }

  Future<void> fetchLeaderboard() async {
    final response = await http.get(
      Uri.parse('http://13.232.115.201:5000/api/leaderboard/top?mode=classic'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        leaderboard = data['leaderboard'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Leaderboard')),
      body: ListView.builder(
        itemCount: leaderboard.length,
        itemBuilder: (context, index) {
          final entry = leaderboard[index];
          return ListTile(
            title: Text(entry['name']),
            subtitle: Text('Score: ${entry['score']}'),
          );
        },
      ),
    );
  }
}
