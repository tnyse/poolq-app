import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:poolqapp/constants/app_theme.dart';
import 'package:poolqapp/constants/payment_status.dart';
import 'package:poolqapp/services/app_config_service.dart';
import 'package:poolqapp/services/game_enforcement_service.dart';
import 'package:poolqapp/services/local_schedule_service.dart';
import 'package:poolqapp/services/payment_service.dart';

/// Live admin view of weekly entrants from Firestore `pickrecord`.
class AdminPlayersPage extends StatefulWidget {
  const AdminPlayersPage({Key? key}) : super(key: key);

  @override
  State<AdminPlayersPage> createState() => _AdminPlayersPageState();
}

class _AdminPlayersPageState extends State<AdminPlayersPage> {
  final _paymentService = PaymentService();
  final _config = AppConfigService();
  final _schedule = LocalScheduleService();
  final _enforcement = GameEnforcementService();

  String _selectedWeek = 'PRE1';
  List<String> _weeks = const ['PRE1', 'PRE2', 'PRE3'];
  DateTime? _kickoff;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    if (!_config.isLoaded) await _config.load();
    final weeks = await _schedule.listWeeks();
    setState(() {
      _weeks = weeks.isEmpty ? _weeks : weeks;
      _selectedWeek = _config.activeWeek;
      if (!_weeks.contains(_selectedWeek)) {
        _selectedWeek = _weeks.first;
      }
    });
    await _refreshKickoff();
  }

  Future<void> _refreshKickoff() async {
    final kickoff = await _enforcement.getFirstKickoff(_selectedWeek);
    if (mounted) setState(() => _kickoff = kickoff);
  }

  Future<void> _setActiveWeek(String week) async {
    setState(() => _busy = true);
    try {
      await _config.setActiveWeek(week);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Active week set to $week')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to set week: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verify(String pickId) async {
    final ok = await _paymentService.verifyPayment(pickId, 'admin');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Verified $pickId' : 'Verify failed'),
        backgroundColor: ok ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _reject(String pickId) async {
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject payment'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(hintText: 'Reason'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, reasonController.text.trim()),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (reason == null || reason.isEmpty) return;
    final ok = await _paymentService.rejectPayment(pickId, 'admin', reason);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Rejected' : 'Reject failed'),
        backgroundColor: ok ? Colors.orange : Colors.red,
      ),
    );
  }

  Color _statusColor(String? status) {
    switch (status) {
      case PaymentStatus.verified:
      case PaymentStatus.autoVerified:
        return Colors.green;
      case PaymentStatus.sent:
        return Colors.amber.shade800;
      case PaymentStatus.pending:
        return Colors.orange;
      case PaymentStatus.rejected:
      case PaymentStatus.disqualified:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Players & Payments'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          if (_busy)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _weeks.contains(_selectedWeek) ? _selectedWeek : null,
                    decoration: const InputDecoration(
                      labelText: 'Week',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: _weeks
                        .map((w) => DropdownMenuItem(value: w, child: Text(w)))
                        .toList(),
                    onChanged: (w) async {
                      if (w == null) return;
                      setState(() => _selectedWeek = w);
                      await _refreshKickoff();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _busy ? null : () => _setActiveWeek(_selectedWeek),
                  child: const Text('Set Active'),
                ),
              ],
            ),
          ),
          if (_kickoff != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'First kickoff: ${_kickoff!.toLocal()}',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ),
          const Divider(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('pickrecord')
                  .where('week', isEqualTo: _selectedWeek)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs.toList()
                  ..sort((a, b) {
                    final aName =
                        (a.data() as Map)['displayName']?.toString() ?? '';
                    final bName =
                        (b.data() as Map)['displayName']?.toString() ?? '';
                    return aName.compareTo(bName);
                  });
                if (docs.isEmpty) {
                  return Center(
                    child: Text('No entries for $_selectedWeek yet'),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final status =
                        data['paymentStatus']?.toString() ?? PaymentStatus.pending;
                    final name = data['displayName']?.toString() ?? 'Unknown';
                    final isDemo = data['isDemoEntry'] == true;
                    return Card(
                      child: ListTile(
                        title: Text(name),
                        subtitle: Text(
                          '$status · fee ${data['entryFee'] ?? '-'}'
                          '${isDemo ? ' · demo' : ''}',
                        ),
                        leading: CircleAvatar(
                          backgroundColor: _statusColor(status),
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (action) {
                            if (action == 'verify') _verify(doc.id);
                            if (action == 'reject') _reject(doc.id);
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'verify',
                              child: Text('Verify payment'),
                            ),
                            PopupMenuItem(
                              value: 'reject',
                              child: Text('Reject payment'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
