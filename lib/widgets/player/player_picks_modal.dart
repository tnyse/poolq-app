import 'package:flutter/material.dart';
import 'package:poolqapp/constants/app_theme.dart';
import 'package:poolqapp/utils/avatar_url.dart';

/// Modal to display player information and their picks with helmet icons
class PlayerPicksModal extends StatelessWidget {
  final Map<String, dynamic> playerData;
  final List<Map<String, dynamic>> games;
  final String weekName;
  final bool hidePrivateInfo;

  const PlayerPicksModal({
    Key? key,
    required this.playerData,
    required this.games,
    required this.weekName,
    this.hidePrivateInfo = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final weekNumber = weekName.replaceAll('REG', '').replaceAll('PRE', '');
    final playerPicks = List<String>.from(playerData['picks'] ?? []);
    final playerScore = playerData['score'] ?? 0;
    final displayName = playerData['displayName'] ?? 'Unknown Player';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryBlue,
                    AppTheme.primaryBlue.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  // Player avatar
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    backgroundImage: resolveAvatarImage(
                      photoUrl: (playerData['photoURL'] ?? '').toString(),
                      email: (playerData['email'] ?? '').toString(),
                      size: 120,
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Player info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Week $weekNumber Picks',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        if (!hidePrivateInfo) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Score: $playerScore',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  // Close button
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            
            // Picks content
            Flexible(
              child: playerPicks.isEmpty
                  ? _buildEmptyState(theme)
                  : _buildPicksList(theme, playerPicks),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.sports_football,
            size: 64,
            color: AppTheme.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No Picks Yet',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: AppTheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This player hasn\'t submitted their picks for this week.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPicksList(ThemeData theme, List<String> playerPicks) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      shrinkWrap: true,
      itemCount: games.length,
      itemBuilder: (context, index) {
        final game = games[index];
        final homeTeam = game['abbreviation'] ?? '';
        final awayTeam = game['abbreviation2'] ?? '';
        final homeName = game['fullname'] ?? '';
        final awayName = game['fullname2'] ?? '';
        
        // Find player's pick for this game
        String? playerPick;
        for (String pick in playerPicks) {
          if (pick == homeTeam || pick == awayTeam) {
            playerPick = pick;
            break;
          }
        }

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: playerPick != null 
                  ? AppTheme.tertiaryGreen.withOpacity(0.5)
                  : AppTheme.outline.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Game number
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Teams
                Expanded(
                  child: Row(
                    children: [
                      // Away team
                      _buildTeamDisplay(
                        theme,
                        awayTeam,
                        awayName,
                        game['picture2'] ?? '',
                        playerPick == awayTeam,
                      ),
                      
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          '@',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      
                      // Home team
                      _buildTeamDisplay(
                        theme,
                        homeTeam,
                        homeName,
                        game['picture'] ?? '',
                        playerPick == homeTeam,
                      ),
                    ],
                  ),
                ),
                
                // Pick indicator
                if (playerPick != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.tertiaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.tertiaryGreen.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 16,
                          color: AppTheme.tertiaryGreen,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          playerPick,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppTheme.tertiaryGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.error.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.help_outline,
                          size: 16,
                          color: AppTheme.error,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'No Pick',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppTheme.error,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTeamDisplay(
    ThemeData theme,
    String abbr,
    String name,
    String logo,
    bool isSelected,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected 
            ? AppTheme.tertiaryGreen.withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isSelected
            ? Border.all(color: AppTheme.tertiaryGreen.withOpacity(0.3))
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Team helmet/logo
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                logo,
                width: 24,
                height: 24,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.sports_football,
                      size: 16,
                      color: AppTheme.primaryBlue,
                    ),
                  );
                },
              ),
            ),
          ),
          
          const SizedBox(width: 6),
          
          // Team abbreviation
          Text(
            abbr,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? AppTheme.tertiaryGreen : AppTheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
