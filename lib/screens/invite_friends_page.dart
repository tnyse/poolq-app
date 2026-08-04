import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:poolqapp/constants/app_theme.dart';

/// Invite-friends funnel (replaces the old "news" screen).
class InviteFriendsPage extends StatelessWidget {
  static const inviteCode = 'fitz';
  static const inviteUrl = 'https://poolq.app';
  static const inviteMessage =
      'Join me on PoolQ — the invite-only NFL picks pool.\n'
      'Sign up at $inviteUrl with invite code: $inviteCode';

  const InviteFriendsPage({super.key});

  Future<void> _copy(BuildContext context, String label, String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied'),
        backgroundColor: AppTheme.success,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _shareInvite(BuildContext context) async {
    await Clipboard.setData(const ClipboardData(text: inviteMessage));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Invite message copied — paste it in a text, email, or chat'),
        backgroundColor: AppTheme.primaryBlue,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
          'Invite Friends',
          style: theme.textTheme.titleLarge?.copyWith(
            color: AppTheme.primaryBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryBlue,
                    AppTheme.primaryBlue.withOpacity(0.85),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(Icons.group_add, size: 56, color: Colors.white),
                  const SizedBox(height: 16),
                  Text(
                    'Invite friends to play',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'PoolQ is invite-only. Share the link and code so your crew can join this week\'s pool.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _InviteCard(
              icon: Icons.link,
              title: 'App link',
              value: inviteUrl,
              onCopy: () => _copy(context, 'Link', inviteUrl),
            ),
            const SizedBox(height: 12),
            _InviteCard(
              icon: Icons.vpn_key_outlined,
              title: 'Invite code',
              value: inviteCode,
              emphasize: true,
              onCopy: () => _copy(context, 'Invite code', inviteCode),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _shareInvite(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.ios_share),
              label: const Text(
                'Copy invite message',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _copy(context, 'Invite code', inviteCode),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryBlue,
                side: const BorderSide(color: AppTheme.primaryBlue),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.copy),
              label: const Text('Copy code only'),
            ),
            const SizedBox(height: 24),
            Text(
              'Tip: Friends create an account at poolq.app and enter the invite code during signup.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _InviteCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onCopy;
  final bool emphasize;

  const _InviteCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.onCopy,
    this.emphasize = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryBlue),
        title: Text(title),
        subtitle: Text(
          value,
          style: TextStyle(
            fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
            fontSize: emphasize ? 20 : 15,
            letterSpacing: emphasize ? 1.2 : 0,
            color: AppTheme.onSurface,
          ),
        ),
        trailing: IconButton(
          tooltip: 'Copy',
          onPressed: onCopy,
          icon: const Icon(Icons.copy, color: AppTheme.primaryBlue),
        ),
      ),
    );
  }
}
