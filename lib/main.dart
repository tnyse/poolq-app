import 'dart:io';
import 'package:rive/rive.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'Module/Screen/Auth/Signup.dart';
import 'Module/Screen/Home/HomePage.dart';
import 'Module/Screen/Home/webPayment.dart';
import 'package:get_storage/get_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'Module/Screen/Home/LeaderbpardWidget.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:poolqapp/Provider/homeProvider.dart';
import 'package:poolqapp/Provider/AuthProviders.dart';




Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    // options: FirebaseOptions(
    //     apiKey: "AIzaSyB_8GwxAp1O-4lW0bLSHHD8ORhrDD2rj2U",
    //     projectId: "poolr-b5392",
    //     messagingSenderId: "841410602650",
    //     appId: "1:841410602650:web:86f41c34cc3356c0602123"),
  );
  GetStorage.init();

  String? getAppId() {
    if (Platform.isIOS) {
      return 'ca-app-pub-1065880110189655~2487853650';
    } else if (Platform.isAndroid) {
      return 'ca-app-pub-1065880110189655~2487853650';
    }
    return null;
  }

  Provider.debugCheckInvalidValueType = null;
  // Admob.initialize(testDeviceIds: [getAppId().toString()]);

  //Assign publishable key to flutter_stripe
  Stripe.publishableKey = "";


  //Load our .env file that contains our Stripe Secret key
  await dotenv.load(fileName: "assets/.env");
  // setUrlStrategy(PathUrlStrategy());
  runApp(MultiProvider(providers: [
    ChangeNotifierProvider<DataProvider>(
      create: (context) => DataProvider(),
    ),
    ChangeNotifierProvider<AuthProviders>(
      create: (context) => AuthProviders(),
    ),
  ], child: MyApp()));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // initialRoute: '/',
      // routes: {
      //   '/': (context) => Home(),
      //   '/processing': (context) => ProcessingPayment(),
      // },
      title: 'PoolQ',
      home: Home()
      // Center(child: Text("hjsjhsjs"))
      // Home(),
    );
  }
}

class Home extends StatefulWidget {
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  void initState() {
    DataProvider dataProvider =
        Provider.of<DataProvider>(context, listen: false);
    dataProvider.getWeek();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(Duration(seconds: 5), () async {
        return decideFirstWidget();
      });
    });

    super.initState();
  }

  Future<dynamic> decideFirstWidget() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null || user == 'null' || user == '') {
      return Navigator.pushAndRemoveUntil(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) {
            return RegisterWidget();
          },
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        ),
        (route) => false,
      );
    } else {
      return Navigator.pushAndRemoveUntil(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) {
            return HomePage();
            // HomePageWidget();
          },
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        ),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: RiveAnimation.asset(
        'assets/riv/football_intro.riv',
        fit: BoxFit.fitHeight,
      ),
    );
  }
}
