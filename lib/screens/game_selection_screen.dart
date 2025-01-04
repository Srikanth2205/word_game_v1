import 'package:flutter/material.dart';

class GameSelectionScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: Text('Select Mode'),
        actions: <Widget>[
          IconButton(
            icon: Icon(
              Icons.home,
              color: Colors.white,
              size: 24.0,
            ),
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/',
                (route) => false,
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