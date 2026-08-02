import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:poolqapp/constants/app_theme.dart';
import 'package:poolqapp/Provider/homeProvider.dart';
import 'package:poolqapp/widgets/auth/auth_button.dart';
import 'package:poolqapp/services/picks_validation_service.dart';

/// Modern review picks widget with edit functionality and clean UI
class ReviewPicksWidget extends StatefulWidget {
  final List<Map<String, dynamic>> games;
  final Map<String, String> userPicks;
  final TextEditingController tieBreakerController;
  final VoidCallback? onEditPicks;
  final VoidCallback? onSubmitPicks;

  const ReviewPicksWidget({
    Key? key,
    required this.games,
    required this.userPicks,
    required this.tieBreakerController,
    this.onEditPicks,
    this.onSubmitPicks,
  }) : super(key: key);

  @override
  State<ReviewPicksWidget> createState() => _ReviewPicksWidgetState();
}

class _ReviewPicksWidgetState extends State<ReviewPicksWidget>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    final weekName = dataProvider.game?['name'] ?? 'REG1';
    final weekNumber = weekName.replaceAll('REG', '').replaceAll('PRE', '');

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.primaryBlue),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Review Your Picks',
          style: theme.textTheme.titleLarge?.copyWith(
            color: AppTheme.primaryBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          if (widget.onEditPicks != null)
            IconButton(
              icon: const Icon(Icons.edit, color: AppTheme.primaryBlue),
              onPressed: widget.onEditPicks,
              tooltip: 'Edit Picks',
            ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Week header
                _buildWeekHeader(theme, weekNumber),
                
                const SizedBox(height: 24),
                
                // Picks summary
                _buildPicksSummary(theme),
                
                const SizedBox(height: 24),
                
                // Game picks list
                _buildGamePicksList(theme),
                
                const SizedBox(height: 24),
                
                // Tiebreaker section
                _buildTiebreakerSection(theme),
                
                const SizedBox(height: 32),
                
                // Action buttons
                _buildActionButtons(),
                
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeekHeader(ThemeData theme, String weekNumber) {
    return Container(
      width: double.infinity,
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
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.sports_football,
            color: Colors.white,
            size: 32,
          ),
          const SizedBox(height: 12),
          Text(
            'Week $weekNumber Picks',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Review your selections before submitting',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPicksSummary(ThemeData theme) {
    final totalGames = widget.games.length;
    final completedPicks = widget.userPicks.length;
    final hasTiebreaker = widget.tieBreakerController.text.isNotEmpty;
    final isComplete = completedPicks == totalGames && hasTiebreaker;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isComplete ? AppTheme.success.withOpacity(0.1) : AppTheme.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isComplete ? AppTheme.success.withOpacity(0.3) : AppTheme.warning.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isComplete ? AppTheme.success : AppTheme.warning,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  isComplete ? Icons.check_circle : Icons.warning_amber,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isComplete ? 'Ready to Submit' : 'Incomplete Picks',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: isComplete ? AppTheme.success : AppTheme.warning,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isComplete 
                          ? 'All picks completed successfully'
                          : 'Please complete all picks and tiebreaker',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  theme,
                  'Game Picks',
                  '$completedPicks/$totalGames',
                  completedPicks == totalGames ? AppTheme.success : AppTheme.warning,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryItem(
                  theme,
                  'Tiebreaker',
                  hasTiebreaker ? 'Complete' : 'Missing',
                  hasTiebreaker ? AppTheme.success : AppTheme.warning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(ThemeData theme, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGamePicksList(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Game Picks',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(height: 16),
        
        ...widget.games.asMap().entries.map((entry) {
          final index = entry.key;
          final game = entry.value;
          return _buildGamePickCard(theme, game, index + 1);
        }).toList(),
      ],
    );
  }

  Widget _buildGamePickCard(ThemeData theme, Map<String, dynamic> game, int gameNumber) {
    final homeTeam = game['abbreviation'] ?? '';
    final awayTeam = game['abbreviation2'] ?? '';
    final homeTeamName = game['fullname'] ?? homeTeam;
    final awayTeamName = game['fullname2'] ?? awayTeam;
    final gameId = '${homeTeam}_vs_${awayTeam}_${game['date']}';
    final selectedTeam = widget.userPicks[gameId];
    final hasSelection = selectedTeam != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasSelection ? AppTheme.success.withOpacity(0.3) : AppTheme.outline,
          width: hasSelection ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Game header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Game $gameNumber',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              if (hasSelection)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.success,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Selected',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Teams and selection
          Row(
            children: [
              // Away team
              Expanded(
                child: _buildTeamDisplay(
                  theme,
                  awayTeamName,
                  awayTeam,
                  selectedTeam == awayTeam,
                  true,
                ),
              ),
              
              // VS separator
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'VS',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppTheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              // Home team
              Expanded(
                child: _buildTeamDisplay(
                  theme,
                  homeTeamName,
                  homeTeam,
                  selectedTeam == homeTeam,
                  false,
                ),
              ),
            ],
          ),
          
          if (!hasSelection) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_outlined,
                    color: AppTheme.warning,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'No selection made',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.warning,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTeamDisplay(ThemeData theme, String teamName, String teamAbbr, bool isSelected, bool isAway) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.success.withOpacity(0.1) : AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? AppTheme.success : AppTheme.outline,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          // Team logo placeholder
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.success : AppTheme.onSurfaceVariant,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                teamAbbr,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            teamAbbr,
            style: theme.textTheme.titleSmall?.copyWith(
              color: isSelected ? AppTheme.success : AppTheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 4),
          
          Text(
            isAway ? 'Away' : 'Home',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.onSurfaceVariant,
            ),
          ),
          
          if (isSelected) ...[
            const SizedBox(height: 4),
            Icon(
              Icons.check_circle,
              color: AppTheme.success,
              size: 16,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTiebreakerSection(ThemeData theme) {
    final hasTiebreaker = widget.tieBreakerController.text.isNotEmpty;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasTiebreaker ? AppTheme.success.withOpacity(0.3) : AppTheme.outline,
          width: hasTiebreaker ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.sports_score,
                color: hasTiebreaker ? AppTheme.success : AppTheme.onSurfaceVariant,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Tiebreaker',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (hasTiebreaker)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.success,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Complete',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Text(
            'Monday Night Football Total Points',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.onSurfaceVariant,
            ),
          ),
          
          const SizedBox(height: 16),
          
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: hasTiebreaker ? AppTheme.success.withOpacity(0.1) : AppTheme.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasTiebreaker ? AppTheme.success.withOpacity(0.3) : AppTheme.warning.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  hasTiebreaker ? Icons.check_circle : Icons.warning_amber,
                  color: hasTiebreaker ? AppTheme.success : AppTheme.warning,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  hasTiebreaker 
                      ? 'Your prediction: ${widget.tieBreakerController.text} points'
                      : 'No tiebreaker entered',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: hasTiebreaker ? AppTheme.success : AppTheme.warning,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Edit picks button
        if (widget.onEditPicks != null)
          AuthButton(
            text: 'Edit Picks',
            icon: Icons.edit,
            type: AuthButtonType.outline,
            onPressed: widget.onEditPicks,
          ),
        
        if (widget.onEditPicks != null) const SizedBox(height: 16),
        
        // Submit picks button
        AuthButton(
          text: 'Submit Picks',
          icon: Icons.send,
          type: AuthButtonType.primary,
          onPressed: _handleSubmitPicks,
        ),
      ],
    );
  }

  void _handleSubmitPicks() async {
    final validationService = PicksValidationService();
    
    // Validate picks with detailed alert
    final isValid = await validationService.validateAndShowAlert(
      context: context,
      games: widget.games,
      userPicks: widget.userPicks,
      tiebreakerValue: widget.tieBreakerController.text,
      onFixPicks: widget.onEditPicks,
    );
    
    if (!isValid) return;
    
    // Show confirmation dialog
    final shouldSubmit = await validationService.showSubmissionConfirmation(
      context: context,
      totalPicks: widget.userPicks.length,
      tiebreakerValue: widget.tieBreakerController.text,
    );
    
    if (shouldSubmit && widget.onSubmitPicks != null) {
      widget.onSubmitPicks!();
    }
  }
}
