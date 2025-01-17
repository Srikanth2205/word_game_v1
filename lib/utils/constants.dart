// API endpoints and constants
class ApiEndpoints {
  static const String BASE_URL = "http://52.66.202.180:5000/api";
  static const String LOGIN = "/auth/login";
  static const String REGISTER = "/auth/register";
  static const String LEADERBOARD = "/leaderboard/leaderboard";
  static const String TOP_LEADERBOARD = "/leaderboard/leaderboard/top";
  static const String SUBMIT_SCORE = "/leaderboard/submit-score";
}

// Timing constants
class AppConstants {
  static const Duration FEEDBACK_DELAY = Duration(milliseconds: 1000);
  static const Duration SUCCESS_DELAY = Duration(milliseconds: 500);
}
