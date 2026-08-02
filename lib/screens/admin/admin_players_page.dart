import 'package:flutter/material.dart';
import 'package:poolqapp/constants/app_theme.dart';
import 'package:poolqapp/services/payment_deadline_service.dart';

/// Admin page for managing players and their payment status across all weeks
class AdminPlayersPage extends StatefulWidget {
  const AdminPlayersPage({Key? key}) : super(key: key);

  @override
  State<AdminPlayersPage> createState() => _AdminPlayersPageState();
}

class _AdminPlayersPageState extends State<AdminPlayersPage> {
  String _selectedWeek = 'REG1';
  List<String> _selectedPlayerIds = [];
  bool _isSelectAllMode = false;
  late PaymentDeadlineService _deadlineService;

  @override
  void initState() {
    super.initState();
    _deadlineService = PaymentDeadlineService();
    _setupDeadlineMonitoring();
  }

  @override
  void dispose() {
    _deadlineService.dispose();
    super.dispose();
  }

  void _setupDeadlineMonitoring() {
    // Mock kickoff time - 2 hours from now for demo
    final mockKickoffTime = DateTime.now().add(Duration(hours: 2));
    
    _deadlineService.addDeadlineCallback((weekName) {
      if (mounted && weekName == _selectedWeek) {
        final unpaidCount = _getUnpaidPlayersCount();
        _deadlineService.showDeadlineNotification(context, weekName, unpaidCount);
      }
    });
    
    _deadlineService.startDeadlineMonitoring(_selectedWeek, mockKickoffTime);
  }

  int _getUnpaidPlayersCount() {
    final players = _weeklyPlayers[_selectedWeek] ?? [];
    return players.where((p) => p['paymentStatus'] == 'unpaid').length;
  }

  // Mock data - in real app, this would come from Firestore
  final Map<String, List<Map<String, dynamic>>> _weeklyPlayers = {
    'REG1': [
      {
        'uid': 'demo_user_current',
        'displayName': 'Demo User (Current Session)',
        'email': 'demo@poolq.com',
        'paymentStatus': 'verified',
        'paymentMethod': 'Demo Mode',
        'submittedAt': DateTime.now().subtract(Duration(hours: 2)),
        'entryFee': 10.0,
        'score': 8,
      },
      {
        'uid': 'demo_jessica',
        'displayName': 'Jessica Chen',
        'email': 'jessica.chen@email.com',
        'paymentStatus': 'pending',
        'paymentMethod': 'Venmo',
        'submittedAt': DateTime.now().subtract(Duration(hours: 5)),
        'entryFee': 10.0,
        'score': 11,
      },
      {
        'uid': 'demo_alex',
        'displayName': 'Alex Rodriguez',
        'email': 'alex.rodriguez@email.com',
        'paymentStatus': 'verified',
        'paymentMethod': 'Cash App',
        'submittedAt': DateTime.now().subtract(Duration(hours: 8)),
        'entryFee': 10.0,
        'score': 10,
      },
      {
        'uid': 'demo_emma',
        'displayName': 'Emma Thompson',
        'email': 'emma.thompson@email.com',
        'paymentStatus': 'unpaid',
        'paymentMethod': null,
        'submittedAt': DateTime.now().subtract(Duration(hours: 12)),
        'entryFee': 10.0,
        'score': 9,
      },
    ],
    'REG2': [
      {
        'uid': 'demo_user_current',
        'displayName': 'Demo User (Current Session)',
        'email': 'demo@poolq.com',
        'paymentStatus': 'verified',
        'paymentMethod': 'Demo Mode',
        'submittedAt': DateTime.now().subtract(Duration(days: 7, hours: 2)),
        'entryFee': 10.0,
        'score': 12,
      },
      {
        'uid': 'demo_alex',
        'displayName': 'Alex Rodriguez',
        'email': 'alex.rodriguez@email.com',
        'paymentStatus': 'pending',
        'paymentMethod': 'PayPal',
        'submittedAt': DateTime.now().subtract(Duration(days: 7, hours: 3)),
        'entryFee': 10.0,
        'score': 8,
      },
    ],
  };

  final List<String> _availableWeeks = [
    'REG1', 'REG2', 'REG3', 'REG4', 'REG5', 'REG6'
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentWeekPlayers = _weeklyPlayers[_selectedWeek] ?? [];

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        title: Text(
          'Admin: Player Management',
          style: theme.textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: Column(
        children: [
          // Week selector and stats
          _buildWeekSelector(theme, currentWeekPlayers),
          
          // Bulk actions bar
          if (_selectedPlayerIds.isNotEmpty) _buildBulkActionsBar(theme),
          
          // Players list
          Expanded(
            child: currentWeekPlayers.isEmpty
                ? _buildEmptyState(theme)
                : _buildPlayersList(theme, currentWeekPlayers),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showPaymentDeadlineAlert,
        backgroundColor: AppTheme.secondaryOrange,
        icon: Icon(Icons.notifications_active),
        label: Text('Send Deadline Alert'),
      ),
    );
  }

  Widget _buildWeekSelector(ThemeData theme, List<Map<String, dynamic>> players) {
    final paidCount = players.where((p) => p['paymentStatus'] == 'verified').length;
    final pendingCount = players.where((p) => p['paymentStatus'] == 'pending').length;
    final unpaidCount = players.where((p) => p['paymentStatus'] == 'unpaid').length;
    final totalRevenue = players.where((p) => p['paymentStatus'] == 'verified')
        .fold(0.0, (sum, p) => sum + (p['entryFee'] ?? 0.0));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Week dropdown
          Row(
            children: [
              Text(
                'Week:',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedWeek,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: _availableWeeks.map((week) {
                    final weekNumber = week.replaceAll('REG', '').replaceAll('PRE', '');
                    return DropdownMenuItem(
                      value: week,
                      child: Text('Week $weekNumber'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedWeek = value;
                        _selectedPlayerIds.clear();
                        _isSelectAllMode = false;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Stats row
          Row(
            children: [
              _buildStatCard(theme, 'Total Players', '${players.length}', AppTheme.primaryBlue),
              const SizedBox(width: 8),
              _buildStatCard(theme, 'Paid', '$paidCount', AppTheme.tertiaryGreen),
              const SizedBox(width: 8),
              _buildStatCard(theme, 'Pending', '$pendingCount', AppTheme.secondaryOrange),
              const SizedBox(width: 8),
              _buildStatCard(theme, 'Unpaid', '$unpaidCount', AppTheme.error),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Deadline status
          _buildDeadlineStatus(theme),
          
          const SizedBox(height: 8),
          
          // Revenue
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.tertiaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.tertiaryGreen.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.attach_money, color: AppTheme.tertiaryGreen, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Total Revenue: \$${totalRevenue.toStringAsFixed(2)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppTheme.tertiaryGreen,
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

  Widget _buildStatCard(ThemeData theme, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeadlineStatus(ThemeData theme) {
    // Mock kickoff time - 2 hours from now for demo
    final mockKickoffTime = DateTime.now().add(Duration(hours: 2));
    final deadlineStatus = _deadlineService.getDeadlineStatus(mockKickoffTime);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: deadlineStatus.statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: deadlineStatus.statusColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(deadlineStatus.icon, color: deadlineStatus.statusColor, size: 20),
          const SizedBox(width: 8),
          Text(
            'Payment Deadline: ${deadlineStatus.displayText}',
            style: theme.textTheme.titleSmall?.copyWith(
              color: deadlineStatus.statusColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (!deadlineStatus.hasPasssed) ...[
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () => _triggerDeadlineAlert(),
              icon: Icon(Icons.notifications_active, size: 16),
              label: Text('Test Alert'),
              style: ElevatedButton.styleFrom(
                backgroundColor: deadlineStatus.statusColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: Size(0, 32),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _triggerDeadlineAlert() {
    final unpaidCount = _getUnpaidPlayersCount();
    _deadlineService.showDeadlineNotification(context, _selectedWeek, unpaidCount);
  }

  Widget _buildBulkActionsBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(color: AppTheme.primaryBlue.withOpacity(0.3)),
        ),
      ),
      child: Row(
        children: [
          Text(
            '${_selectedPlayerIds.length} selected',
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppTheme.primaryBlue,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: _markSelectedAsPaid,
            icon: Icon(Icons.check_circle, color: AppTheme.tertiaryGreen),
            label: Text('Mark Paid', style: TextStyle(color: AppTheme.tertiaryGreen)),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: _markSelectedAsPending,
            icon: Icon(Icons.schedule, color: AppTheme.secondaryOrange),
            label: Text('Mark Pending', style: TextStyle(color: AppTheme.secondaryOrange)),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: _markSelectedAsUnpaid,
            icon: Icon(Icons.cancel, color: AppTheme.error),
            label: Text('Mark Unpaid', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayersList(ThemeData theme, List<Map<String, dynamic>> players) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: players.length + 1, // +1 for select all header
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildSelectAllHeader(theme, players);
        }
        
        final player = players[index - 1];
        final isSelected = _selectedPlayerIds.contains(player['uid']);
        
        return _buildPlayerCard(theme, player, isSelected);
      },
    );
  }

  Widget _buildSelectAllHeader(ThemeData theme, List<Map<String, dynamic>> players) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Checkbox(
          value: _isSelectAllMode,
          onChanged: (value) {
            setState(() {
              _isSelectAllMode = value ?? false;
              if (_isSelectAllMode) {
                _selectedPlayerIds = players.map((p) => p['uid'].toString()).toList();
              } else {
                _selectedPlayerIds.clear();
              }
            });
          },
        ),
        title: Text(
          'Select All Players',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text('${players.length} players in this week'),
      ),
    );
  }

  Widget _buildPlayerCard(ThemeData theme, Map<String, dynamic> player, bool isSelected) {
    final paymentStatus = player['paymentStatus'] ?? 'unpaid';
    final statusColor = _getStatusColor(paymentStatus);
    final submittedAt = player['submittedAt'] as DateTime?;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? AppTheme.primaryBlue : Colors.transparent,
          width: 2,
        ),
      ),
      child: ListTile(
        leading: Checkbox(
          value: isSelected,
          onChanged: (value) {
            setState(() {
              if (value == true) {
                _selectedPlayerIds.add(player['uid']);
              } else {
                _selectedPlayerIds.remove(player['uid']);
              }
              _isSelectAllMode = false;
            });
          },
        ),
        title: Text(
          player['displayName'] ?? 'Unknown Player',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(player['email'] ?? 'No email'),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    paymentStatus.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (player['paymentMethod'] != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    'via ${player['paymentMethod']}',
                    style: theme.textTheme.labelSmall,
                  ),
                ],
              ],
            ),
            if (submittedAt != null) ...[
              const SizedBox(height: 2),
              Text(
                'Submitted: ${_formatDateTime(submittedAt)}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '\$${player['entryFee']?.toStringAsFixed(2) ?? '0.00'}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
            Text(
              'Score: ${player['score'] ?? 0}',
              style: theme.textTheme.labelSmall,
            ),
          ],
        ),
        onTap: () => _showPlayerDetails(player),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: AppTheme.onSurfaceVariant.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No Players Yet',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: AppTheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No players have entered for this week.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'verified':
        return AppTheme.tertiaryGreen;
      case 'pending':
        return AppTheme.secondaryOrange;
      case 'unpaid':
        return AppTheme.error;
      default:
        return AppTheme.onSurfaceVariant;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.month}/${dateTime.day} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _refreshData() {
    // In real app, this would refresh from Firestore
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Data refreshed'),
        backgroundColor: AppTheme.tertiaryGreen,
      ),
    );
  }

  void _markSelectedAsPaid() {
    // In real app, this would update Firestore
    setState(() {
      for (String playerId in _selectedPlayerIds) {
        final players = _weeklyPlayers[_selectedWeek];
        if (players != null) {
          final playerIndex = players.indexWhere((p) => p['uid'] == playerId);
          if (playerIndex != -1) {
            players[playerIndex]['paymentStatus'] = 'verified';
          }
        }
      }
      _selectedPlayerIds.clear();
      _isSelectAllMode = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Marked ${_selectedPlayerIds.length} players as paid'),
        backgroundColor: AppTheme.tertiaryGreen,
      ),
    );
  }

  void _markSelectedAsPending() {
    setState(() {
      for (String playerId in _selectedPlayerIds) {
        final players = _weeklyPlayers[_selectedWeek];
        if (players != null) {
          final playerIndex = players.indexWhere((p) => p['uid'] == playerId);
          if (playerIndex != -1) {
            players[playerIndex]['paymentStatus'] = 'pending';
          }
        }
      }
      _selectedPlayerIds.clear();
      _isSelectAllMode = false;
    });
  }

  void _markSelectedAsUnpaid() {
    setState(() {
      for (String playerId in _selectedPlayerIds) {
        final players = _weeklyPlayers[_selectedWeek];
        if (players != null) {
          final playerIndex = players.indexWhere((p) => p['uid'] == playerId);
          if (playerIndex != -1) {
            players[playerIndex]['paymentStatus'] = 'unpaid';
          }
        }
      }
      _selectedPlayerIds.clear();
      _isSelectAllMode = false;
    });
  }

  void _showPlayerDetails(Map<String, dynamic> player) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(player['displayName'] ?? 'Player Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Email: ${player['email'] ?? 'N/A'}'),
              Text('Payment Status: ${player['paymentStatus'] ?? 'N/A'}'),
              Text('Payment Method: ${player['paymentMethod'] ?? 'N/A'}'),
              Text('Entry Fee: \$${player['entryFee']?.toStringAsFixed(2) ?? '0.00'}'),
              Text('Score: ${player['score'] ?? 0}'),
              if (player['submittedAt'] != null)
                Text('Submitted: ${_formatDateTime(player['submittedAt'])}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                _showAdminOverrideDialog(player);
              },
              icon: Icon(Icons.admin_panel_settings, size: 16),
              label: Text('Override'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  void _showPaymentDeadlineAlert() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Send Payment Deadline Alert'),
          content: Text(
            'This will send a notification to all players with pending or unpaid status for $_selectedWeek.\n\nContinue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Payment deadline alerts sent!'),
                    backgroundColor: AppTheme.secondaryOrange,
                  ),
                );
              },
              child: Text('Send Alerts'),
            ),
          ],
        );
      },
    );
  }

  void _showAdminOverrideDialog(Map<String, dynamic> player) {
    String? selectedStatus = player['paymentStatus'];
    String overrideReason = '';
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Icon(Icons.admin_panel_settings, color: Colors.red, size: 24),
                  SizedBox(width: 8),
                  Text('Admin Override'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Override payment status after games began. Use only for corrections.',
                            style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  Text('Player: ${player['displayName']}'),
                  Text('Current: ${player['paymentStatus']}'),
                  SizedBox(height: 16),
                  DropdownButton<String>(
                    value: selectedStatus,
                    isExpanded: true,
                    items: [
                      DropdownMenuItem(value: 'verified', child: Text('Verified')),
                      DropdownMenuItem(value: 'pending', child: Text('Pending')),
                      DropdownMenuItem(value: 'unpaid', child: Text('Unpaid')),
                      DropdownMenuItem(value: 'ineligible', child: Text('Ineligible')),
                    ],
                    onChanged: (value) => setState(() => selectedStatus = value),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Reason (Required)',
                      hintText: 'Late payment verified, Admin correction',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    maxLines: 2,
                    onChanged: (value) => overrideReason = value,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: overrideReason.trim().isEmpty || selectedStatus == null
                      ? null
                      : () {
                          _applyAdminOverride(player, selectedStatus!, overrideReason);
                          Navigator.of(context).pop();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Apply Override'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _applyAdminOverride(Map<String, dynamic> player, String newStatus, String reason) {
    setState(() {
      final players = _weeklyPlayers[_selectedWeek];
      if (players != null) {
        final playerIndex = players.indexWhere((p) => p['uid'] == player['uid']);
        if (playerIndex != -1) {
          players[playerIndex]['paymentStatus'] = newStatus;
          players[playerIndex]['overrideReason'] = reason;
          players[playerIndex]['overrideAt'] = DateTime.now().toIso8601String();
        }
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Status overridden for ${player['displayName']}'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}
