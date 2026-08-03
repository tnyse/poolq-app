import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:poolqapp/Module/Screen/Admin/AdminLogin.dart';
import 'package:poolqapp/Module/Screen/Profile/editProfile.dart';
import 'package:poolqapp/Provider/AuthProviders.dart';
import 'package:poolqapp/Model/user_model.dart';
import 'package:poolqapp/constants/app_theme.dart';
import 'package:poolqapp/screens/auth/login_screen.dart';
import 'package:poolqapp/services/auth_service.dart';

class UserProfile extends StatelessWidget {
  const UserProfile({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProviders>(context);
    final UserModel? user = authProvider.user;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        actions: [
          if (user != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit Profile',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => EditProfile()),
                );
              },
            ),
        ],
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _AvatarHeader(user: user, authProvider: authProvider),
                  const SizedBox(height: 24),
                  _InfoCard(user: user),
                  const SizedBox(height: 32),
                  _ActionButtons(user: user, authProvider: authProvider),
                ],
              ),
            ),
    );
  }
}

class _AvatarHeader extends StatelessWidget {
  final UserModel user;
  final AuthProviders authProvider;

  const _AvatarHeader({required this.user, required this.authProvider});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 44,
          backgroundColor: const Color(0x1A063a73), // primaryBlue 10% opacity
          backgroundImage: authProvider.image.toString().isNotEmpty
              ? NetworkImage(authProvider.image.toString()) as ImageProvider
              : const AssetImage('assets/images/user.png'),
        ),
        const SizedBox(height: 12),
        Text(
          user.displayName.isNotEmpty ? user.displayName : 'Player',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppTheme.onSurface,
              ),
        ),
        if (user.email.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            user.email,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.onSurfaceVariant,
                ),
          ),
        ],
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final UserModel user;

  const _InfoCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            _InfoRow(
              icon: Icons.person_outline,
              label: 'Display Name',
              value: user.displayName.isNotEmpty ? user.displayName : 'Not set',
            ),
            const Divider(height: 1, indent: 56),
            _InfoRow(
              icon: Icons.email_outlined,
              label: 'Email',
              value: user.email.isNotEmpty ? user.email : 'Not set',
            ),
            const Divider(height: 1, indent: 56),
            _InfoRow(
              icon: Icons.phone_outlined,
              label: 'Phone',
              value: user.phone.isNotEmpty ? user.phone : 'Not set',
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryBlue, size: 22),
      title: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppTheme.onSurfaceVariant,
            ),
      ),
      subtitle: Text(
        value,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final UserModel user;
  final AuthProviders authProvider;

  const _ActionButtons({required this.user, required this.authProvider});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.primaryBlue,
            side: const BorderSide(color: AppTheme.primaryBlue),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminLogin()),
            );
          },
          icon: const Icon(Icons.admin_panel_settings_outlined),
          label: const Text('Admin Login'),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: AppTheme.primaryButtonStyle,
            onPressed: () async {
              await authProvider.signOut(context);
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            icon: const Icon(Icons.logout),
            label: const Text('Sign Out'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.error,
              side: const BorderSide(color: AppTheme.error),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => _confirmDeleteAccount(context),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete Account'),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      try {
        await AuthService().deleteUserAccount();
        if (context.mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting account: $e')),
          );
        }
      }
    }
  }
}
