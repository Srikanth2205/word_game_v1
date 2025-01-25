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
      String url = '${ApiEndpoints.BASE_URL}/leaderboard/leaderboard/top';
      if (selectedMode != 'all') {
        url += '?mode=$selectedMode';
      }

      print('Fetching from URL: $url'); // Debug print

      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedResponse = jsonDecode(response.body);
        
        setState(() {
          // Safely handle the data mapping with null checks
          leaderboardData = (decodedResponse['leaderboard'] as List?)
              ?.map((item) => {
                    'name': item['name']?.toString() ?? 'Unknown',  // Safe string conversion
                    'score': int.tryParse(item['score']?.toString() ?? '0') ?? 0,
                    'mode': item['mode']?.toString()?.toLowerCase() ?? 'unknown',
                    'timestamp': item['timestamp']?.toString() ?? '',
                  })
              .toList() ?? [];

          // Filter if needed
          if (selectedMode != 'all') {
            leaderboardData = leaderboardData
                .where((entry) => entry['mode'] == selectedMode.toLowerCase())
                .toList();
          }
          isLoading = false;
        });
      } else {
        print('Failed to load leaderboard: ${response.statusCode}');
        throw Exception('Failed to load leaderboard');
      }
    } catch (e) {
      print('Error fetching leaderboard: $e');
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
          IconButton(
            icon: Icon(Icons.home),
            onPressed: () {
              Navigator.pushNamed(context, '/home', arguments: widget.token);
            },
          ),
        ],
      ),
      body: Column(
        children: [
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
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : leaderboardData.isEmpty
                    ? Center(child: Text('No leaderboard data available'))
                    : ListView.builder(
                        itemCount: leaderboardData.length,
                        itemBuilder: (context, index) {
                          final entry = leaderboardData[index];
                          return Card(
                            margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            elevation: index < 3 ? 4 : 1,
                            color: index < 3 ? Colors.amber.shade50 : null,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: index < 3 
                                    ? [Colors.amber, Colors.grey[300], Colors.brown[300]][index]
                                    : Colors.blue.withOpacity(0.2),
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    color: index < 3 ? Colors.white : Colors.black87,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                entry['name']?.toString() ?? 'Unknown',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Score: ${entry['score']}',
                                    style: TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Mode: ${(entry['mode'] as String).toUpperCase()}',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                  Text(
                                    'Date: ${entry['timestamp']}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: index < 3
                                  ? Icon(
                                      Icons.emoji_events,
                                      color: [
                                        Colors.amber,
                                        Colors.grey[400],
                                        Colors.brown[300]
                                      ][index],
                                    )
                                  : null,
                            ),
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

