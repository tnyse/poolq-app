import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/simulation_controller.dart';
import '../services/time_simulation_service.dart';
import '../Model/pick_model.dart';

class ResultsAnnouncementPage extends StatefulWidget {
  final String weekName;
  
  const ResultsAnnouncementPage({
    Key? key,
    required this.weekName,
  }) : super(key: key);

  @override
  _ResultsAnnouncementPageState createState() => _ResultsAnnouncementPageState();
}

class _ResultsAnnouncementPageState extends State<ResultsAnnouncementPage>
    with TickerProviderStateMixin {
  final SimulationController _simController = SimulationController();
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  Map<String, dynamic>? _results;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadResults();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: Duration(milliseconds: 800),
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
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));
  }

  void _loadResults() async {
    await Future.delayed(Duration(milliseconds: 500)); // Dramatic pause
    
    final results = _simController.getCurrentWeekResults();
    setState(() {
      _results = results;
      _isLoading = false;
    });

    if (results != null) {
      _fadeController.forward();
      await Future.delayed(Duration(milliseconds: 300));
      _slideController.forward();
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
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isLoading ? _buildLoadingScreen() : _buildResultsScreen(),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
            strokeWidth: 3,
          ),
          SizedBox(height: 24),
          Text(
            'Calculating Results...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Analyzing ${widget.weekName} performances',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsScreen() {
    if (_results == null) {
      return Center(
        child: Text(
          'No results available',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      );
    }

    final leaderboard = _results!['leaderboard'] as List<dynamic>? ?? [];
    final gameResults = _results!['gameResults'] as List<dynamic>? ?? [];

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              _buildHeader(),
              SizedBox(height: 32),
              SlideTransition(
                position: _slideAnimation,
                child: _buildLeaderboard(leaderboard),
              ),
              SizedBox(height: 32),
              _buildGameResults(gameResults),
              SizedBox(height: 32),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Icon(
          Icons.emoji_events,
          color: Colors.amber,
          size: 64,
        ),
        SizedBox(height: 16),
        Text(
          '${widget.weekName} RESULTS',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Final Standings',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboard(List<dynamic> leaderboard) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey[900]!,
            Colors.grey[800]!,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(Icons.leaderboard, color: Colors.amber, size: 24),
                SizedBox(width: 12),
                Text(
                  'LEADERBOARD',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ...leaderboard.asMap().entries.map((entry) {
            final index = entry.key;
            final player = entry.value;
            return _buildPlayerRow(player, index);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildPlayerRow(Map<String, dynamic> player, int index) {
    final rank = player['rank'] ?? (index + 1);
    final name = player['displayName'] ?? 'Unknown';
    final score = player['score'] ?? 0;
    final tiebreaker = player['tiebreaker'] ?? 0;
    final tiebreakerDiff = player['tiebreakerDiff'];
    
    Color rankColor = Colors.white;
    IconData? rankIcon;
    
    if (rank == 1) {
      rankColor = Colors.amber;
      rankIcon = Icons.emoji_events;
    } else if (rank == 2) {
      rankColor = Colors.grey[300]!;
      rankIcon = Icons.workspace_premium;
    } else if (rank == 3) {
      rankColor = Colors.orange[300]!;
      rankIcon = Icons.workspace_premium;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[700]!,
            width: 0.5,
          ),
        ),
        color: rank == 1 ? Colors.amber.withOpacity(0.05) : null,
      ),
      child: Row(
        children: [
          // Rank
          Container(
            width: 40,
            child: Row(
              children: [
                if (rankIcon != null) 
                  Icon(rankIcon, color: rankColor, size: 20)
                else
                  Text(
                    '$rank',
                    style: TextStyle(
                      color: rankColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
          
          // Player name
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: rank <= 3 ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          
          // Score
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$score',
              style: TextStyle(
                color: Colors.blue[300],
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          SizedBox(width: 8),
          
          // Tiebreaker info
          if (tiebreakerDiff != null)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey[700],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'TB: $tiebreaker (±$tiebreakerDiff)',
                style: TextStyle(
                  color: Colors.grey[300],
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGameResults(List<dynamic> gameResults) {
    if (gameResults.isEmpty) return SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(Icons.sports_football, color: Colors.blue, size: 24),
                SizedBox(width: 12),
                Text(
                  'GAME RESULTS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ...gameResults.map((game) => _buildGameRow(game)).toList(),
        ],
      ),
    );
  }

  Widget _buildGameRow(Map<String, dynamic> game) {
    final homeTeam = game['homeTeam'] ?? '';
    final awayTeam = game['awayTeam'] ?? '';
    final homeScore = game['homeScore'] ?? 0;
    final awayScore = game['awayScore'] ?? 0;
    final winner = game['winner'] ?? '';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[700]!, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // Away team
          Expanded(
            child: Text(
              awayTeam,
              style: TextStyle(
                color: winner == awayTeam ? Colors.green : Colors.white,
                fontWeight: winner == awayTeam ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          
          // Score
          Text(
            '$awayScore - $homeScore',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          // Home team
          Expanded(
            child: Text(
              homeTeam,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: winner == homeTeam ? Colors.green : Colors.white,
                fontWeight: winner == homeTeam ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Back to Dashboard',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _advanceToNextWeek,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.white),
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Continue to Next Week',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _advanceToNextWeek() async {
    final success = await _simController.advanceToNextWeek();
    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Advanced to next week! Ready for new picks.'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to advance to next week.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
