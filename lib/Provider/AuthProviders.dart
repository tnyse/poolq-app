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

// String mainUrl = "https://api.poolq.app";
String mainUrl = "http://10.0.2.2:3000";

class AuthProviders with ChangeNotifier {
  String image = "";
  String username = "";
  String email = "";
  String phone = "";
  static GetStorage box = GetStorage();
  // String mode = box.read("mode")==null||box.read("mode")=="null"?"REG":box.read("mode");
  FirebaseAuth auth = FirebaseAuth.instance;

// changeMode(value){
//     mode = value;
//     box.write("mode", mode);
//   notifyListeners();
// }

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
    username = user!.displayName!;
    image = user.photoURL!;
    phone = user.phoneNumber!;
    email = user.email!;
  }

  Future register(context, email, password, displayName) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      await userCredential.user!.updateDisplayName(displayName);
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => HomePage(),
        ),
        (r) => false,
      );
      // return true;
    } on FirebaseAuthException catch (e) {
      print(e);
      Navigator.pop(context);
      if (e.code == 'weak-password') {
        // print('The password provided is too weak.');
        customSnackbar(context, 'The password provided is too weak.');
        // return false;
      } else if (e.code == 'email-already-in-use') {
        // print('The account already exists for that email.');
        customSnackbar(context, 'The account already exists for that email.');
        // return false;
      }
    } catch (e) {
      Navigator.pop(context);
      // print(e);
      customSnackbar(context, e.toString());
      // return false;
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

  Future login(context, email, password) async {
    print(email);
    print(password);
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => HomePage(),
        ),
        (r) => false,
      );
      // return true;
    } on FirebaseAuthException catch (e) {
      print(e);
      Navigator.pop(context);
      if (e.code == 'user-not-found') {
        customSnackbar(context, "No user found for that email.");
        // return false;
        // print('No user found for that email.');
      } else if (e.code == 'wrong-password') {
        // print('Wrong password provided for that user.');
        customSnackbar(context, "Wrong password provided for that user.");
        // return false;
      } else {
        customSnackbar(context, e.message.toString());
        // return false;
      }
      // Navigator.pop(context);
    } catch (e) {
      Navigator.pop(context);
      print(e);
      customSnackbar(context, e.toString());
      return false;
    }
  }
}
