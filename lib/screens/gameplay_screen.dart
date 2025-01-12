import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import './game_over_screen.dart';
import './mode_selection_screen.dart';
import './leaderboard_screen.dart';

class GameplayScreen extends StatefulWidget {
  final String token;
  final String mode;

  const GameplayScreen({
    Key? key,
    required this.token,
    required this.mode,
  }) : super(key: key);

  @override
  _GameplayScreenState createState() => _GameplayScreenState();
}

class _GameplayScreenState extends State<GameplayScreen> {
  bool isHighScore = false;
  String jumbledWord = '';
  String wordToken = '';
  int wordLength = 0;
  List<TextEditingController> controllers = [];
  bool isLoading = true;
  int score = 0;
  int streak = 0;
  int timeLimit = 0;
  bool isTimedMode = false;
  bool isGameOver = false;
  int wrongAttempts = 0;
  bool isWrongInput = false;
  bool isCorrectInput = false;
  String correctWord = '';
  FocusNode firstFocusNode = FocusNode();
  String lastGuess = '';
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  List<String> validWords = [];
  List<FocusNode> focusNodes = [];
  List<String> currentValidWords = [];

  @override
  void initState() {
    super.initState();
    isTimedMode = widget.mode == 'timed';
    focusNodes = List.generate(
      4,
      (index) => index == 0 ? firstFocusNode : FocusNode(),
    );
    fetchJumbledWord();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      firstFocusNode.requestFocus();
    });
  }

  void startCountdown() {
    Future.delayed(Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        if (timeLimit > 0) {
          timeLimit -= 1;
          if (timeLimit == 0) {
            showIncorrectWordDialog([correctWord]);
            endGame(false);
          }
        }
      });
      if (timeLimit > 0) {
        startCountdown();
      }
    });
  }

  Future<void> fetchJumbledWord() async {
    try {
      final url =
          'http://13.235.31.190:5000/api/start-round?score=$score&mode=${widget.mode}';
      print('Fetching jumbled word from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      print('FetchJumbledWord Response Status: ${response.statusCode}');
      print('FetchJumbledWord Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          jumbledWord = data['jumbled'] ?? '';
          wordToken = data['token'] ?? '';
          correctWord = data['correctWord']?.toString() ?? jumbledWord;
          wordLength = jumbledWord.length;
          timeLimit = data['timeLimit'] ?? 0;
          focusNodes = List.generate(
            wordLength,
            (index) => index == 0 ? firstFocusNode : FocusNode(),
          );
          controllers = List.generate(
            wordLength,
            (_) => TextEditingController(),
          );
          isLoading = false;

          if (isTimedMode) {
            startCountdown();
          }

          WidgetsBinding.instance.addPostFrameCallback((_) {
            firstFocusNode.requestFocus();
          });
        });
      } else {
        showError('Failed to fetch word.');
        if (widget.mode == 'survival') {
          endGame(false);
        }
      }
    } catch (e) {
      print('FetchJumbledWord Error: $e');
      showError('Error fetching word: $e');
    }
  }

  void clearInput() {
    for (var controller in controllers) {
      controller.clear();
    }
    firstFocusNode.requestFocus();
  }

  bool areAllFieldsFilled() {
    for (var controller in controllers) {
      if (controller.text.isEmpty) {
        return false;
      }
    }
    return true;
  }

  void onTextChanged(String value, int index) {
    print("Text changed at index $index: $value");

    if (value.isEmpty && index > 0) {
      // Handle backspace - move focus to previous field
      controllers[index].clear();
      FocusScope.of(context).previousFocus();
      return;
    }

    if (value.isNotEmpty) {
      controllers[index].text = value.toUpperCase();

      if (index < wordLength - 1) {
        FocusScope.of(context).nextFocus();
      } else {
        if (areAllFieldsFilled()) {
          print("All boxes filled, current word: ${getCurrentWord()}");
          validateWord();
        }
      }
    }
  }

  String getCurrentWord() {
    return controllers.map((c) => c.text.toUpperCase()).join();
  }

  Future<void> validateWord() async {
    if (!areAllFieldsFilled()) return;

    final guess = controllers.map((c) => c.text.toUpperCase()).join();
    lastGuess = guess;

    try {
      final url = '${ApiEndpoints.BASE_URL}/validate/';
      final body = {
        'userInput': guess,
        'token': wordToken,
        'streak': streak,
        'timeTaken': isTimedMode ? timeLimit : 0,
      };

      print('Validating word at: $url');
      print('Validation Request Body: $body');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      print('ValidateWord Response Status: ${response.statusCode}');
      print('ValidateWord Response Body: ${response.body}');

      final data = jsonDecode(response.body);

      // Store valid words from response
      currentValidWords = List<String>.from(data['validWords'] ?? []);

      setState(() {
        if (data['isCorrect']) {
          // Correct answer
          isWrongInput = false;
          isCorrectInput = true;
          score = data['score'];
          streak = data['streak'];

          // Show success feedback with valid words
          showSuccessDialog(currentValidWords);

          Future.delayed(AppConstants.SUCCESS_DELAY, () {
            if (mounted && (timeLimit > 0 || !isTimedMode)) {
              fetchJumbledWord();
            }
          });
        } else {
          // Wrong answer
          isWrongInput = true;
          isCorrectInput = false;

          if (widget.mode == 'survival') {
            showIncorrectWordDialog(currentValidWords);
            endGame(false);
          } else if (widget.mode == 'classic') {
            wrongAttempts++;
            showIncorrectWordDialog(currentValidWords);
            if (wrongAttempts >= 3) {
              endGame(false);
            } else {
              Future.delayed(AppConstants.FEEDBACK_DELAY, () {
                if (mounted) clearInput();
              });
            }
          } else if (widget.mode == 'timed') {
            showIncorrectWordDialog(currentValidWords);
            Future.delayed(AppConstants.FEEDBACK_DELAY, () {
              if (mounted) {
                clearInput();
                firstFocusNode.requestFocus();
              }
            });
          }
        }
      });
    } catch (e) {
      print('ValidateWord Error: $e');
      showError('Error validating word: $e');
    }
  }

  Future<void> fetchHint() async {
    try {
      final url = '${ApiEndpoints.BASE_URL}/hint/';
      final body = {'token': wordToken};

      print('Fetching hint from: $url');
      print('Hint Request Body: $body');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      print('FetchHint Response Status: ${response.statusCode}');
      print('FetchHint Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final hint = data['hint'];
        print('Hint data received: $hint');

        setState(() {
          // Clear previous states
          isWrongInput = false;
          isCorrectInput = false;
          controllers.forEach((controller) => controller.clear());

          // Apply the hint
          for (int i = 0; i < hint.length; i++) {
            if (hint[i] != '_') {
              controllers[i].text = hint[i].toUpperCase();
            }
          }

          // Find first empty field
          int nextEmptyIndex =
              controllers.indexWhere((controller) => controller.text.isEmpty);

          // Focus management
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (nextEmptyIndex != -1) {
              FocusScope.of(context).requestFocus(focusNodes[nextEmptyIndex]);
            } else {
              // If no empty fields, validate the word
              validateWord();
            }
          });
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hint applied!'),
            duration: Duration(seconds: 1),
          ),
        );
      } else {
        print('Failed to fetch hint, status code: ${response.statusCode}');
        showError('Failed to fetch hint.');
      }
    } catch (e) {
      print('FetchHint Error: $e');
      showError('Error fetching hint: $e');
    }
  }

  void showIncorrectWordDialog(List<String> validWords) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title:
            Text(isTimedMode && timeLimit <= 0 ? 'Time\'s Up!' : 'Incorrect!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your guess: $lastGuess'),
            SizedBox(height: 10),
            Text('Valid words:', style: TextStyle(fontWeight: FontWeight.bold)),
            if (validWords.isNotEmpty)
              ...validWords.map((word) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      word,
                      style: TextStyle(fontSize: 16, color: Colors.blue),
                    ),
                  ))
            else
              Text(
                'No valid words available',
                style: TextStyle(fontSize: 16, color: Colors.red),
              ),
            if (widget.mode == 'classic' && wrongAttempts < 3)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  'You have ${3 - wrongAttempts} chances left',
                  style:
                      TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (widget.mode == 'survival' ||
                  (widget.mode == 'classic' && wrongAttempts >= 3) ||
                  (widget.mode == 'timed' && timeLimit <= 0)) {
                endGame(false);
              } else {
                firstFocusNode.requestFocus();
              }
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void showSuccessDialog(List<String> validWords) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Correct!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your word: $lastGuess'),
            SizedBox(height: 10),
            Text('All possible words:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            ...validWords.map((word) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    word,
                    style: TextStyle(
                      fontSize: 16,
                      color: word == lastGuess ? Colors.green : Colors.blue,
                      fontWeight: word == lastGuess
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                )),
            SizedBox(height: 10),
            Text('Score: $score',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Streak: $streak',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (mounted && (timeLimit > 0 || !isTimedMode)) {
                fetchJumbledWord();
              }
            },
            child: Text('Continue'),
          ),
        ],
      ),
    );
  }

  void showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void endGame(bool isWin) async {
    if (isGameOver) return;
    setState(() => isGameOver = true);

    try {
      final url = '${ApiEndpoints.BASE_URL}${ApiEndpoints.SUBMIT_SCORE}';
      final body = {
        'score': score,
        'mode': widget.mode,
      };

      print('Submitting score to: $url');
      print('Score Submit Request Body: $body');

      final submitResponse = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      print('SubmitScore Response Status: ${submitResponse.statusCode}');
      print('SubmitScore Response Body: ${submitResponse.body}');

      if (submitResponse.statusCode == 200) {
        final data = jsonDecode(submitResponse.body);
        isHighScore = data['isHighScore'] ?? false;
      }
    } catch (e) {
      print('SubmitScore Error: $e');
    }

    String message = isWin
        ? 'Congratulations! Your score: $score'
        : isTimedMode && timeLimit <= 0
            ? 'Time\'s Up! Final score: $score'
            : 'Game Over! Final score: $score';

    if (mounted) {
      // Use single navigation call
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => GameOverScreen(
            score: score,
            mode: widget.mode,
            token: widget.token,
            message: message,
            validWords: validWords,
            finalStreak: streak,
            isHighScore: isHighScore,
          ),
        ),
        (route) => false,
      );
    }
  }

  String formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gameplay (${widget.mode})'),
        actions: [
          IconButton(
            icon: Icon(Icons.home),
            onPressed: () {
              Navigator.pushNamed(context, '/home', arguments: widget.token);
            },
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isTimedMode) ...[
                    Container(
                      margin: EdgeInsets.only(bottom: 24),
                      padding:
                          EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: (timeLimit <= 10 ? Colors.red : Colors.blue)
                                .withOpacity(0.2),
                            spreadRadius: 2,
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                        border: Border.all(
                          color: timeLimit <= 10 ? Colors.red : Colors.blue,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.timer,
                            color: timeLimit <= 10 ? Colors.red : Colors.blue,
                            size: 32,
                          ),
                          SizedBox(width: 12),
                          Text(
                            formatTime(timeLimit),
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: timeLimit <= 10 ? Colors.red : Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  Text(
                    'Jumbled Word: $jumbledWord',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      wordLength,
                      (index) => Container(
                        width: 50,
                        height: 50,
                        margin: EdgeInsets.symmetric(horizontal: 4),
                        child: TextField(
                          controller: controllers[index],
                          focusNode: focusNodes[index],
                          textAlign: TextAlign.center,
                          maxLength: 1,
                          textCapitalization: TextCapitalization.characters,
                          onChanged: (value) => onTextChanged(value, index),
                          decoration: InputDecoration(
                            counterText: "",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  BorderSide(color: Colors.blue, width: 2),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  BorderSide(color: Colors.blue, width: 2),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  BorderSide(color: Colors.blue, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isWrongInput
                                ? Colors.red
                                : (isCorrectInput
                                    ? Colors.green
                                    : Colors.black),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (!isTimedMode)
                    ElevatedButton(
                      onPressed: fetchHint,
                      child: Text('Hint'),
                    ),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    for (var node in focusNodes) {
      node.dispose();
    }
    for (var controller in controllers) {
      controller.dispose();
    }
    super.dispose();
  }
}
