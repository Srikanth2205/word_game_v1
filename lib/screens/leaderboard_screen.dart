import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/constants.dart';

class LeaderboardScreen extends StatefulWidget {
  final String token;

  const LeaderboardScreen({
    Key? key,
    required this.token,
  }) : super(key: key);

  @override
  _LeaderboardScreenState createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  String selectedMode = 'all';
  List<dynamic> leaderboardData = [];
  bool isLoading = true;
  bool isTopLeaderboard = false;

  @override
  void initState() {
    super.initState();
    fetchLeaderboard();
  }

  Future<void> fetchLeaderboard() async {
    try {
      final endpoint = isTopLeaderboard
          ? ApiEndpoints.TOP_LEADERBOARD
          : ApiEndpoints.LEADERBOARD;

      String url = '${ApiEndpoints.BASE_URL}$endpoint';
      if (selectedMode != 'all') {
        url += '?mode=$selectedMode';
      }

      print('Fetching leaderboard from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      print('Leaderboard Response Status: ${response.statusCode}');
      print('Leaderboard Response Body: ${response.body}');

      if (response.statusCode == 200) {
        print('Leaderboard Response: ${response.body}');
        final dynamic decodedResponse = jsonDecode(response.body);
        setState(() {
          // Access the 'leaderboard' key from the response
          if (decodedResponse is Map &&
              decodedResponse.containsKey('leaderboard')) {
            leaderboardData = decodedResponse['leaderboard'] as List;
          } else {
            leaderboardData = [];
          }
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load leaderboard: ${response.statusCode}');
      }
    } catch (e) {
      print('Leaderboard Error: $e');
      setState(() {
        isLoading = false;
        leaderboardData = [];
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading leaderboard: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Leaderboard'),
        actions: [
          // Add a home button to navigate back to the home screen
          IconButton(
            icon: Icon(Icons.home),
            onPressed: () {
              Navigator.pushNamed(context, '/home', arguments: widget.token);
            },
          ),
          // Toggle between full and top leaderboard
          IconButton(
            icon: Icon(isTopLeaderboard ? Icons.list : Icons.star),
            onPressed: () {
              setState(() {
                isTopLeaderboard = !isTopLeaderboard;
                isLoading = true;
              });
              fetchLeaderboard();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Mode filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                FilterChip(
                  label: Text('All'),
                  selected: selectedMode == 'all',
                  onSelected: (_) => _updateMode('all'),
                ),
                FilterChip(
                  label: Text('Classic'),
                  selected: selectedMode == 'classic',
                  onSelected: (_) => _updateMode('classic'),
                ),
                FilterChip(
                  label: Text('Timed'),
                  selected: selectedMode == 'timed',
                  onSelected: (_) => _updateMode('timed'),
                ),
                FilterChip(
                  label: Text('Survival'),
                  selected: selectedMode == 'survival',
                  onSelected: (_) => _updateMode('survival'),
                ),
              ],
            ),
          ),
          // Leaderboard list
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: leaderboardData.length,
                    itemBuilder: (context, index) {
                      final entry = leaderboardData[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: index < 3 ? Colors.amber : null,
                          child: Text('${index + 1}'),
                        ),
                        title: Text('Score: ${entry['score']}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                'Mode: ${entry['mode']?.toString().toUpperCase() ?? 'All'}'),
                            Text('Date: ${entry['timestamp'] ?? 'N/A'}'),
                          ],
                        ),
                        trailing: index < 3
                            ? Icon(Icons.emoji_events, color: Colors.amber)
                            : null,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _updateMode(String mode) {
    setState(() {
      selectedMode = mode;
      isLoading = true;
    });
    fetchLeaderboard();
  }
}
