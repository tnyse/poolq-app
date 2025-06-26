import 'editProfile.dart';
import '../Auth/Forget.dart';
import '../Auth/Signup.dart';
import '../../../../main.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../Provider/homeProvider.dart';
import 'package:get_storage/get_storage.dart';
import '../../../Provider/AuthProviders.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/auth_service.dart';
import '../../../screens/auth/login_screen.dart';
import '../../../Model/user_model.dart';
// import 'package:share_plus/share_plus.dart';

// //import 'package:admob_flutter/admob_flutter.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// import 'package:phosphor_flutter/phosphor_flutter.dart';

class UserProfile extends StatelessWidget {
  const UserProfile({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProviders>(context);
    final UserModel? user = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (user != null) ...[
              Text('Name: ${user.displayName ?? "Not set"}'),
              const SizedBox(height: 8),
              Text('Email: ${user.email ?? "Not set"}'),
              const SizedBox(height: 8),
              Text('Phone: ${user.phone ?? "Not set"}'),
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  onPressed: () async {
                    await authProvider.signOut(context);
                    if (context.mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                        (route) => false,
                      );
                    }
                  },
                  child: const Text('Sign Out'),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    // Show confirmation dialog
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Account'),
                        content: const Text(
                          'Are you sure you want to delete your account? This action cannot be undone.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      try {
                        final authService = AuthService();
                        await authService.deleteUserAccount();
                        
                        if (context.mounted) {
                          // Navigate to login screen
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginScreen()),
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
                  },
                  child: const Text('Delete Account'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class CurveImage extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0.0, size.height - 30);
    path.quadraticBezierTo(
        size.width / 4, size.height, size.width / 2, size.height);
    path.quadraticBezierTo(size.width - (size.width / 4), size.height,
        size.width, size.height - 30);
    path.lineTo(size.width, 0.0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class SwitchButton extends StatefulWidget {
  @override
  SwitchClass createState() => new SwitchClass();
}

class SwitchClass extends State {
  bool isSwitched = false;
  var textValue = 'Switch is OFF';

  void toggleSwitch(bool value) {
    if (isSwitched == false) {
      setState(() {
        isSwitched = true;
        textValue = 'Switch Button is ON';
      });
      print('Switch Button is ON');
    } else {
      setState(() {
        isSwitched = false;
        textValue = 'Switch Button is OFF';
      });
      print('Switch Button is OFF');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: 1.2,
      child: Switch(
        onChanged: toggleSwitch,
        value: isSwitched,
        activeColor: Colors.red,
        activeTrackColor: Colors.black12,
        inactiveThumbColor: Colors.green,
        inactiveTrackColor: Colors.black12,
      ),
    );
  }
}
