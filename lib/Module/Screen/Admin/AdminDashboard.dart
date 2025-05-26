import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:poolqapp/Provider/homeProvider.dart';
import 'package:poolqapp/services/nfl_game_service.dart';
import 'package:poolqapp/Widget/AppDrawer.dart';
import 'package:poolqapp/Module/Screen/Admin/AdminStats.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final NFLGameService _gameService = NFLGameService();
  List<Map<String, dynamic>> _games = [];
  List<String> _winners = [];
  String _selectedWeek = "REG1";
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadGameData();
  }
  
  void _loadGameData() {
    setState(() {
      _games = _gameService.getMockGamesForWeek(_selectedWeek);
      _winners = _gameService.getWinnersForWeek(_selectedWeek);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Game Scores', icon: Icon(Icons.sports_football)),
            Tab(text: 'Winners', icon: Icon(Icons.emoji_events)),
            Tab(text: 'Statistics', icon: Icon(Icons.analytics)),
          ],
        ),
      ),
      drawer: AppDrawer(),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGameScoresTab(),
          _buildWinnersTab(),
          AdminStats(),
        ],
      ),
    );
  }

  Widget _buildGameScoresTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              const Text('Select Week: ', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 10),
              DropdownButton<String>(
                value: _selectedWeek,
                items: [
                  for (int i = 1; i <= 18; i++)
                    DropdownMenuItem(
                      value: 'REG$i',
                      child: Text('Week $i'),
                    )
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedWeek = value;
                      _loadGameData();
                    });
                  }
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _games.length,
            itemBuilder: (context, index) {
              final game = _games[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        game['date'] ?? 'Date unknown',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                CircleAvatar(
                                  backgroundImage: NetworkImage(game['picture'] ?? ''),
                                  radius: 25,
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  game['fullname'] ?? '',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  game['abbreviation'] ?? '',
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 60,
                                  child: TextFormField(
                                    textAlign: TextAlign.center,
                                    keyboardType: TextInputType.number,
                                    initialValue: game['score'] ?? '0',
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                    ),
                                    onChanged: (value) {
                                      setState(() {
                                        game['score'] = value;
                                      });
                                    },
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 8),
                                  child: Text(
                                    '-',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                                  ),
                                ),
                                SizedBox(
                                  width: 60,
                                  child: TextFormField(
                                    textAlign: TextAlign.center,
                                    keyboardType: TextInputType.number,
                                    initialValue: game['score2'] ?? '0',
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                    ),
                                    onChanged: (value) {
                                      setState(() {
                                        game['score2'] = value;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                CircleAvatar(
                                  backgroundImage: NetworkImage(game['picture2'] ?? ''),
                                  radius: 25,
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  game['fullname2'] ?? '',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  game['abbreviation2'] ?? '',
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              // Set winner for team 1
                              setState(() {
                                if (!_winners.contains(game['abbreviation'])) {
                                  _winners.add(game['abbreviation'] ?? '');
                                }
                                _winners.remove(game['abbreviation2']);
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('${game['fullname']} set as winner')),
                              );
                            },
                            icon: const Icon(Icons.check_circle),
                            label: const Text('Set as Winner'),
                          ),
                          const SizedBox(width: 20),
                          ElevatedButton.icon(
                            onPressed: () {
                              // Set winner for team 2
                              setState(() {
                                if (!_winners.contains(game['abbreviation2'])) {
                                  _winners.add(game['abbreviation2'] ?? '');
                                }
                                _winners.remove(game['abbreviation']);
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('${game['fullname2']} set as winner')),
                              );
                            },
                            icon: const Icon(Icons.check_circle),
                            label: const Text('Set as Winner'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWinnersTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Week: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(width: 10),
              DropdownButton<String>(
                value: _selectedWeek,
                items: [
                  for (int i = 1; i <= 18; i++)
                    DropdownMenuItem(
                      value: 'REG$i',
                      child: Text('Week $i'),
                    )
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedWeek = value;
                      _loadGameData();
                    });
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          _winners.isEmpty
              ? const Center(
                  child: Text(
                    'No winners selected yet',
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : Expanded(
                  child: ListView.builder(
                    itemCount: _winners.length,
                    itemBuilder: (context, index) {
                      final winner = _winners[index];
                      // Find the game with this winner
                      final game = _games.firstWhere(
                        (g) => g['abbreviation'] == winner || g['abbreviation2'] == winner,
                        orElse: () => <String, dynamic>{},
                      );
                      
                      final isTeam1 = game['abbreviation'] == winner;
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage: NetworkImage(
                              isTeam1 ? game['picture'] ?? '' : game['picture2'] ?? '',
                            ),
                          ),
                          title: Text(
                            isTeam1 ? game['fullname'] ?? '' : game['fullname2'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(winner),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                _winners.removeAt(index);
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Winner removed')),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton.icon(
              onPressed: () {
                // Save winners
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Winners saved successfully!')),
                );
              },
              icon: const Icon(Icons.save),
              label: const Text('Save Winners'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 