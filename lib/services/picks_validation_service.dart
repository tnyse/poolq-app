import 'package:flutter/material.dart';
import 'package:poolqapp/constants/app_theme.dart';
import 'package:poolqapp/widgets/auth/auth_button.dart';

/// Service for validating picks and showing detailed alert dialogs
class PicksValidationService {
  static final PicksValidationService _instance = PicksValidationService._internal();
  factory PicksValidationService() => _instance;
  PicksValidationService._internal();

  /// Validate picks and show detailed alert if incomplete
  Future<bool> validateAndShowAlert({
    required BuildContext context,
    required List<Map<String, dynamic>> games,
    required Map<String, String> userPicks,
    required String tiebreakerValue,
    VoidCallback? onFixPicks,
  }) async {
    final validationResult = _validatePicks(games, userPicks, tiebreakerValue);
    
    if (validationResult.isValid) {
      return true;
    }
    
    // Show detailed alert dialog
    await _showValidationAlert(
      context: context,
      validationResult: validationResult,
      onFixPicks: onFixPicks,
    );
    
    return false;
  }

  /// Build gameId → picked team from a flat list of team abbreviations.
  static Map<String, String> mapFromAbbreviationPicks(
    List<Map<String, dynamic>> games,
    List<String> abbreviationPicks,
  ) {
    final picks = abbreviationPicks.map((p) => p.trim()).toSet();
    final mapped = <String, String>{};
    for (final game in games) {
      final home = game['abbreviation']?.toString().trim() ?? '';
      final away = game['abbreviation2']?.toString().trim() ?? '';
      final gameId = '${home}_vs_${away}_${game['date']}';
      if (home.isNotEmpty && picks.contains(home)) {
        mapped[gameId] = home;
      } else if (away.isNotEmpty && picks.contains(away)) {
        mapped[gameId] = away;
      }
    }
    return mapped;
  }

  /// Validate picks and return detailed result
  PicksValidationResult _validatePicks(
    List<Map<String, dynamic>> games,
    Map<String, String> userPicks,
    String tiebreakerValue,
  ) {
    List<String> missingGames = [];
    List<String> completedGames = [];
    
    // Check each game for picks (by gameId map OR by team abbreviation values)
    final pickedTeams = userPicks.values.map((v) => v.trim()).toSet();
    for (int i = 0; i < games.length; i++) {
      final game = games[i];
      final homeTeam = game['abbreviation']?.toString().trim() ?? '';
      final awayTeam = game['abbreviation2']?.toString().trim() ?? '';
      final gameId = '${homeTeam}_vs_${awayTeam}_${game['date']}';
      final label = '$awayTeam @ $homeTeam';

      final hasPick = userPicks.containsKey(gameId) ||
          pickedTeams.contains(homeTeam) ||
          pickedTeams.contains(awayTeam);
      
      if (hasPick) {
        completedGames.add(label);
      } else {
        missingGames.add('Game ${i + 1}: $label');
      }
    }
    
    // Check tiebreaker
    final hasTiebreaker = tiebreakerValue.trim().isNotEmpty;
    
    return PicksValidationResult(
      isValid: missingGames.isEmpty && hasTiebreaker,
      totalGames: games.length,
      completedPicks: completedGames.length,
      missingGames: missingGames,
      completedGames: completedGames,
      hasTiebreaker: hasTiebreaker,
    );
  }

  /// Show detailed validation alert dialog
  Future<void> _showValidationAlert({
    required BuildContext context,
    required PicksValidationResult validationResult,
    VoidCallback? onFixPicks,
  }) async {
    final theme = Theme.of(context);
    
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.warning_amber_outlined,
                  color: AppTheme.warning,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Incomplete Picks',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: AppTheme.warning,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Summary
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.sports_football,
                            color: AppTheme.primaryBlue,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Pick Summary',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Completed:',
                            style: theme.textTheme.bodyMedium,
                          ),
                          Text(
                            '${validationResult.completedPicks}/${validationResult.totalGames}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: validationResult.completedPicks > 0 
                                  ? AppTheme.success 
                                  : AppTheme.onSurfaceVariant,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Tiebreaker:',
                            style: theme.textTheme.bodyMedium,
                          ),
                          Row(
                            children: [
                              Icon(
                                validationResult.hasTiebreaker 
                                    ? Icons.check_circle 
                                    : Icons.cancel,
                                color: validationResult.hasTiebreaker 
                                    ? AppTheme.success 
                                    : AppTheme.error,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                validationResult.hasTiebreaker ? 'Complete' : 'Missing',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: validationResult.hasTiebreaker 
                                      ? AppTheme.success 
                                      : AppTheme.error,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                if (validationResult.missingGames.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(
                    'Missing Picks:',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppTheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Column (not ListView) — AlertDialog + scroll view can't
                  // measure ListView/viewport intrinsic height.
                  ...validationResult.missingGames.map(
                    (gameLabel) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: AppTheme.error,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              gameLabel,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppTheme.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                
                if (!validationResult.hasTiebreaker) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.error.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.sports_score,
                          color: AppTheme.error,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Please enter your tiebreaker prediction',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppTheme.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                const SizedBox(height: 20),
                
                // Help text
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.info.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppTheme.info,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'You must pick a winner for every game and enter a tiebreaker to submit your entry.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.info,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            // Cancel button
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: AppTheme.onSurfaceVariant),
              ),
            ),
            
            // Fix picks button
            AuthButton(
              text: 'Fix Picks',
              icon: Icons.edit,
              type: AuthButtonType.primary,
              fullWidth: false,
              onPressed: () {
                Navigator.of(context).pop();
                if (onFixPicks != null) {
                  onFixPicks();
                }
              },
            ),
          ],
        );
      },
    );
  }

  /// Show success confirmation dialog
  Future<bool> showSubmissionConfirmation({
    required BuildContext context,
    required int totalPicks,
    required String tiebreakerValue,
  }) async {
    final theme = Theme.of(context);
    
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.check_circle_outline,
                  color: AppTheme.success,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Ready to Submit',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: AppTheme.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Your picks are complete and ready for submission:',
                style: theme.textTheme.bodyLarge,
              ),
              
              const SizedBox(height: 16),
              
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.success.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Picks:',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '$totalPicks',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppTheme.success,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Tiebreaker:',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          tiebreakerValue,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppTheme.success,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.warning.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.warning_amber_outlined,
                      color: AppTheme.warning,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Once submitted, you cannot change your picks. Make sure you\'re satisfied with your selections.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.warning,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            // Go back button
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Review Picks',
                style: TextStyle(color: AppTheme.onSurfaceVariant),
              ),
            ),
            
            // Submit button
            AuthButton(
              text: 'Submit Picks',
              icon: Icons.send,
              type: AuthButtonType.primary,
              fullWidth: false,
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    ) ?? false;
  }
}

/// Result of picks validation
class PicksValidationResult {
  final bool isValid;
  final int totalGames;
  final int completedPicks;
  final List<String> missingGames;
  final List<String> completedGames;
  final bool hasTiebreaker;

  PicksValidationResult({
    required this.isValid,
    required this.totalGames,
    required this.completedPicks,
    required this.missingGames,
    required this.completedGames,
    required this.hasTiebreaker,
  });
}
