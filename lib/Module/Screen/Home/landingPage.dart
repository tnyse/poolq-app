import 'Play.dart';
import '../Auth/Signup.dart';
import '../../../Widget/reuse.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../Widget/countDown.dart';
import '../../../Provider/homeProvider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:poolqapp/Module/Screen/Home/LeaderbpardWidget.dart';
import 'package:poolqapp/widgets/home/home_welcome_cards.dart';
import 'package:poolqapp/widgets/home/previous_week_top3.dart';
import 'package:poolqapp/constants/app_theme.dart';
import 'package:poolqapp/services/game_enforcement_service.dart';

class HomePageWidget extends StatefulWidget {
  PageController? controller;
  bool? isEmpty;

  HomePageWidget({required this.controller, this.isEmpty});

  @override
  _HomePageWidgetState createState() => _HomePageWidgetState();
}

class _HomePageWidgetState extends State<HomePageWidget> {
  User? user = FirebaseAuth.instance.currentUser;
  DateTime? _deadline;
  String? _deadlineWeek;
  bool _deadlineLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDeadline());
  }

  Future<void> _loadDeadline() async {
    if (!mounted) return;
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    final week = dataProvider.game?['name']?.toString() ?? 'PRE1';

    DateTime? kickoff;
    try {
      kickoff = await GameEnforcementService().getFirstKickoff(week);
    } catch (e) {
      debugPrint('HomePageWidget: kickoff load failed: $e');
    }

    // Fallback: parse the first label date from getGame() (midnight that day).
    if (kickoff == null) {
      final raw = _deadlineRaw(dataProvider);
      if (raw.isNotEmpty) {
        kickoff = dataProvider.formatStringDate(raw);
      }
    }

    if (!mounted) return;
    setState(() {
      _deadline = kickoff;
      _deadlineWeek = week;
      _deadlineLoading = false;
    });
  }

  String _deadlineRaw(DataProvider dataProvider) {
    if (dataProvider.data == null || dataProvider.data!.isEmpty) return '';
    final first = dataProvider.data![0];
    if (first is String) return first;
    return (first['date'] ?? '').toString();
  }

  String _formatDeadlineLabel(DateTime deadline) {
    final local = deadline.toLocal();
    return DateFormat('EEE MMM d, yyyy · h:mm a').format(local);
  }

  Future<void> _onLetsPlay(DataProvider dataProvider) async {
    if (dataProvider.data == null || dataProvider.game == null) {
      customSnackbar(context, 'loading games');
      return;
    }
    final alreadyEntered = widget.isEmpty == false;
    if (alreadyEntered) {
      if (widget.controller != null) {
        widget.controller!.jumpToPage(1);
        dataProvider.setValue(1);
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LeaderboardWidget()),
        );
      }
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PlayWidget()),
    );
  }

  Widget _buildDeadlineCard(DataProvider dataProvider) {
    if (_deadlineLoading) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.primaryBlue.withOpacity(0.92),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
      );
    }

    final week = _deadlineWeek ?? dataProvider.game?['name']?.toString() ?? '';
    final deadline = _deadline;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withOpacity(0.92),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            week.isEmpty ? 'ENTRY DEADLINE' : '$week ENTRY DEADLINE',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontWeight: FontWeight.w600,
              fontSize: 12,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 8),
          if (deadline == null)
            const Text(
              'Deadline unavailable',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            )
          else ...[
            CountdownTimerDemo(
              deadline,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _formatDeadlineLabel(deadline),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.75),
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dataProvider = Provider.of<DataProvider>(context, listen: true);
    final alreadyEntered = widget.isEmpty == false;
    final loading = dataProvider.data == null || dataProvider.game == null;

    // Reload deadline when active week changes.
    final week = dataProvider.game?['name']?.toString();
    if (!_deadlineLoading &&
        week != null &&
        week != _deadlineWeek &&
        dataProvider.game != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadDeadline());
    }

    return SizedBox.expand(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/gb.jpeg', fit: BoxFit.cover),
          Container(color: Colors.black.withOpacity(0.35)),
          if (loading)
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF063a73)),
              ),
            )
          else
            SafeArea(
              bottom: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                          if (!mounted) return;
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RegisterWidget(),
                            ),
                            (route) => false,
                          );
                        },
                        icon: const Icon(
                          Icons.logout,
                          size: 28,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Image.asset(
                      'assets/images/poolq12.png',
                      width: 140,
                      height: 150,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 8),
                    HomeWelcomeCards(
                      alreadyEntered: alreadyEntered,
                      onLetsPlay: () => _onLetsPlay(dataProvider),
                    ),
                    const SizedBox(height: 16),
                    const PreviousWeekTop3(),
                    const SizedBox(height: 8),
                    _buildDeadlineCard(dataProvider),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
