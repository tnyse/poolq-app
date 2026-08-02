import 'dart:io';
import '../Widget/reuse.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../Module/Screen/Home/HomePage.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../Module/Screen/Home/landingPage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Model/user_model.dart';

class AuthProviders with ChangeNotifier {
  String image = "";
  String username = "";
  String email = "";
  String phone = "";
  static GetStorage box = GetStorage();
  // String mode = box.read("mode")==null||box.read("mode")=="null"?"REG":box.read("mode");
  FirebaseAuth auth = FirebaseAuth.instance;
  bool _isInitialized = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  UserModel? _user;
  
  // Getter for the current user
  UserModel? get user => _user;

  // Initialize persistence
  Future<void> initializePersistence() async {
    if (_isInitialized) return;
    
    try {
      // Set persistence for web
      if (kIsWeb) {
        await auth.setPersistence(Persistence.LOCAL);
      }
      
      // Initialize shared preferences
      final prefs = await SharedPreferences.getInstance();
      
      // Check for existing session
      final savedEmail = prefs.getString('user_email');
      final savedPassword = prefs.getString('user_password');
      
      if (savedEmail != null && savedPassword != null) {
        try {
          await auth.signInWithEmailAndPassword(
            email: savedEmail,
            password: savedPassword,
          );
        } catch (e) {
          // Clear invalid credentials
          await prefs.remove('user_email');
          await prefs.remove('user_password');
        }
      }
      
      _isInitialized = true;
    } catch (e) {
      print('Error initializing persistence: $e');
    }
  }

  // Save credentials for persistence
  Future<void> _saveCredentials(String email, String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_email', email);
      await prefs.setString('user_password', password);
    } catch (e) {
      print('Error saving credentials: $e');
    }
  }

  // Clear saved credentials
  Future<void> _clearCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_email');
      await prefs.remove('user_password');
    } catch (e) {
      print('Error clearing credentials: $e');
    }
  }

  uploadImage({imagePath, context}) async {
    final _firebaseStorage = FirebaseStorage.instance;
    final _imagePicker = ImagePicker();
    XFile? image;
    //Check Permissions
    // await Permission.photos.request();
    await Permission.storage.request();

    // var permissionStatus = await Permission.photos.status;
    var permissionStatus2 = await Permission.storage.status;

    if (permissionStatus2.isGranted) {
      //Select Image
      image = await _imagePicker.pickImage(source: ImageSource.gallery);
      var file = File(image!.path);

      if (image != null) {
        //Upload to Firebase
        var snapshot = await _firebaseStorage
            .ref()
            .child('images/imageName')
            .putFile(file);
        var downloadUrl = await snapshot.ref.getDownloadURL();
        // setState(() {
        this.image = downloadUrl;
        User? user = FirebaseAuth.instance.currentUser;
        await user!.updatePhotoURL(this.image);
        // });
      } else {
        print('No Image Path Received');
      }
    } else {
      print('Permission not granted. Try Again with permission access');
    }
    notifyListeners();
  }

  getUserInfo() async {
    User? user = FirebaseAuth.instance.currentUser;
    username = user?.displayName ?? '';
    image = user?.photoURL ?? '';
    phone = user?.phoneNumber ?? '';
    email = user?.email ?? '';
  }

  // Method used by the new screens
  Future<bool> registerUser(String email, String password) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        throw 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        throw 'The account already exists for that email.';
      } else {
        throw e.message ?? 'An error occurred during registration';
      }
    } catch (e) {
      throw e.toString();
    }
  }

  // Method used by the new screens — real Firebase auth.
  // Optional debug bypass: --dart-define=BYPASS_AUTH=true (debug builds only).
  Future<bool> loginUser(String email, String password) async {
    const bypassAuth = bool.fromEnvironment('BYPASS_AUTH', defaultValue: false);
    if (kDebugMode && bypassAuth) {
      debugPrint('DEBUG: BYPASS_AUTH enabled — mock login only');
      _user = UserModel(
        userId: 'test_user',
        email: email.trim().isEmpty ? 'test@poolq.com' : email.trim(),
        displayName: 'Test User',
        phone: '',
        avatar: '',
        isActive: true,
        userType: 'player',
        joinDate: DateTime.now(),
        invitationCode: 'TEST2024',
        invitedBy: 'system',
        preferences: {},
        statistics: {
          'totalWinnings': 0.0,
          'winRate': 0.0,
          'poolsPlayed': 0,
        },
      );
      notifyListeners();
      return true;
    }

    try {
      final credential = await auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await _saveCredentials(email.trim(), password);

      final firebaseUser = credential.user;
      if (firebaseUser != null) {
        final doc =
            await _firestore.collection('users').doc(firebaseUser.uid).get();
        if (doc.exists) {
          _user = UserModel.fromFirestore(doc);
        } else {
          _user = UserModel(
            userId: firebaseUser.uid,
            email: firebaseUser.email ?? email.trim(),
            displayName: firebaseUser.displayName ?? 'Player',
            phone: firebaseUser.phoneNumber ?? '',
            avatar: firebaseUser.photoURL ?? '',
            isActive: true,
            userType: 'player',
            joinDate: DateTime.now(),
            invitationCode: '',
            invitedBy: '',
            preferences: {},
            statistics: const {},
          );
        }
      }
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('loginUser FirebaseAuthException: ${e.code}');
      rethrow;
    } catch (e) {
      debugPrint('loginUser error: $e');
      rethrow;
    }
  }

  // Modified register method
  Future register(context, email, password, displayName) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      await userCredential.user!.updateDisplayName(displayName);
      
      // Save credentials for persistence
      await _saveCredentials(email, password);
      
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => HomePage(),
        ),
        (r) => false,
      );
    } on FirebaseAuthException catch (e) {
      print(e);
      Navigator.pop(context);
      if (e.code == 'weak-password') {
        customSnackbar(context, 'The password provided is too weak.');
      } else if (e.code == 'email-already-in-use') {
        customSnackbar(context, 'The account already exists for that email.');
      }
    } catch (e) {
      Navigator.pop(context);
      customSnackbar(context, e.toString());
    }
  }

  Future verifyEmail(context) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      print(user!.email);
      print(user.emailVerified);
      print(user != null);
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        customSnackbar(context, 'Email has been sent to ${user.email}');
        Navigator.pop(context);
      }
    } catch (e) {
      Navigator.pop(context);
    }
  }

  // Modified login method
  Future login(context, email, password) async {
    print(email);
    print(password);
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      
      // Save credentials for persistence
      await _saveCredentials(email, password);
      
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => HomePage(),
        ),
        (r) => false,
      );
    } on FirebaseAuthException catch (e) {
      print(e);
      Navigator.pop(context);
      if (e.code == 'user-not-found') {
        customSnackbar(context, "No user found for that email.");
      } else if (e.code == 'wrong-password') {
        customSnackbar(context, "Wrong password provided for that user.");
      } else {
        customSnackbar(context, e.message.toString());
      }
    } catch (e) {
      Navigator.pop(context);
      print(e);
      customSnackbar(context, e.toString());
      return false;
    }
  }

  // Sign out method
  Future<void> signOut(BuildContext context) async {
    try {
      debugPrint('Attempting sign out...');
      await auth.signOut();
      await _clearCredentials();
      _user = null;
      notifyListeners();
      debugPrint('Sign out successful');
    } catch (e) {
      debugPrint('Sign out error: $e');
      throw 'Failed to sign out. Please try again.';
    }
  }
}
