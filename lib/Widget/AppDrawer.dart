import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:poolqapp/Module/Screen/Admin/AdminLogin.dart';
import 'package:poolqapp/constants/app_theme.dart';
import 'package:poolqapp/utils/avatar_url.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue,
            ),
            accountName: Text(
              user?.displayName ?? 'Guest',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            accountEmail: Text(
              user?.email ?? 'guest@example.com',
            ),
            currentAccountPicture: CircleAvatar(
              backgroundImage: resolveAvatarImage(
                photoUrl: user?.photoURL,
                email: user?.email,
                size: 160,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () {
              Navigator.pop(context);
              // Navigate back to home screen
              Navigator.pushReplacementNamed(context, '/home');
            },
          ),
          ListTile(
            leading: const Icon(Icons.leaderboard),
            title: const Text('Leaderboard'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/home');
              // Since we don't have LeaderboardWidget properly set up, 
              // we'll navigate to home for now
            },
          ),
          ListTile(
            leading: const Icon(Icons.rule),
            title: const Text('Rules'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/home');
              // Since we don't have RuleWidget properly set up,
              // we'll navigate to home for now
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.admin_panel_settings),
            title: const Text('Admin Dashboard'),
            subtitle: const Text('Manage games and winners'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AdminLogin()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pop(context);
              // Navigate to login screen
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
    );
  }
} 