import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:poolqapp/Provider/homeProvider.dart';
import 'package:poolqapp/services/nfl_game_service.dart';
import 'package:poolqapp/services/scoring_service.dart';
import 'package:poolqapp/constants/app_theme.dart';
import 'package:poolqapp/constants/season_config.dart';
import 'package:poolqapp/Widget/AppDrawer.dart';
import 'package:poolqapp/Module/Screen/Admin/AdminStats.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:poolqapp/Module/Screen/Admin/PaymentVerificationScreen.dart';
import 'package:poolqapp/screens/admin/admin_payment_settings.dart';
import 'package:poolqapp/services/week_results_service.dart';
// import '../../../Model/invitation_model.dart';
// import '../../../services/nfl_schedule_service.dart';
import '../../../Widget/reuse.dart';

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
  String _selectedWeek = "MOCK1";
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _maxUsesController = TextEditingController();
  bool _isReusable = true;
  bool _isLoading = false;
  bool _scoresPublic = false;
  bool _savingScores = false;
  String _entriesStatusFilter = 'All';
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _loadGameData();
  }
  
  void _loadGameData() async {
    final games = await _gameService.getGamesForWeek(_selectedWeek);
    final winners = await _gameService.getWinnersForWeek(_selectedWeek);

    // Overlay any scores already saved in Firestore
    try {
      final saved = await ScoringService().getGameResultsForWeek(_selectedWeek);
      final byId = {for (final r in saved) r.gameId: r};
      for (final game in games) {
        final id = (game['id'] ?? '').toString();
        final result = byId[id];
        if (result == null) continue;
        if (result.homeScore != null) {
          game['score'] = result.homeScore.toString();
        }
        if (result.awayScore != null) {
          game['score2'] = result.awayScore.toString();
        }
        if (result.status.isNotEmpty) {
          game['status'] = result.status;
        }
      }
    } catch (e) {
      debugPrint('AdminDashboard: could not load game_results: $e');
    }

    if (!mounted) return;
    setState(() {
      _games = games;
      _winners = winners;
      // Consider scores public when all games are final/completed
      _scoresPublic = _games.isNotEmpty && _games.every((g) {
        final s = (g['status'] ?? '').toString().toLowerCase();
        return s == 'final' || s == 'completed';
      });
    });
  }

  Future<void> _saveGameScoresToFirestore() async {
    if (_games.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No games loaded for this week')),
      );
      return;
    }

    setState(() => _savingScores = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final scoring = ScoringService();
      final results = scoring.gameResultsFromAdminGames(
        weekName: _selectedWeek,
        games: _games,
      );
      final count = await scoring.saveGameResults(results);
      if (!mounted) return;
      setState(() {
        _savingScores = false;
        for (final g in _games) {
          g['status'] = 'final';
        }
        _scoresPublic = _games.isNotEmpty;
      });
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Saved $count final scores for $_selectedWeek to Firestore',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _savingScores = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Save failed: $e\n'
            'Sign in as a Firebase user with userType=admin.',
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 6),
        ),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _codeController.dispose();
    _maxUsesController.dispose();
    super.dispose();
  }

  List<DropdownMenuItem<String>> get _weekDropdownItems =>
      SeasonConfig.adminWeekChoices
          .map(
            (w) => DropdownMenuItem(
              value: w,
              child: Text(SeasonConfig.adminWeekLabel(w)),
            ),
          )
          .toList();

  Future<void> _createInvitationCode() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final code = _codeController.text.trim();
      
      // Check if code already exists
      final existingCode = await FirebaseFirestore.instance
          .collection('invites')
          .where('code', isEqualTo: code)
          .get();

      if (existingCode.docs.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('This code already exists')),
          );
        }
        return;
      }

      // Create new invitation code
      await FirebaseFirestore.instance.collection('invites').add({
        'code': code,
        'createdBy': 'admin@poolq.app', // You might want to get this from current user
        'createdAt': FieldValue.serverTimestamp(),
        'isReusable': _isReusable,
        'maxUses': _maxUsesController.text.isEmpty ? null : int.parse(_maxUsesController.text),
        'usedCount': 0,
        'usedBy': [],
        'usedAt': [],
        'status': 'active',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invitation code created successfully')),
        );
        _codeController.clear();
        _maxUsesController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating invitation code: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleCodeStatus(String docId, bool makeActive) async {
    try {
      await FirebaseFirestore.instance
          .collection('invites')
          .doc(docId)
          .update({'status': makeActive ? 'active' : 'expired'});
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Code ${makeActive ? 'activated' : 'deactivated'} successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating code status: $e')),
        );
      }
    }
  }

  Widget _buildInvitationCodesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Create Invitation Code',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _codeController,
                      decoration: const InputDecoration(
                        labelText: 'Invitation Code',
                        hintText: 'Enter a unique code',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an invitation code';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    CheckboxListTile(
                      title: const Text('Reusable Code'),
                      subtitle: const Text('Allow multiple users to use this code'),
                      value: _isReusable,
                      onChanged: (bool? value) {
                        if (value != null) {
                          setState(() {
                            _isReusable = value;
                          });
                        }
                      },
                    ),
                    if (_isReusable) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _maxUsesController,
                        decoration: const InputDecoration(
                          labelText: 'Max Uses (Optional)',
                          hintText: 'Leave empty for unlimited uses',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            final number = int.tryParse(value);
                            if (number == null || number < 1) {
                              return 'Please enter a valid number greater than 0';
                            }
                          }
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: 24),
                    Center(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _createInvitationCode,
                        child: _isLoading
                            ? const CircularProgressIndicator()
                            : const Text('Create Code'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Existing Invitation Codes',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('invites')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data?.docs ?? [];
              
              if (docs.isEmpty) {
                return const Center(
                  child: Text('No invitation codes found'),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final isActive = data['status'] == 'active';
                  final usedCount = data['usedCount'] ?? 0;
                  final maxUses = data['maxUses'];
                  final isReusable = data['isReusable'] ?? false;

                  return Card(
                    child: ListTile(
                      title: Text(data['code'] ?? ''),
                      subtitle: Text(
                        'Status: ${data['status']}\n'
                        'Used: $usedCount${maxUses != null ? ' / $maxUses' : ''}\n'
                        'Reusable: ${isReusable ? 'Yes' : 'No'}',
                      ),
                      trailing: Switch(
                        value: isActive,
                        onChanged: (bool value) => _toggleCodeStatus(doc.id, value),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                'assets/images/app_icon.png',
                width: 28,
                height: 28,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Image.asset(
                  'assets/images/poolq12.png',
                  width: 28,
                  height: 28,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Admin Dashboard',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            tooltip: 'Players & Payments',
            icon: const Icon(Icons.people),
            onPressed: () {
              Navigator.pushNamed(context, '/admin-players');
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Game Scores', icon: Icon(Icons.sports_football)),
            Tab(text: 'Winners', icon: Icon(Icons.emoji_events)),
            Tab(text: 'Entries', icon: Icon(Icons.list_alt)),
            Tab(text: 'Notifications', icon: Icon(Icons.notifications)),
            Tab(text: 'Statistics', icon: Icon(Icons.analytics)),
            Tab(text: 'Invitation Codes', icon: Icon(Icons.code)),
            Tab(text: 'Payments', icon: Icon(Icons.payments_outlined)),
          ],
        ),
      ),
      drawer: AppDrawer(),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGameScoresTab(),
          _buildWinnersTab(),
          _buildEntriesTab(),
          _buildNotificationsTab(),
          AdminStats(),
          _buildInvitationCodesTab(),
          const AdminPaymentSettings(),
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
                items: _weekDropdownItems,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedWeek = value;
                      _loadGameData();
                    });
                  }
                },
              ),
              const SizedBox(width: 16),
              Chip(
                avatar: Icon(_scoresPublic ? Icons.public : Icons.schedule,
                    color: _scoresPublic ? Colors.green : Colors.orange),
                label: Text(_scoresPublic ? 'Scores public (final)' : 'Scores not public'),
                backgroundColor: _scoresPublic ? Colors.green.shade50 : Colors.orange.shade50,
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            key: ValueKey('game-scores-$_selectedWeek'),
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
                                TeamLogo(
                                  abbr: game['abbreviation'] ?? '',
                                  size: 50,
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
                                TeamLogo(
                                  abbr: game['abbreviation2'] ?? '',
                                  size: 50,
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
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _savingScores ? null : _saveGameScoresToFirestore,
              icon: _savingScores
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.cloud_upload),
              label: Text(
                _savingScores
                    ? 'Saving to Firestore…'
                    : 'Save Scores to Firestore',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: const [
              Icon(Icons.notifications),
              SizedBox(width: 8),
              Text('Payment Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('admin_notifications')
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return const Center(child: Text('No notifications'));
              }
              return ListView.separated(
                itemCount: docs.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final isUnread = !(data['read'] == true);
                  final type = (data['type'] ?? 'pending_payment').toString();
                  final userName = (data['userDisplayName'] ?? 'Unknown').toString();
                  final userEmail = (data['userEmail'] ?? '').toString();
                  final week = (data['week'] ?? '').toString();
                  final pickRecordId = (data['pickRecordId'] ?? '').toString();
                  return ListTile(
                    leading: Stack(
                      children: [
                        const CircleAvatar(child: Icon(Icons.receipt_long)),
                        if (isUnread)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                    title: Text('$userName • $week'),
                    subtitle: Text('Type: $type\n$userEmail'),
                    isThreeLine: true,
                    trailing: Wrap(
                      spacing: 8,
                      children: [
                        TextButton(
                          onPressed: () async {
                            await _viewPicksFromPickRecordId(pickRecordId);
                          },
                          child: const Text('View Picks'),
                        ),
                        TextButton(
                          onPressed: () async {
                            await FirebaseFirestore.instance
                                .collection('admin_notifications')
                                .doc(doc.id)
                                .update({'read': true});
                          },
                          child: const Text('Mark read'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const PaymentVerificationScreen()),
                            );
                          },
                          icon: const Icon(Icons.verified),
                          label: const Text('Verify'),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _viewPicksFromPickRecordId(String pickRecordId) async {
    if (pickRecordId.isEmpty) return;
    try {
      final snap = await FirebaseFirestore.instance.collection('pickrecord').doc(pickRecordId).get();
      if (!snap.exists) return;
      final data = snap.data() as Map<String, dynamic>;
      _showPicksDialog(context, data);
    } catch (_) {}
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
                items: _weekDropdownItems,
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
                          leading: TeamLogo(
                            abbr: isTeam1 ? game['abbreviation'] ?? '' : game['abbreviation2'] ?? '',
                            size: 40,
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Team winners are local only. Use “Declare Week Results” to score entries.',
                    ),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
              icon: const Icon(Icons.info_outline),
              label: const Text('Save Winners (UI only)'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: ElevatedButton.icon(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Declaring results for $_selectedWeek…'),
                  ),
                );
                final result =
                    await WeekResultsService().declareWeek(_selectedWeek);
                if (!mounted) return;
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      result == null
                          ? 'Declare failed — need scored pickrecords for $_selectedWeek'
                          : 'Declared $_selectedWeek — '
                              '${(result['winners'] as List?)?.length ?? 0} winner(s), '
                              'top ${(result['top3'] as List?)?.length ?? 0}',
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.emoji_events),
              label: const Text('Declare Week Results'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF063a73),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntriesTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              const Text('Week: ', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 10),
              DropdownButton<String>(
                value: _selectedWeek,
                items: _weekDropdownItems,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedWeek = value;
                    });
                  }
                },
              ),
              const SizedBox(width: 16),
              const Text('Status: ', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _entriesStatusFilter,
                items: const [
                  DropdownMenuItem(value: 'All', child: Text('All')),
                  DropdownMenuItem(value: 'pending', child: Text('Pending')),
                  DropdownMenuItem(value: 'verified', child: Text('Verified')),
                  DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
                  DropdownMenuItem(value: 'disqualified', child: Text('Disqualified')),
                ],
                onChanged: (v) => setState(() => _entriesStatusFilter = v ?? 'All'),
              ),
              const Spacer(),
              Chip(
                avatar: Icon(_scoresPublic ? Icons.public : Icons.schedule,
                    color: _scoresPublic ? Colors.green : Colors.orange),
                label: Text(_scoresPublic ? 'Scores public (final)' : 'Scores not public'),
                backgroundColor: _scoresPublic ? Colors.green.shade50 : Colors.orange.shade50,
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: (_entriesStatusFilter == 'All')
                ? FirebaseFirestore.instance
                    .collection('pickrecord')
                    .where('week', isEqualTo: _selectedWeek)
                    .snapshots()
                : FirebaseFirestore.instance
                    .collection('pickrecord')
                    .where('week', isEqualTo: _selectedWeek)
                    .where('paymentStatus', isEqualTo: _entriesStatusFilter)
                    .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return const Center(child: Text('No entries for this week'));
              }
              return ListView.separated(
                itemCount: docs.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final displayName = data['displayName'] ?? data['email'] ?? data['uid'] ?? 'Unknown';
                  final status = data['paymentStatus'] ?? 'pending';
                  final tiebreaker = data['tiebreaker']?.toString() ?? '—';
                  final score = data['score']?.toString();
                  final rank = data['rank']?.toString();
                  return ListTile(
                    leading: CircleAvatar(child: Text('${index + 1}')),
                    title: Text(displayName),
                    subtitle: Text('Status: $status • Tiebreaker: $tiebreaker' + (score != null ? ' • Score: $score' : '') + (rank != null ? ' • Rank: $rank' : '')),
                    trailing: TextButton.icon(
                      onPressed: () {
                        _showPicksDialog(context, data);
                      },
                      icon: const Icon(Icons.remove_red_eye),
                      label: const Text('View Picks'),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showPicksDialog(BuildContext context, Map<String, dynamic> pickData) {
    final picks = (pickData['picks'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .where((e) => e.isNotEmpty)
        .toList();
    final tiebreaker = pickData['tiebreaker']?.toString() ?? '—';
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Submitted Picks'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PicksLogoGrid(picks: picks, logoSize: 36),
                const SizedBox(height: 12),
                Text(
                  'Tiebreaker: $tiebreaker',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            )
          ],
        );
      },
    );
  }
} 