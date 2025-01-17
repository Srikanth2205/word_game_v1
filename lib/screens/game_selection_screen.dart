import 'package:flutter/material.dart';

class GameSelectionScreen extends StatefulWidget {
  final String token;

  const GameSelectionScreen({Key? key, required this.token}) : super(key: key);

  @override
  _GameSelectionScreenState createState() => _GameSelectionScreenState();
}

class _GameSelectionScreenState extends State<GameSelectionScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text('Select Mode'),
        automaticallyImplyLeading: true,
        actions: <Widget>[
          IconButton(
            icon: const Icon(
              Icons.home,
              color: Colors.white,
              size: 28,
            ),
            onPressed: () {
              print('Home button pressed in game selection');
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/home',
                (route) => false,
                arguments: widget.token,
              );
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Choose your gameplay mode:',
              style: TextStyle(fontSize: 20),
            ),
          ),
          _buildModeCard(
            context,
            'Classic Mode',
            'Play at your own pace',
            'classic',
          ),
          _buildModeCard(
            context,
            'Timed Mode',
            'Race against the clock',
            'timed',
          ),
          _buildModeCard(
            context,
            'Survival Mode',
            'One mistake and game over',
            'survival',
          ),
        ],
      ),
    );
  }

  Widget _buildModeCard(BuildContext context, String title, String description, String mode) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 4.0,
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/gameplay',
            arguments: {'mode': mode},
          );
        },
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 