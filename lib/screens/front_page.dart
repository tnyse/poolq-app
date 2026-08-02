import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:poolqapp/constants/app_theme.dart';
import 'package:poolqapp/widgets/auth/auth_button.dart';
import 'package:poolqapp/services/nfl_schedule_service.dart';
import 'package:poolqapp/services/simulation_controller.dart';
import 'package:poolqapp/Provider/homeProvider.dart';
import 'package:poolqapp/Module/Screen/Home/HomePage.dart';

/// Front page displaying NFL news, previous week results, and current week info
class FrontPage extends StatefulWidget {
  const FrontPage({Key? key}) : super(key: key);

  @override
  State<FrontPage> createState() => _FrontPageState();
}

class _FrontPageState extends State<FrontPage> with TickerProviderStateMixin {
  final NFLScheduleService _nflService = NFLScheduleService();
  final SimulationController _simulationController = SimulationController();
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  List<Map<String, dynamic>> _previousWeekGames = [];
  List<Map<String, dynamic>> _currentWeekGames = [];
  Map<String, dynamic>? _weeklyWinner;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadFrontPageData();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    // Start animations
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _slideController.forward();
    });
  }

  Future<void> _loadFrontPageData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Load previous week results (REG1 has completed games)
      final previousWeekGames = await _nflService.getScheduleForWeekWithLocalFallback('REG1');
      final completedGames = previousWeekGames
          .where((game) => game['completed'] == true)
          .take(6) // Show top 6 games
          .toList();

      // Load current week schedule (for upcoming games)
      final currentWeekGames = await _nflService.getScheduleForWeekWithLocalFallback('REG1');
      final upcomingGames = currentWeekGames
          .where((game) => game['completed'] != true)
          .take(4) // Show next 4 games
          .toList();

      // Get simulation results for winner display
      final simulationStatus = _simulationController.getSimulationStatus();
      Map<String, dynamic>? winner;
      if (simulationStatus['hasResults'] == true) {
        final results = simulationStatus['results'];
        if (results != null && results['leaderboard'] != null && results['leaderboard'].isNotEmpty) {
          winner = results['leaderboard'][0]; // Top player
        }
      }

      setState(() {
        _previousWeekGames = completedGames;
        _currentWeekGames = upcomingGames;
        _weeklyWinner = winner;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load NFL data: $e';
        _isLoading = false;
      });
    }
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
    final size = MediaQuery.of(context).size;
    
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
          'PoolQ News',
          style: theme.textTheme.titleLarge?.copyWith(
            color: AppTheme.primaryBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue))
          : _errorMessage != null
              ? _buildErrorState()
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: size.width > 600 ? 600 : double.infinity,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildWelcomeSection(),
                            const SizedBox(height: 24),
                            _buildWeeklyWinnerSection(),
                            const SizedBox(height: 24),
                            _buildPreviousWeekSection(),
                            const SizedBox(height: 24),
                            _buildCurrentWeekSection(),
                            const SizedBox(height: 32),
                            _buildCallToActionSection(),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppTheme.error.withOpacity(0.7),
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to load NFL data',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Please try again later',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            AuthButton(
              text: 'Retry',
              icon: Icons.refresh,
              type: AuthButtonType.outline,
              onPressed: _loadFrontPageData,
              fullWidth: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    final theme = Theme.of(context);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
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
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.sports_football,
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
                      'Welcome to PoolQ',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Your NFL Pick\'em Experience',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Stay up to date with the latest NFL results, see who\'s winning, and make your picks for the upcoming week!',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(0.9),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyWinnerSection() {
    if (_weeklyWinner == null) return const SizedBox.shrink();
    
    final theme = Theme.of(context);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.success.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.success,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.emoji_events,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Weekly Champion',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppTheme.success,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '🏆 ${_weeklyWinner!['displayName']} leads with ${_weeklyWinner!['score']} correct picks!',
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Congratulations on a great week of predictions!',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviousWeekSection() {
    if (_previousWeekGames.isEmpty) return const SizedBox.shrink();
    
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.history,
              color: AppTheme.primaryBlue,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Week 1 Results',
              style: theme.textTheme.titleLarge?.copyWith(
                color: AppTheme.primaryBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...(_previousWeekGames.take(3).map((game) => _buildGameResultCard(game))),
        if (_previousWeekGames.length > 3)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Center(
              child: TextButton(
                onPressed: () {
                  // Navigate to full results page
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Full results page coming soon!'),
                      backgroundColor: AppTheme.info,
                    ),
                  );
                },
                child: Text(
                  'View All ${_previousWeekGames.length} Results',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCurrentWeekSection() {
    if (_currentWeekGames.isEmpty) return const SizedBox.shrink();
    
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.schedule,
              color: AppTheme.accentOrange,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Upcoming Games',
              style: theme.textTheme.titleLarge?.copyWith(
                color: AppTheme.accentOrange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...(_currentWeekGames.take(2).map((game) => _buildUpcomingGameCard(game))),
        if (_currentWeekGames.length > 2)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Center(
              child: TextButton(
                onPressed: () {
                  // Navigate to full schedule
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => HomePage()),
                  );
                },
                child: Text(
                  'View Full Schedule',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.accentOrange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildGameResultCard(Map<String, dynamic> game) {
    final theme = Theme.of(context);
    final homeTeam = game['homeTeam'];
    final awayTeam = game['awayTeam'];
    final homeScore = game['homeScore'] ?? 0;
    final awayScore = game['awayScore'] ?? 0;
    final winner = homeScore > awayScore ? homeTeam['abbreviation'] : awayTeam['abbreviation'];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.outline,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Away team
          Expanded(
            child: Column(
              children: [
                Text(
                  awayTeam['abbreviation'],
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: winner == awayTeam['abbreviation'] ? FontWeight.bold : FontWeight.normal,
                    color: winner == awayTeam['abbreviation'] ? AppTheme.success : AppTheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$awayScore',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: winner == awayTeam['abbreviation'] ? AppTheme.success : AppTheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          
          // VS separator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Text(
                  'FINAL',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 2,
                  height: 20,
                  color: AppTheme.outline,
                ),
              ],
            ),
          ),
          
          // Home team
          Expanded(
            child: Column(
              children: [
                Text(
                  homeTeam['abbreviation'],
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: winner == homeTeam['abbreviation'] ? FontWeight.bold : FontWeight.normal,
                    color: winner == homeTeam['abbreviation'] ? AppTheme.success : AppTheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$homeScore',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: winner == homeTeam['abbreviation'] ? AppTheme.success : AppTheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingGameCard(Map<String, dynamic> game) {
    final theme = Theme.of(context);
    final homeTeam = game['homeTeam'];
    final awayTeam = game['awayTeam'];
    final gameDate = DateTime.parse(game['date']);
    final formattedDate = '${gameDate.month}/${gameDate.day}';
    final formattedTime = '${gameDate.hour}:${gameDate.minute.toString().padLeft(2, '0')}';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.outline,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Away team
          Expanded(
            child: Column(
              children: [
                Text(
                  awayTeam['abbreviation'],
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Away',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          
          // Game info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Text(
                  formattedDate,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formattedTime,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 2,
                  height: 16,
                  color: AppTheme.outline,
                ),
              ],
            ),
          ),
          
          // Home team
          Expanded(
            child: Column(
              children: [
                Text(
                  homeTeam['abbreviation'],
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Home',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallToActionSection() {
    final theme = Theme.of(context);
    
    return Container(
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
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentOrange.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.sports_football,
            size: 48,
            color: Colors.white,
          ),
          const SizedBox(height: 16),
          Text(
            'Ready to Play?',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Make your picks for this week and compete with other players!',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          AuthButton(
            text: 'Let\'s Play!',
            icon: Icons.play_arrow,
            type: AuthButtonType.primary,
            onPressed: () async {
              // Initialize game data and navigate to home
              try {
                final dataProvider = Provider.of<DataProvider>(context, listen: false);
                await dataProvider.getWeek();
                await dataProvider.getGame();
                
                if (mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => HomePage()),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error loading game data: $e'),
                      backgroundColor: AppTheme.error,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
