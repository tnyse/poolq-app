import 'package:flutter/foundation.dart';

/// Service to manage game state and score visibility
/// Ensures scores are only visible on appropriate screens (results/leaderboard)
class GameStateService {
  static final GameStateService _instance = GameStateService._internal();
  factory GameStateService() => _instance;
  GameStateService._internal();

  /// Determines if scores should be visible based on context
  /// Scores should ONLY be visible on:
  /// - Results pages (after games are completed)
  /// - Leaderboard pages (for final standings)
  /// - GamePlayWidget (for viewing completed games)
  /// 
  /// Scores should NEVER be visible on:
  /// - Play widget (during pick selection)
  /// - EditPlay widget (when editing picks)
  bool shouldShowScores({
    required String screenContext,
    required String gameStatus,
    bool isPickingPhase = false,
  }) {
    debugPrint('GameStateService: Checking score visibility for context: $screenContext, status: $gameStatus, picking: $isPickingPhase');
    
    // Never show scores during picking phase
    if (isPickingPhase) {
      debugPrint('GameStateService: Hiding scores - picking phase active');
      return false;
    }
    
    // Show scores only on specific screens
    switch (screenContext.toLowerCase()) {
      case 'results':
      case 'leaderboard':
      case 'gameplaywidget':
      case 'games':
        // Only show if games are completed
        final isCompleted = gameStatus.toLowerCase() == 'final' || 
                           gameStatus.toLowerCase() == 'completed' ||
                           gameStatus.toLowerCase() == 'status_final';
        debugPrint('GameStateService: ${isCompleted ? 'Showing' : 'Hiding'} scores for $screenContext (status: $gameStatus)');
        return isCompleted;
      
      case 'play':
      case 'editplay':
      case 'playwidget':
      default:
        debugPrint('GameStateService: Hiding scores for $screenContext');
        return false;
    }
  }

  /// Sanitizes game data to hide scores when appropriate
  Map<String, dynamic> sanitizeGameData(
    Map<String, dynamic> gameData, {
    required String screenContext,
    bool isPickingPhase = false,
  }) {
    final shouldShow = shouldShowScores(
      screenContext: screenContext,
      gameStatus: gameData['status'] ?? 'scheduled',
      isPickingPhase: isPickingPhase,
    );

    if (shouldShow) {
      return gameData; // Return original data with scores
    }

    // Hide scores by returning sanitized data
    var sanitizedData = Map<String, dynamic>.from(gameData);
    sanitizedData['score'] = '0';
    sanitizedData['score2'] = '0';
    sanitizedData['homeScore'] = null;
    sanitizedData['awayScore'] = null;
    
    // Ensure status shows as scheduled during picking
    if (isPickingPhase) {
      sanitizedData['status'] = 'scheduled';
      sanitizedData['statusDetail'] = 'Scheduled';
      sanitizedData['completed'] = false;
    }

    debugPrint('GameStateService: Sanitized game data for ${gameData['name'] ?? 'Unknown Game'}');
    return sanitizedData;
  }

  /// Sanitizes a list of games for the appropriate context
  List<Map<String, dynamic>> sanitizeGamesList(
    List<Map<String, dynamic>> games, {
    required String screenContext,
    bool isPickingPhase = false,
  }) {
    debugPrint('GameStateService: Sanitizing ${games.length} games for context: $screenContext');
    
    return games.map((game) => sanitizeGameData(
      game,
      screenContext: screenContext,
      isPickingPhase: isPickingPhase,
    )).toList();
  }

  /// Checks if the current context is a picking phase
  bool isPickingContext(String screenContext) {
    return ['play', 'editplay', 'playwidget'].contains(screenContext.toLowerCase());
  }

  /// Gets appropriate game status text for display
  String getDisplayStatus(Map<String, dynamic> gameData, String screenContext) {
    if (isPickingContext(screenContext)) {
      return 'Make Your Pick';
    }
    
    final status = gameData['status']?.toString().toLowerCase() ?? 'scheduled';
    switch (status) {
      case 'final':
      case 'completed':
      case 'status_final':
        return 'Final';
      case 'in_progress':
      case 'live':
        return 'In Progress';
      case 'scheduled':
      default:
        return 'Scheduled';
    }
  }
}
