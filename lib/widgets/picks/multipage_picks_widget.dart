import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:poolqapp/constants/app_theme.dart';
import 'package:poolqapp/Provider/homeProvider.dart';
import 'package:poolqapp/widgets/auth/auth_button.dart';
import 'package:poolqapp/widgets/picks/review_picks_widget.dart';

/// Enhanced multipage picks widget with grouped games by start times
class MultipagePicksWidget extends StatefulWidget {
  final List<Map<String, dynamic>> games;
  final TextEditingController tieBreakerController;
  final VoidCallback? onSubmit;

  const MultipagePicksWidget({
    Key? key,
    required this.games,
    required this.tieBreakerController,
    this.onSubmit,
  }) : super(key: key);

  @override
  State<MultipagePicksWidget> createState() => _MultipagePicksWidgetState();
}

class _MultipagePicksWidgetState extends State<MultipagePicksWidget>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  
  int _currentPageIndex = 0;
  List<GameTimeGroup> _gameGroups = [];
  Map<String, String> _userPicks = {};
  
  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _groupGamesByStartTime();
  }

  void _initializeControllers() {
    _pageController = PageController();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _fadeController.forward();
    _slideController.forward();
  }

  void _groupGamesByStartTime() {
    // Group games by start time
    Map<String, List<Map<String, dynamic>>> timeGroups = {};
    
    for (var game in widget.games) {
      String gameTime = _extractGameTime(game);
      if (!timeGroups.containsKey(gameTime)) {
        timeGroups[gameTime] = [];
      }
      timeGroups[gameTime]!.add(game);
    }
    
    // Convert to sorted list of GameTimeGroup objects
    _gameGroups = timeGroups.entries
        .map((entry) => GameTimeGroup(
              timeSlot: entry.key,
              games: entry.value,
            ))
        .toList();
    
    // Sort by time (earliest first)
    _gameGroups.sort((a, b) => _compareTimeSlots(a.timeSlot, b.timeSlot));
    
    // Add tiebreaker page at the end
    _gameGroups.add(GameTimeGroup(
      timeSlot: 'Tiebreaker',
      games: [],
      isTiebreakerPage: true,
    ));
  }

  String _extractGameTime(Map<String, dynamic> game) {
    try {
      // First try to get time from 'time' field
      String timeStr = game['time'] ?? '';
      if (timeStr.isNotEmpty) {
        return timeStr;
      }
      
      // Extract time from date field (primary source)
      String dateStr = game['date'] ?? '';
      if (dateStr.isNotEmpty) {
        // Try to parse and extract time
        DateTime? dateTime = DateTime.tryParse(dateStr);
        if (dateTime != null) {
          int hour = dateTime.hour;
          int minute = dateTime.minute;
          String period = hour >= 12 ? 'PM' : 'AM';
          int displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
          return '${displayHour}:${minute.toString().padLeft(2, '0')} $period';
        }
      }
      
      // Fallback: try to extract from formatted date string
      String formattedDate = game['formattedDate'] ?? '';
      if (formattedDate.isNotEmpty) {
        // Extract time from formatted date like "Friday September 5TH, 2025"
        // This is a fallback for when we have formatted dates
        return 'TBD';
      }
      
      return 'TBD';
    } catch (e) {
      return 'TBD';
    }
  }

  int _compareTimeSlots(String timeA, String timeB) {
    if (timeA == 'TBD') return 1;
    if (timeB == 'TBD') return -1;
    
    try {
      // Simple time comparison - convert to 24-hour format for comparison
      int hourA = _parseTimeToMinutes(timeA);
      int hourB = _parseTimeToMinutes(timeB);
      return hourA.compareTo(hourB);
    } catch (e) {
      return timeA.compareTo(timeB);
    }
  }

  int _parseTimeToMinutes(String timeStr) {
    try {
      // Parse "1:00 PM" format
      RegExp timeRegex = RegExp(r'(\d+):(\d+)\s*(AM|PM)');
      Match? match = timeRegex.firstMatch(timeStr);
      
      if (match != null) {
        int hour = int.parse(match.group(1)!);
        int minute = int.parse(match.group(2)!);
        String period = match.group(3)!;
        
        if (period == 'PM' && hour != 12) hour += 12;
        if (period == 'AM' && hour == 12) hour = 0;
        
        return hour * 60 + minute;
      }
    } catch (e) {
      // Fallback
    }
    return 0;
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        children: [
          // Progress indicator
          _buildProgressIndicator(),
          
          const SizedBox(height: 16),
          
          // Page content
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              itemCount: _gameGroups.length,
              itemBuilder: (context, index) {
                return _buildGameGroupPage(_gameGroups[index], index);
              },
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Navigation buttons
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Step ${_currentPageIndex + 1} of ${_gameGroups.length}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                _gameGroups.isNotEmpty ? _gameGroups[_currentPageIndex].timeSlot : '',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (_currentPageIndex + 1) / _gameGroups.length,
            backgroundColor: AppTheme.outline,
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
          ),
        ],
      ),
    );
  }

  Widget _buildGameGroupPage(GameTimeGroup group, int pageIndex) {
    if (group.isTiebreakerPage) {
      return _buildTiebreakerPage();
    }
    
    return FadeTransition(
      opacity: _fadeController,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.3, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _slideController,
          curve: Curves.easeOutCubic,
        )),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Time slot header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryBlue,
                      AppTheme.primaryBlue.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.schedule,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      group.timeSlot,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${group.games.length} game${group.games.length != 1 ? 's' : ''}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Games for this time slot
              ...group.games.asMap().entries.map((entry) {
                int gameIndex = entry.key;
                Map<String, dynamic> game = entry.value;
                return _buildGameCard(game, gameIndex);
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameCard(Map<String, dynamic> game, int gameIndex) {
    final theme = Theme.of(context);
    final homeTeam = game['abbreviation'] ?? '';
    final awayTeam = game['abbreviation2'] ?? '';
    final gameId = '${homeTeam}_vs_${awayTeam}_${game['date']}';
    final currentPick = _userPicks[gameId];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: currentPick != null ? AppTheme.primaryBlue : AppTheme.outline,
          width: currentPick != null ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
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
                    'GAME ${gameIndex + 1}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                if (currentPick != null)
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
                          'Picked',
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
            
            const SizedBox(height: 16),
            
            // Teams selection
            Row(
              children: [
                // Away team
                Expanded(
                  child: _buildTeamOption(
                    teamName: game['fullname2'] ?? '',
                    teamAbbr: awayTeam,
                    teamLogo: game['picture2'] ?? '',
                    isSelected: currentPick == awayTeam,
                    onTap: () => _selectTeam(gameId, awayTeam),
                    isAway: true,
                  ),
                ),
                
                // VS separator
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      Text(
                        'VS',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppTheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 2,
                        height: 30,
                        color: AppTheme.outline,
                      ),
                    ],
                  ),
                ),
                
                // Home team
                Expanded(
                  child: _buildTeamOption(
                    teamName: game['fullname'] ?? '',
                    teamAbbr: homeTeam,
                    teamLogo: game['picture'] ?? '',
                    isSelected: currentPick == homeTeam,
                    onTap: () => _selectTeam(gameId, homeTeam),
                    isAway: false,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.3, curve: Curves.easeOutCubic);
  }

  Widget _buildTeamOption({
    required String teamName,
    required String teamAbbr,
    required String teamLogo,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isAway,
  }) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryBlue.withOpacity(0.1) : AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryBlue : AppTheme.outline,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            // Team logo placeholder
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryBlue : AppTheme.onSurfaceVariant,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  teamAbbr,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Team abbreviation
            Text(
              teamAbbr,
              style: theme.textTheme.titleMedium?.copyWith(
                color: isSelected ? AppTheme.primaryBlue : AppTheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 4),
            
            // Away/Home indicator
            Text(
              isAway ? 'Away' : 'Home',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTiebreakerPage() {
    final theme = Theme.of(context);
    
    return FadeTransition(
      opacity: _fadeController,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.3, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _slideController,
          curve: Curves.easeOutCubic,
        )),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tiebreaker header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.accentOrange,
                      AppTheme.accentOrange.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
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
                      'Tiebreaker',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Predict the total points in Monday Night Football',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Tiebreaker input
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.outline,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Points Prediction',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter your prediction for the combined score of both teams in the Monday Night Football game.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: widget.tieBreakerController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Enter total points (e.g., 45)',
                        prefixIcon: Icon(
                          Icons.sports_score,
                          color: AppTheme.primaryBlue,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppTheme.primaryBlue,
                            width: 2,
                          ),
                        ),
                      ),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Instructions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.info.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppTheme.info,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'The tiebreaker is used to determine the winner if multiple players have the same number of correct picks.',
                        style: theme.textTheme.bodyMedium?.copyWith(
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
      ),
    );
  }

  Widget _buildNavigationButtons() {
    final isFirstPage = _currentPageIndex == 0;
    final isLastPage = _currentPageIndex == _gameGroups.length - 1;
    final canProceed = _canProceedToNextPage();
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Previous button
          if (!isFirstPage)
            Expanded(
              child: AuthButton(
                text: 'Previous',
                icon: Icons.arrow_back,
                type: AuthButtonType.outline,
                onPressed: _goToPreviousPage,
              ),
            ),
          
          if (!isFirstPage && !isLastPage) const SizedBox(width: 16),
          
          // Next/Submit button
          Expanded(
            flex: isFirstPage ? 1 : 1,
            child: AuthButton(
              text: isLastPage ? 'Submit Picks' : 'Next',
              icon: isLastPage ? Icons.check : Icons.arrow_forward,
              type: AuthButtonType.primary,
              onPressed: canProceed ? (isLastPage ? _submitPicks : _goToNextPage) : null,
            ),
          ),
        ],
      ),
    );
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPageIndex = index;
    });
    
    // Restart animations for the new page
    _fadeController.reset();
    _slideController.reset();
    _fadeController.forward();
    _slideController.forward();
  }

  void _selectTeam(String gameId, String teamAbbr) {
    setState(() {
      _userPicks[gameId] = teamAbbr;
    });
    
    // Update the provider with the pick
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    // Add to playerPicks list if not already present
    if (dataProvider.playerPicks != null) {
      // Remove any existing pick for this game first
      dataProvider.playerPicks!.removeWhere((pick) => pick.startsWith(gameId));
      // Add the new pick
      dataProvider.addToPlayerPicks('$gameId:$teamAbbr');
    }
  }

  bool _canProceedToNextPage() {
    if (_currentPageIndex == _gameGroups.length - 1) {
      // Last page (tiebreaker) - check if tiebreaker is filled
      return widget.tieBreakerController.text.isNotEmpty;
    }
    
    // Check if all games in current page have picks
    final currentGroup = _gameGroups[_currentPageIndex];
    for (var game in currentGroup.games) {
      final homeTeam = game['abbreviation'] ?? '';
      final awayTeam = game['abbreviation2'] ?? '';
      final gameId = '${homeTeam}_vs_${awayTeam}_${game['date']}';
      if (!_userPicks.containsKey(gameId)) {
        return false;
      }
    }
    return true;
  }

  void _goToPreviousPage() {
    if (_currentPageIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToNextPage() {
    if (_currentPageIndex < _gameGroups.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _submitPicks() async {
    // Navigate to review picks page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReviewPicksWidget(
          games: widget.games,
          userPicks: _userPicks,
          tieBreakerController: widget.tieBreakerController,
          onEditPicks: () {
            // Go back to multipage picks to edit
            Navigator.of(context).pop();
            _navigateToFirstIncompletePage();
          },
          onSubmitPicks: () {
            // Navigate to the old PlayerPicksWidget for final submission
            Navigator.of(context).pop(); // Close review page
            if (widget.onSubmit != null) {
              widget.onSubmit!();
            }
          },
        ),
      ),
    );
  }

  void _navigateToFirstIncompletePage() {
    // Find the first page with incomplete picks
    for (int i = 0; i < _gameGroups.length - 1; i++) { // -1 to exclude tiebreaker page
      final group = _gameGroups[i];
      bool hasIncompletePicks = false;
      
      for (var game in group.games) {
        final homeTeam = game['abbreviation'] ?? '';
        final awayTeam = game['abbreviation2'] ?? '';
        final gameId = '${homeTeam}_vs_${awayTeam}_${game['date']}';
        if (!_userPicks.containsKey(gameId)) {
          hasIncompletePicks = true;
          break;
        }
      }
      
      if (hasIncompletePicks) {
        _pageController.animateToPage(
          i,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        return;
      }
    }
    
    // If all game picks are complete, check tiebreaker
    if (widget.tieBreakerController.text.isEmpty) {
      _pageController.animateToPage(
        _gameGroups.length - 1, // Navigate to tiebreaker page
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }
}

/// Data class for grouping games by time slot
class GameTimeGroup {
  final String timeSlot;
  final List<Map<String, dynamic>> games;
  final bool isTiebreakerPage;

  GameTimeGroup({
    required this.timeSlot,
    required this.games,
    this.isTiebreakerPage = false,
  });
}
