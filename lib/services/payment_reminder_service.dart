import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:poolqapp/Module/Screen/Home/ManualPaymentScreen.dart';
import 'package:poolqapp/constants/app_theme.dart';
import 'package:poolqapp/constants/payment_status.dart';
import 'package:poolqapp/services/payment_service.dart';

/// In-app reminders when payment is not admin-confirmed and the deadline nears.
class PaymentReminderService {
  static final PaymentReminderService _instance =
      PaymentReminderService._internal();
  factory PaymentReminderService() => _instance;
  PaymentReminderService._internal();

  static const List<Duration> _milestones = [
    Duration(hours: 24),
    Duration(hours: 6),
    Duration(hours: 2),
    Duration(hours: 1),
    Duration(minutes: 30),
    Duration(minutes: 15),
  ];

  final _box = GetStorage();
  final _paymentService = PaymentService();
  final List<Timer> _timers = [];
  bool _dialogOpen = false;
  String? _activeWeek;

  /// Payment deadline = first kickoff minus 1 hour (matches PaymentDeadlineService).
  DateTime deadlineFromKickoff(DateTime kickoff) =>
      kickoff.subtract(const Duration(hours: 1));

  /// Start interval timers for [weekName]. Safe to call again (restarts).
  Future<void> startMonitoring({
    required BuildContext context,
    required String weekName,
    required DateTime kickoff,
  }) async {
    stopMonitoring();
    _activeWeek = weekName;

    final deadline = deadlineFromKickoff(kickoff);
    final now = DateTime.now();
    if (!now.isBefore(deadline)) {
      debugPrint('PaymentReminderService: deadline already passed for $weekName');
      return;
    }

    // Catch the most recent missed milestone on open (once per milestone).
    await _maybeShowCatchUp(context, weekName, deadline);

    for (final remaining in _milestones) {
      final fireAt = deadline.subtract(remaining);
      final delay = fireAt.difference(DateTime.now());
      if (delay.isNegative) continue;

      _timers.add(Timer(delay, () {
        if (!context.mounted) return;
        unawaited(_checkAndNotify(
          context,
          weekName: weekName,
          deadline: deadline,
          milestoneKey: _milestoneKey(remaining),
          remainingLabel: _formatRemaining(remaining),
        ));
      }));
    }

    debugPrint(
      'PaymentReminderService: monitoring $weekName — '
      '${_timers.length} timers until $deadline',
    );
  }

  void stopMonitoring() {
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
    _activeWeek = null;
  }

  Future<void> _maybeShowCatchUp(
    BuildContext context,
    String weekName,
    DateTime deadline,
  ) async {
    Duration? latestPassed;
    for (final remaining in _milestones) {
      final fireAt = deadline.subtract(remaining);
      if (!fireAt.isAfter(DateTime.now())) {
        latestPassed = remaining;
      }
    }
    if (latestPassed == null) return;

    await _checkAndNotify(
      context,
      weekName: weekName,
      deadline: deadline,
      milestoneKey: _milestoneKey(latestPassed),
      remainingLabel: _formatRemaining(latestPassed),
    );
  }

  Future<void> _checkAndNotify(
    BuildContext context, {
    required String weekName,
    required DateTime deadline,
    required String milestoneKey,
    required String remainingLabel,
  }) async {
    if (!context.mounted) return;
    if (_dialogOpen) return;
    if (_activeWeek != null && _activeWeek != weekName) return;

    final storageKey = 'pay_reminder_${weekName}_$milestoneKey';
    if (_box.read(storageKey) == true) return;

    final entry = await _paymentService.getUserEntryForWeek(weekName);
    if (entry == null) return; // no entry this week — nothing to remind

    final status = (entry['paymentStatus'] ?? 'unpaid').toString();
    if (PaymentStatus.isEligible(status)) return;

    if (!context.mounted) return;
    _box.write(storageKey, true);

    final left = deadline.difference(DateTime.now());
    final timeText = left.isNegative || left == Duration.zero
        ? 'Deadline has passed'
        : '${_formatDuration(left)} left to confirm payment';

    final pickId = (entry['id'] ?? '').toString();
    await _showReminderDialog(
      context,
      weekName: weekName,
      status: status,
      remainingLabel: remainingLabel,
      timeText: timeText,
      pickRecordId: pickId.isNotEmpty
          ? pickId
          : PaymentService.pickDocumentId(
              (entry['uid'] ?? '').toString(),
              weekName,
            ),
    );
  }

  Future<void> _showReminderDialog(
    BuildContext context, {
    required String weekName,
    required String status,
    required String remainingLabel,
    required String timeText,
    required String pickRecordId,
  }) async {
    _dialogOpen = true;
    final awaitingAdmin = status == PaymentStatus.pending ||
        status == PaymentStatus.sent;

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (ctx) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.schedule, color: AppTheme.warning, size: 24),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Payment reminder',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  awaitingAdmin
                      ? 'Your $weekName payment is still waiting for admin confirmation.'
                      : 'Your $weekName payment has not been confirmed yet.',
                  style: const TextStyle(fontSize: 15, height: 1.35),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.warning.withOpacity(0.35),
                    ),
                  ),
                  child: Text(
                    '$timeText\n(Checkpoint: $remainingLabel before deadline)',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.orange.shade800,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Dismiss'),
              ),
              if (!awaitingAdmin)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    if (pickRecordId.isEmpty) return;
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ManualPaymentScreen(
                          pickRecordId: pickRecordId,
                          weekName: weekName,
                          entryFee: 10.0,
                        ),
                      ),
                    );
                  },
                  child: const Text('Pay now'),
                )
              else
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Got it'),
                ),
            ],
          );
        },
      );
    } finally {
      _dialogOpen = false;
    }
  }

  String _milestoneKey(Duration d) {
    if (d.inHours >= 1 && d.inMinutes % 60 == 0) return '${d.inHours}h';
    return '${d.inMinutes}m';
  }

  String _formatRemaining(Duration d) {
    if (d.inHours >= 1 && d.inMinutes % 60 == 0) return '${d.inHours}h';
    if (d.inHours >= 1) {
      return '${d.inHours}h ${d.inMinutes % 60}m';
    }
    return '${d.inMinutes}m';
  }

  String _formatDuration(Duration d) {
    if (d.inDays > 0) {
      return '${d.inDays}d ${d.inHours % 24}h';
    }
    if (d.inHours > 0) {
      return '${d.inHours}h ${d.inMinutes % 60}m';
    }
    return '${d.inMinutes}m';
  }
}
