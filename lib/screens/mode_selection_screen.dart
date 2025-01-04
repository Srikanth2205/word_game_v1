import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class ModeSelectionScreen extends StatelessWidget {
  final String token;
  
  const ModeSelectionScreen({
    Key? key,
    required this.token,
  }) : super(key: key);
  
  void startGame(BuildContext context, String mode) {
    print('Starting game...');
    print('Mode: $mode');
    print('Token: $token');

    Navigator.pushNamed(
      context,
      '/gameplay',
      arguments: {
        'mode': mode,
        'token': token,
      },
    );
  }
  
  Widget _buildModeButton({
    required String title,
    required String description,
    required String mode,
    required BuildContext context,
  }) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Card(
        elevation: 4,
        child: InkWell(
          onTap: () => startGame(context, mode),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Mode'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Choose your gameplay mode:",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              _buildModeButton(
                title: 'Classic Mode',
                description: 'Play at your own pace',
                mode: 'classic',
                context: context,
              ),
              _buildModeButton(
                title: 'Timed Mode',
                description: 'Race against the clock',
                mode: 'timed',
                context: context,
              ),
              _buildModeButton(
                title: 'Survival Mode',
                description: 'One mistake and game over',
                mode: 'survival',
                context: context,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showModeIntro(BuildContext context, String mode) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        String introText;
        switch (mode) {
          case 'Classic':
            introText = 'Classic Mode: In this mode, you play at your own pace. Try to achieve the highest score without any time pressure.';
            break;
          case 'Timed':
            introText = 'Timed Mode: You have a limited amount of time to score as high as possible. Speed and accuracy are key!';
            break;
          case 'Survival':
            introText = 'Survival Mode: Keep playing as long as you can without making mistakes. The game gets harder as you progress!';
            break;
          default:
            introText = 'Select a mode to see its description.';
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$mode Mode',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                introText,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),
              Align(
                alignment: Alignment.bottomRight,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Got it!'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
