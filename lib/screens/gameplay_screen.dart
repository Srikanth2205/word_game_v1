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

class _GameplayScreenState extends State<GameplayScreen>
    with SingleTickerProviderStateMixin {
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
  String hint = '';
  bool isHintLoading = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool showStreakEmoji = false;

  @override
  void initState() {
    super.initState();
    isTimedMode = widget.mode == 'timed';
    fetchJumbledWord();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      firstFocusNode.requestFocus();
    });
    _animationController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
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
      final response = await http.get(
        Uri.parse(
          'http://13.232.37.18:5000/api/start-round?score=$score&mode=${widget.mode}',
        ),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          jumbledWord = data['jumbled'];
          wordToken = data['token'];
          wordLength = jumbledWord.length;
          timeLimit = data['timeLimit'] ?? 0;
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
    if (value.length == 1 && index < wordLength - 1) {
      // Move to next field
      FocusScope.of(context).nextFocus();
    } else if (value.isEmpty && index > 0) {
      // Move to previous field on backspace
      FocusScope.of(context).previousFocus();
    }

    // Check if word is complete
    if (areAllFieldsFilled()) {
      validateWord();
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
      final response = await http.post(
        Uri.parse('${ApiEndpoints.BASE_URL}/validate/'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'userInput': guess,
          'token': wordToken,
          'streak': streak,
          'timeTaken': isTimedMode ? timeLimit : 0,
        }),
      );

      final data = jsonDecode(response.body);

      setState(() {
        if (data['isCorrect']) {
          // Correct answer
          isWrongInput = false;
          isCorrectInput = true;
          score = data['score'];
          streak = data['streak'];

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Correct!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 1),
            ),
          );

          Future.delayed(AppConstants.SUCCESS_DELAY, () {
            if (mounted && (timeLimit > 0 || !isTimedMode)) {
              fetchJumbledWord();
            }
          });

          // Show celebration animation
          showStreakEmoji = true;
          _animationController.forward().then((_) {
            Future.delayed(Duration(seconds: 1), () {
              if (mounted) {
                setState(() {
                  showStreakEmoji = false;
                });
                _animationController.reset();
              }
            });
          });
        } else {
          // Wrong answer handling
          if (widget.mode == 'timed') {
            // For timed mode: show quick feedback and clear input
            isWrongInput = true;
            isCorrectInput = false;

            // Show suggestion to try again
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Try again!'),
                backgroundColor: Colors.red,
                duration: Duration(milliseconds: 500),
              ),
            );

            // Clear input boxes immediately
            Future.delayed(Duration(milliseconds: 300), () {
              if (mounted) {
                clearInput();
                firstFocusNode.requestFocus();
              }
            });
          } else if (widget.mode == 'survival') {
            // Existing survival mode logic
            showIncorrectWordDialog(
                List<String>.from(data['validWords'] ?? []));
            endGame(false);
          } else if (widget.mode == 'classic') {
            // Existing classic mode logic
            wrongAttempts++;
            showIncorrectWordDialog(
                List<String>.from(data['validWords'] ?? []));
            if (wrongAttempts >= 3) {
              endGame(false);
            } else {
              Future.delayed(AppConstants.FEEDBACK_DELAY, () {
                if (mounted) clearInput();
              });
            }
          }
        }
      });
    } catch (e) {
      print("Validation error: $e");
      showError('Error validating word: $e');
    }
  }

  Future<void> fetchHint() async {
    try {
      setState(() => isHintLoading = true);

      final response = await http.post(
        Uri.parse('${ApiEndpoints.BASE_URL}/hint/'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'token': wordToken,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final hint = data['hint'];

        setState(() {
          // Update only the first empty field with hint
          int emptyIndex =
              controllers.indexWhere((controller) => controller.text.isEmpty);
          if (emptyIndex != -1) {
            controllers[emptyIndex].text = hint[emptyIndex];

            // Ensure the text field remains editable
            controllers[emptyIndex].selection = TextSelection.fromPosition(
              TextPosition(offset: controllers[emptyIndex].text.length),
            );
          }
          isHintLoading = false;
        });

        // Find next empty field and focus it
        int nextEmptyIndex =
            controllers.indexWhere((controller) => controller.text.isEmpty);
        if (nextEmptyIndex != -1) {
          // Small delay to ensure proper focus
          Future.delayed(Duration(milliseconds: 50), () {
            if (mounted) {
              FocusScope.of(context).requestFocus(
                  nextEmptyIndex == 0 ? firstFocusNode : FocusNode());
            }
          });
        }

        // Show feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hint applied!'),
            duration: Duration(seconds: 1),
          ),
        );
      } else {
        setState(() => isHintLoading = false);
        showError('Failed to fetch hint.');
      }
    } catch (e) {
      setState(() => isHintLoading = false);
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
          children: [
            Text('Your guess: $lastGuess'),
            SizedBox(height: 10),
            Text('Valid words:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...validWords.map((word) => Text(
                  word,
                  style: TextStyle(fontSize: 16, color: Colors.blue),
                )),
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

    // Submit final score
    bool isHighScore = false;
    try {
      final submitResponse = await http.post(
        Uri.parse('${ApiEndpoints.BASE_URL}${ApiEndpoints.SUBMIT_SCORE}'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'score': score,
          'mode': widget.mode,
        }),
      );

      if (submitResponse.statusCode == 200) {
        final data = jsonDecode(submitResponse.body);
        isHighScore = data['isHighScore'] ?? false;
      }
    } catch (e) {
      print('Error submitting score: $e');
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

  void showGameFeedback(List<String> validWords) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red),
                    SizedBox(width: 8),
                    Text(
                      'Game Over!',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your answer was incorrect.',
                        style: TextStyle(fontSize: 18),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Valid words were:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      ...validWords.map((word) => Padding(
                            padding: EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              '• $word',
                              style: TextStyle(fontSize: 16),
                            ),
                          )),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(16),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50),
                    backgroundColor: Colors.blue,
                  ),
                  onPressed: () {
                    Navigator.pop(context); // Close feedback
                    endGame(false); // Move to game over screen
                  },
                  child: Text(
                    'View Final Score',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildScoreDisplay() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Score Card
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.blue, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.2),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  'Score',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                AnimatedDefaultTextStyle(
                  duration: Duration(milliseconds: 300),
                  style: TextStyle(
                    fontSize: score > 0 ? 24 : 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                  child: Text('$score'),
                ),
              ],
            ),
          ),

          // Streak Card with Emoji
          Stack(
            alignment: Alignment.topRight,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: Colors.orange,
                    width: streak > 0 ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.2),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'Streak',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedDefaultTextStyle(
                          duration: Duration(milliseconds: 300),
                          style: TextStyle(
                            fontSize: streak > 0 ? 24 : 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                          child: Text('$streak'),
                        ),
                        if (streak > 0) Text(' 🔥'),
                      ],
                    ),
                  ],
                ),
              ),
              if (showStreakEmoji)
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Text(
                    _getStreakEmoji(),
                    style: TextStyle(fontSize: 24),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _getStreakEmoji() {
    if (streak >= 10) return '🏆';
    if (streak >= 7) return '🌟';
    if (streak >= 5) return '⭐';
    if (streak >= 3) return '✨';
    return '👏';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gameplay (${widget.mode})'),
        actions: [
          if (isTimedMode)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: timeLimit <= 10
                      ? Colors.red.withOpacity(0.2)
                      : Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.timer,
                      color: timeLimit <= 10 ? Colors.red : Colors.white,
                    ),
                    SizedBox(width: 4),
                    Text(
                      formatTime(timeLimit),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: timeLimit <= 10 ? Colors.red : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  if (isTimedMode)
                    Container(
                      margin: EdgeInsets.only(bottom: 20),
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: timeLimit <= 10
                            ? Colors.red.withOpacity(0.1)
                            : Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15),
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
                            size: 28,
                          ),
                          SizedBox(width: 8),
                          Text(
                            formatTime(timeLimit),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: timeLimit <= 10 ? Colors.red : Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  _buildScoreDisplay(),
                  Text(
                    'Jumbled Word: $jumbledWord',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      wordLength,
                      (index) => _buildTextField(index),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: isHintLoading ? null : fetchHint,
                    child: Text('Hint'),
                  ),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    firstFocusNode.dispose();
    for (var controller in controllers) {
      controller.dispose();
    }
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildTextField(int index) {
    return Container(
      width: 50,
      height: 50,
      margin: EdgeInsets.symmetric(horizontal: 4),
      child: TextField(
        controller: controllers[index],
        focusNode: index == 0 ? firstFocusNode : null,
        textAlign: TextAlign.center,
        maxLength: 1,
        enabled: true, // Ensure field is enabled
        textCapitalization: TextCapitalization.characters,
        onChanged: (value) => onTextChanged(value, index),
        decoration: InputDecoration(
          counterText: "",
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.blue, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.blue, width: 2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.blue, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: isWrongInput
              ? Colors.red
              : (isCorrectInput ? Colors.green : Colors.black),
        ),
      ),
    );
  }
}
