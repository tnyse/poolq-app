import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Provider/homeProvider.dart';
import '../Module/Screen/Home/picked.dart';
import '../Module/Screen/Home/EditPlay.dart';

class EnhancedLeaderboard extends StatefulWidget {
  const EnhancedLeaderboard({super.key});

  @override
  State<EnhancedLeaderboard> createState() => _EnhancedLeaderboardState();
}

class _EnhancedLeaderboardState extends State<EnhancedLeaderboard> {
  User? user = FirebaseAuth.instance.currentUser;
  List<Map<String, dynamic>>? leaderboardData;
  bool isLoading = true;
  bool deadlinePassed = false;

  @override
  void initState() {
    super.initState();
    _loadLeaderboardData();
  }

  Future<void> _loadLeaderboardData() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Simulate deadline checking - for demo, let's say deadline hasn't passed yet
      // In real app, this would check against actual game times
      deadlinePassed = false; // Will be true after entry deadline

      // Load demo leaderboard data
      List<Map<String, dynamic>> mockLeaderboard = [
        {
          "uid": "demo_user",
          "displayName": "Demo User",
          "photoURL": "",
          "score": 0,
          "picks": ["DET", "CLE", "WAS"],
          "tiebreaker": 55,
          "rank": 1,
          "week": "PRE1",
        },
        {
          "uid": "john_doe",
          "displayName": "John Doe", 
          "photoURL": "",
          "score": 0,
          "picks": ["ATL", "CAR", "NE"],
          "tiebreaker": 45,
          "rank": 2,
          "week": "PRE1",
        },
        {
          "uid": "jane_smith",
          "displayName": "Jane Smith",
          "photoURL": "",
          "score": 0,
          "picks": ["DET", "CLE", "WAS"],
          "tiebreaker": 72,
          "rank": 3,
          "week": "PRE1",
        },
        {
          "uid": "mike_wilson",
          "displayName": "Mike Wilson",
          "photoURL": "",
          "score": 0,
          "picks": ["ATL", "CAR", "WAS"],
          "tiebreaker": 38,
          "rank": 4,
          "week": "PRE1",
        },
        {
          "uid": "sarah_jones",
          "displayName": "Sarah Jones",
          "photoURL": "",
          "score": 0,
          "picks": ["DET", "CLE", "NE"],
          "tiebreaker": 61,
          "rank": 5,
          "week": "PRE1",
        },
      ];

      setState(() {
        leaderboardData = mockLeaderboard;
        isLoading = false;
      });

    } catch (e) {
      print('Error loading leaderboard data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dataProvider = Provider.of<DataProvider>(context);
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/gb.jpeg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // PoolQ Logo
                      Container(
                        width: 150,
                        height: 90,
                        child: Image.asset(
                          'assets/images/poolq12.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'WEEK ${dataProvider.game?["name"]?.toString().replaceAll("REG", "").replaceAll("PRE", "") ?? "1"} LEADERBOARD',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        deadlinePassed 
                          ? 'Entry deadline has passed - Click to view picks'
                          : 'Entry deadline not yet reached',
                        style: TextStyle(
                          color: deadlinePassed ? Colors.green : Colors.orange,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Leaderboard List
                Expanded(
                  child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      )
                    : leaderboardData == null || leaderboardData!.isEmpty
                        ? const Center(
                            child: Text(
                              'No entries yet',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: leaderboardData!.length,
                            itemBuilder: (context, index) {
                              final entry = leaderboardData![index];
                              final isCurrentUser = entry['uid'] == (user?.uid ?? 'demo_user');
                              
                              return Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                decoration: BoxDecoration(
                                  color: isCurrentUser 
                                    ? Colors.blue.withOpacity(0.8)
                                    : Colors.white.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(12),
                                  border: isCurrentUser 
                                    ? Border.all(color: Colors.white, width: 2)
                                    : null,
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: isCurrentUser ? Colors.white : Colors.grey[300],
                                    child: Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        color: isCurrentUser ? Colors.blue : Colors.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    entry['displayName'].toString().toUpperCase(),
                                    style: TextStyle(
                                      color: isCurrentUser ? Colors.white : Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'Score: ${entry['score'] ?? 0} | Tiebreaker: ${entry['tiebreaker']}',
                                    style: TextStyle(
                                      color: isCurrentUser ? Colors.white70 : Colors.grey[600],
                                    ),
                                  ),
                                  trailing: deadlinePassed
                                    ? const Icon(
                                        Icons.arrow_forward_ios,
                                        color: Colors.grey,
                                        size: 16,
                                      )
                                    : isCurrentUser
                                        ? const Icon(
                                            Icons.edit,
                                            color: Colors.white,
                                          )
                                        : null,
                                  onTap: () {
                                    if (deadlinePassed) {
                                      // Show picks after deadline
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => PickedWidget(
                                            userId: entry['uid'],
                                            selectedValue: dataProvider.game?["name"]?.toString().replaceAll("REG", "").replaceAll("PRE", "") ?? "1",
                                          ),
                                        ),
                                      );
                                    } else if (isCurrentUser) {
                                      // Allow editing own picks before deadline
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const EditPlayWidget(),
                                        ),
                                      );
                                    } else {
                                      // Show message that deadline hasn't passed
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Picks will be visible after entry deadline'),
                                          backgroundColor: Colors.orange,
                                        ),
                                      );
                                    }
                                  },
                                ),
                              );
                            },
                          ),
                ),
                
                // Bottom action button
                Container(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'BACK TO HOME',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}