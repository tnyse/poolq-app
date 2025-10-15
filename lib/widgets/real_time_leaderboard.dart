import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../services/scoring_service.dart';
import '../Model/pick_model.dart';
import '../constants.dart';
import '../Provider/homeProvider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RealTimeLeaderboard extends StatefulWidget {
  final String weekName;
  final bool showUserHighlight;

  const RealTimeLeaderboard({
    Key? key,
    required this.weekName,
    this.showUserHighlight = true,
  }) : super(key: key);

  @override
  _RealTimeLeaderboardState createState() => _RealTimeLeaderboardState();
}

class _RealTimeLeaderboardState extends State<RealTimeLeaderboard> {
  final ScoringService _scoringService = ScoringService();
  User? _currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    print('⚡⚡⚡ REAL TIME LEADERBOARD WIDGET IS BUILDING! ⚡⚡⚡');
    print('RealTimeLeaderboard: Building widget for week ${widget.weekName}');
    print('RealTimeLeaderboard: Current user: ${_currentUser?.uid ?? "null"}');
    print('RealTimeLeaderboard: Show user highlight: ${widget.showUserHighlight}');
    
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('pickrecord')
          .where('week', isEqualTo: widget.weekName)
          .where('paymentStatus', isEqualTo: 'verified')
          .orderBy('score', descending: true)
          .orderBy('tiebreakerDiff', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        print('RealTimeLeaderboard: StreamBuilder state - Connection: ${snapshot.connectionState}');
        print('RealTimeLeaderboard: StreamBuilder state - HasData: ${snapshot.hasData}');
        print('RealTimeLeaderboard: StreamBuilder state - HasError: ${snapshot.hasError}');
        
        if (snapshot.hasError) {
          print('RealTimeLeaderboard: ERROR in StreamBuilder: ${snapshot.error}');
          return _buildErrorWidget('Error loading leaderboard: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          print('RealTimeLeaderboard: Loading leaderboard data...');
          return _buildLoadingWidget();
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          print('RealTimeLeaderboard: No data available - docs count: ${snapshot.data?.docs.length ?? 0}');
          return _buildEmptyWidget();
        }

        print('RealTimeLeaderboard: Processing ${snapshot.data!.docs.length} documents');
        
        try {
          final picks = snapshot.data!.docs
              .map((doc) {
                print('RealTimeLeaderboard: Processing document ${doc.id}');
                try {
                  final pick = PickModel.fromFirestore(doc);
                  print('RealTimeLeaderboard: Successfully parsed pick for ${pick.displayName}');
                  return pick;
                } catch (e) {
                  print('RealTimeLeaderboard: ERROR parsing document ${doc.id}: $e');
                  print('RealTimeLeaderboard: Document data: ${doc.data()}');
                  rethrow;
                }
              })
              .toList();

          print('RealTimeLeaderboard: Successfully processed ${picks.length} picks');
          return _buildLeaderboardList(picks);
        } catch (e, stackTrace) {
          print('RealTimeLeaderboard: ERROR processing picks: $e');
          print('RealTimeLeaderboard: Stack trace: $stackTrace');
          return _buildErrorWidget('Error processing leaderboard data: $e');
        }
      },
    );
  }

  Widget _buildLeaderboardList(List<PickModel> picks) {
    return Column(
      children: [
        // Header
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.leaderboard, color: primary),
              SizedBox(width: 8),
              Text(
                'Week ${widget.weekName} Leaderboard',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primary,
                ),
              ),
              Spacer(),
              Text(
                '${picks.length} Players',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16),
        
        // Leaderboard List
        Expanded(
          child: ListView.builder(
            itemCount: picks.length,
            itemBuilder: (context, index) {
              final pick = picks[index];
              final isCurrentUser = pick.userId == _currentUser?.uid;
              
              return _buildLeaderboardItem(pick, index + 1, isCurrentUser);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardItem(PickModel pick, int rank, bool isCurrentUser) {
    print('RealTimeLeaderboard: Building item for ${pick.displayName} - Rank: $rank, Current User: $isCurrentUser');
    print('RealTimeLeaderboard: Pick details - Score: ${pick.score}, Picks: ${pick.picks?.length ?? 0}, Tiebreaker: ${pick.tiebreaker}');
    
    final isTopThree = rank <= 3;
    
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isCurrentUser ? primary.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentUser ? primary : Colors.grey[300]!,
          width: isCurrentUser ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _getRankColor(rank),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              rank.toString(),
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                pick.displayName,
                style: TextStyle(
                  fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.w500,
                  color: isCurrentUser ? primary : Colors.black87,
                ),
              ),
            ),
            if (isCurrentUser)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'YOU',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Text(
          '${pick.score ?? 0} correct picks',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${pick.score ?? 0}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _getRankColor(rank),
              ),
            ),
            if (pick.tiebreakerDiff != null)
              Text(
                'TB: ${pick.tiebreakerDiff}',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[500],
                ),
              ),
          ],
        ),
        onTap: () {
          print('🎯🎯🎯 REAL-TIME LEADERBOARD CLICK DETECTED! Player: ${pick.displayName}');
          
          // Show alert dialog first to confirm click detection
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('🎯 RealTime Click Detected!'),
                content: Text('You successfully clicked on "${pick.displayName}"! \n\nThis is from RealTimeLeaderboard widget. \n\nWould you like to view their picks?'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close dialog
                      // Then show picks
                      _showPlayerPicks(context, pick);
                    },
                    child: Text('Yes, View Picks'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Just close dialog
                    },
                    child: Text('Cancel'),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  void _showPlayerPicks(BuildContext context, PickModel pick) {
    print('RealTimeLeaderboard: User tapped on ${pick.displayName} (${pick.userId})');
    print('RealTimeLeaderboard: Pick data - Score: ${pick.score}, Week: ${pick.week}, Picks: ${pick.picks}');
    
    try {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          print('RealTimeLeaderboard: Building dialog for ${pick.displayName}');
          return AlertDialog(
            title: Text('${pick.displayName}\'s Picks'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Week: ${pick.week}',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text('Score: ${pick.score ?? 0}'),
                SizedBox(height: 8),
                if (pick.tiebreaker != null)
                  Text('Tiebreaker: ${pick.tiebreaker}'),
                SizedBox(height: 16),
                Text(
                  'Picks:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                if (pick.picks != null && pick.picks!.isNotEmpty)
                  ...pick.picks!.map((pickTeam) => Padding(
                    padding: EdgeInsets.symmetric(vertical: 2),
                    child: Text('• $pickTeam'),
                  ))
                else
                  Text('No picks available'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  print('RealTimeLeaderboard: Closing dialog for ${pick.displayName}');
                  Navigator.of(context).pop();
                },
                child: Text('Close'),
              ),
            ],
          );
        },
      );
      print('RealTimeLeaderboard: Dialog shown successfully for ${pick.displayName}');
    } catch (e, stackTrace) {
      print('RealTimeLeaderboard: ERROR showing dialog for ${pick.displayName}: $e');
      print('RealTimeLeaderboard: Stack trace: $stackTrace');
      
      // Fallback: Show a simple snackbar with the error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading picks for ${pick.displayName}: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber[700]!;
      case 2:
        return Colors.grey[400]!;
      case 3:
        return Colors.brown[400]!;
      default:
        return primary;
    }
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: primary),
          SizedBox(height: 16),
          Text(
            'Loading leaderboard...',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.leaderboard_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'No entries yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Be the first to submit your picks!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[400],
          ),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.red[600],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                // Trigger rebuild
              });
            },
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }
} 