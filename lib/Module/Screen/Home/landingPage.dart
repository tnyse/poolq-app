// import '/auth/firebase_auth/auth_util.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pollapp/Model/games.dart';
import 'package:pollapp/Module/Screen/Home/LeaderbpardWidget.dart';
import 'package:provider/provider.dart';

import '../../../Constants/value.dart';
import '../../../Provider/homeProvider.dart';
import '../../../Widget/countDown.dart';
import '../../../Widget/reuse.dart';
import '../Auth/Forget.dart';
import '../Auth/Signup.dart';
import 'Play.dart';

class HomePageWidget extends StatefulWidget {
  const HomePageWidget({Key? key}) : super(key: key);

  @override
  _HomePageWidgetState createState() => _HomePageWidgetState();
}

class _HomePageWidgetState extends State<HomePageWidget> {
  // late HomePageModel _model;
  User? user = FirebaseAuth.instance.currentUser;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  List<GamesModel>? data;

  //
  // Future getGame(context) async {
  //   DataProvider dataProvider =
  //   Provider.of<DataProvider>(context, listen: false);
  //   var response =
  //   await http.get(Uri.parse('https://poolq.app/getnlf/${dataProvider.game!["name"]}'), headers: {
  //     'Content-Type': 'application/json; charset=UTF-8',
  //   }).timeout(Duration(seconds: 20));
  //   var body = json.decode(response.body);
  //   // print(body);
  //   // print(body);
  //   List body1 = body;
  //   List<GamesModel> gameModel = body1.map((data) {
  //     return GamesModel.fromJson(data, context);
  //   }).toList();
  //   setState(() {
  //     data = gameModel;
  //     print(data);
  //   });
  //   return body;
  // }
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DataProvider dataProvider =
          Provider.of<DataProvider>(context, listen: false);
//       if(dataProvider.game==null){
// print("dd");
//       }else{
//         print("zz");
//         getGame(context);
//       }
      check();
    });
    super.initState();

    // _model = createModel(context, () => HomePageModel());
  }

  check() {
    if (!user!.emailVerified) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => ForgetWidget(),
        ),
        (r) => false,
      );
    }
  }

  @override
  void dispose() {
    // _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // context.watch<FFAppState>();
    DataProvider dataProvider =
        Provider.of<DataProvider>(context, listen: true);

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: Color(0xFFF5F5F5),
      body: Stack(
        children: [
          Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height * 1,
            decoration: BoxDecoration(
              color: Color(0x90FFFFFF),
            ),
            child: Align(
              alignment: AlignmentDirectional(0, 0),
              child: Image.asset(
                'assets/images/assets.aboutamazon.jpg',
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height * 1,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height * 1,
            decoration: BoxDecoration(
              color: Color(0x6DFFFFFF),
            ),
          ),
          Align(
            alignment: AlignmentDirectional(0, -0.9),
            child: Text(
              'POOL Q',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: Colors.white,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 20.0, right: 20),
            child: Align(
              alignment: Alignment.topRight,
              child: IconButton(
                onPressed: () async {
                  FirebaseAuth auth = FirebaseAuth.instance;
                  await auth.signOut();
                  Navigator.pushAndRemoveUntil(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) {
                        return RegisterWidget();
                      },
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                        return FadeTransition(
                          opacity: animation,
                          child: child,
                        );
                      },
                    ),
                    (route) => false,
                  );
                },
                icon: Icon(
                  Icons.logout,
                  size: 30,
                  color: Color.fromRGBO(6, 58, 115, 1),
                ),
              ),
            ),
          ),
          Align(
            alignment: AlignmentDirectional(-0.15, -0.41),
            child: Image.asset(
              'assets/images/poolq.png',
              width: 300,
              height: 500,
              fit: BoxFit.contain,
            ),
          ),
          Align(
            alignment: AlignmentDirectional(0, 0),
            child: Padding(
              padding: EdgeInsetsDirectional.fromSTEB(0, 0, 0, 80),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(0, 0, 10, 20),
                    child: Align(
                        alignment: AlignmentDirectional(0, 0.58),
                        child: SizedBox(
                          width: 150,
                          height: 40,
                          child: TextButton(
                            onPressed: () async {
                              if( dataProvider.data == null || dataProvider.game == null){
                                customSnackbar(context, 'loading games');

                              }else{
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PlayWidget(),
                                  ),
                                  // (r) => false,
                                );
                              }
                              // await authManager.signOut();
                            },
                            child: Text(
                              'Let\'s Play!',
                              style: TextStyle(color: Colors.white),
                            ),
                            style: ButtonStyle(
                              elevation: MaterialStateProperty.all<double>(2),
                              shape: MaterialStateProperty.all<
                                      RoundedRectangleBorder>(
                                  RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30.0),
                                      side: BorderSide(
                                        color: Colors.transparent,
                                        width: 1,
                                      ))),
                              backgroundColor:
                                  MaterialStateProperty.all<Color>(primary),
                              textStyle: MaterialStateProperty.all<TextStyle>(
                                  TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                        )),
                  ),
                ],
              ),
            ),
          ),
          dataProvider.data == null || dataProvider.game == null
              ? Container()
              : Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    height: 55,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(3.0),
                          child: Center(
                              child: Text(
                            "NEXT GAME CLOSES BY: ${dataProvider.data != null ? dataProvider.data![0] : ""}",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          )),
                        ),
                        // Text("${dataProvider.formatStringDate(dataProvider.data?[0]!)}")
                        Padding(
                          padding: const EdgeInsets.all(2.0),
                          child: CountdownTimerDemo(dataProvider
                              .formatStringDate(dataProvider.data![0])),
                        )
                      ],
                    ),
                    color: primary,
                  ),
                ),
          dataProvider.data == null || dataProvider.game == null
          ?Center(
              child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: ColorScheme.fromSwatch()
                        .copyWith(secondary: Color(0xFF063a73)),
                  ),
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFF063a73)),
                    strokeWidth: 2,
                    backgroundColor: Colors.white,
                    //  valueColor: new AlwaysStoppedAnimation<Color>(color: Color(0xFF9B049B)),
                  )),
              SizedBox(
                height: 10,
              ),
              Text('Loading',
                  style: TextStyle(
                      color: Color(0xFF333333),
                      fontSize: 18,
                      fontWeight: FontWeight.w600)),
            ],
          )):
          Container()
        ],
      ),
    );
  }
}
