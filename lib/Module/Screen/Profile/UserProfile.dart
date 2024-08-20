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
// import 'package:share_plus/share_plus.dart';

// //import 'package:admob_flutter/admob_flutter.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// import 'package:phosphor_flutter/phosphor_flutter.dart';

class UserProfile extends StatefulWidget {
  const UserProfile({Key? key}) : super(key: key);

  @override
  State<UserProfile> createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  // GetStorage box = GetStorage();

  final GlobalKey<ScaffoldState> _scaffoldkey = new GlobalKey<ScaffoldState>();
  // List<DeliveryMainModel>? shipments;

  Stream<DocumentSnapshot>? paymentMethod;
  Future<dynamic>? info;
  @override
  void initState() {
    super.initState();
    User? user = FirebaseAuth.instance.currentUser;
    var authProvider = Provider.of<AuthProviders>(context, listen: false);
    // var locationProvider = Provider.of<LocationService>(context, listen: false);
    paymentMethod = FirebaseFirestore.instance
        .collection('paymentMethod')
        .doc(user!.uid)
        .snapshots();
    authProvider.getUserInfo();
  }

  TextEditingController username = TextEditingController();

  @override
  Widget build(BuildContext context) {
    // var locationProvider = Provider.of<LocationService>(context, listen: false);
    var authProvider = Provider.of<AuthProviders>(context, listen: false);
    Widget scaffold = Scaffold(
      // bottomNavigationBar: Container(
      //     color: Colors.white,
      //     child: AdmobBanner(
      //       adUnitId: Provider.of<DataProvider>(context, listen: false)
      //           .getBannerAdUnitId().toString(),
      //       adSize: AdmobBannerSize.BANNER,
      //       listener: (AdmobAdEvent event, Map<String, dynamic> ?args) {},
      //     )),
      backgroundColor: Color(0xFFF9FAFB),
      body: StreamBuilder<DocumentSnapshot>(
          stream: paymentMethod,
          builder:
              (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Something went wrong'));
            }

            if (snapshot.connectionState == ConnectionState.waiting ||
                snapshot.data == null) {
              return Center(
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
              ));
            }

            return Consumer<AuthProviders>(
              builder: (context, network, child) {
                return SingleChildScrollView(
                  physics: BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      Container(
                        child: Stack(
                          children: [
                            // Positioned(
                            //   top: 20,
                            //   child: Container(
                            //       width: MediaQuery.of(context).size.width,
                            //       // height: 260,
                            //       child: Image.asset(
                            //         "image/r3.png",
                            //         fit: BoxFit.cover,
                            //       )),
                            // ),

                            Container(
                                margin: EdgeInsets.only(bottom: 0),
                                width: MediaQuery.of(context).size.width,
                                height: 170,
                                decoration:
                                    BoxDecoration(color: Color(0xFF063a73)),
                                child: Text("")),
                            Padding(
                              padding: const EdgeInsets.only(
                                  top: 40.0, left: 20, right: 20),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Text(""),
                                      Spacer(),
                                      InkWell(
                                        onTap: () {
                                          // Navigator.push(
                                          //     context,
                                          //     PageRouteBuilder(
                                          //       pageBuilder: (context, animation, secondaryAnimation) {
                                          //         return NotificationPage();
                                          //         //SignUpAddress();
                                          //       },
                                          //       transitionsBuilder:
                                          //           (context, animation, secondaryAnimation, child) {
                                          //         return FadeTransition(
                                          //           opacity: animation,
                                          //           child: child,
                                          //         );
                                          //       },
                                          //     )
                                          // );
                                        },
                                        child: Padding(
                                          padding:
                                              const EdgeInsets.only(right: 0.0),
                                          child: Text(""),
                                        ),
                                      ),
                                      // Icon(PhosphorIcons.package,
                                      //     size: 30, color: Colors.white)
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Positioned(
                              top: MediaQuery.of(context).size.height * 0.1,
                              left: MediaQuery.of(context).size.width * 0.05,
                              child: Center(
                                child: Container(
                                  width:
                                      MediaQuery.of(context).size.width * 0.9,
                                  height: 80,
                                  child: Row(
                                    children: [
                                      Container(
                                        height: 120,
                                        width: 120,
                                        decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.white),
                                        child: Center(
                                          child: CircleAvatar(
                                            foregroundColor: Colors.white,
                                            backgroundColor: Colors.white,
                                            radius: 47,
                                            backgroundImage: authProvider.image
                                                        .toString() ==
                                                    ""
                                                ? AssetImage(
                                                    "assets/images/user.png")
                                                : NetworkImage(authProvider
                                                        .image
                                                        .toString())
                                                    as ImageProvider,
                                          ),
                                        ),
                                      ),
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                top: 15.0),
                                            child: Align(
                                                alignment: Alignment.topLeft,
                                                child: Text(
                                                  "${network.username}",
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.white,
                                                      fontSize: 16),
                                                )),
                                          ),
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 5.0),
                                            child: Align(
                                                alignment: Alignment.topLeft,
                                                child: Text(
                                                  "${network.email}",
                                                  style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 14),
                                                )),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          ],
                        ),
                        // decoration: BoxDecoration(
                        //   color: Color(0xFF2A7396),
                        //
                        // ),
                        width: MediaQuery.of(context).size.width,
                        height: 180,
                      ),
                      Column(
                        children: [
                          Align(
                            alignment: Alignment.topRight,
                            child: Padding(
                              padding: const EdgeInsets.only(
                                  top: 10.0, bottom: 0, right: 20),
                              child: ElevatedButton(
                                style: ButtonStyle(
                                    elevation: MaterialStateProperty.all(0),
                                    backgroundColor: MaterialStateProperty.all(
                                        Color(0xFF063a73)),
                                    shape: MaterialStateProperty.all<
                                            RoundedRectangleBorder>(
                                        RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(100.0),
                                    ))),
                                child: Container(
                                  width:
                                      MediaQuery.of(context).size.width * 0.22,
                                  height: 38,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(100)),
                                  child: Text(
                                    'Edit Profile',
                                    style: TextStyle(
                                        fontSize: 14, color: Colors.white),
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    PageRouteBuilder(
                                      pageBuilder: (context, animation,
                                          secondaryAnimation) {
                                        return EditProfile(); //SignUpAddress();
                                      },
                                      transitionsBuilder: (context, animation,
                                          secondaryAnimation, child) {
                                        return FadeTransition(
                                          opacity: animation,
                                          child: child,
                                        );
                                      },
                                    ),
                                  ).then((value) {
                                    setState(() {
                                      print("");
                                    });
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        margin: EdgeInsets.only(top: 30, bottom: 30),
                        child: Center(
                          child: Material(
                            borderRadius: BorderRadius.circular(15),
                            elevation: 4,
                            child: Container(
                              width: MediaQuery.of(context).size.width * 0.9,
                              height: 160,
                              child: Column(
                                children: [
                                  ListTile(
                                    onTap: () {
                                      showModalBottomSheet(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.only(
                                              topLeft: Radius.circular(10),
                                              topRight: Radius.circular(10)),
                                        ),
                                        backgroundColor: Colors.white,
                                        context: context,
                                        builder: (BuildContext context) {
                                          return Container(
                                            width: MediaQuery.of(context)
                                                .size
                                                .width,
                                            height: 240,
                                            child: Column(
                                              children: [
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: Align(
                                                    alignment:
                                                        Alignment.topCenter,
                                                    child: Container(
                                                      width: 60,
                                                      height: 5,
                                                      decoration: BoxDecoration(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(5),
                                                          color:
                                                              Colors.black12),
                                                    ),
                                                  ),
                                                ),
                                                Container(
                                                  color: snapshot.data!
                                                              .data()
                                                              .toString() ==
                                                          "null"
                                                      ? Colors.transparent
                                                      : snapshot.data!
                                                                  .get("type")
                                                                  .toLowerCase() ==
                                                              "Paypal"
                                                                  .toLowerCase()
                                                          ? Colors.black26
                                                          : Colors.transparent,
                                                  child: ListTile(
                                                    trailing: Icon(
                                                        Icons.arrow_forward_ios,
                                                        color:
                                                            Color(0xFF063a73)),
                                                    title: Text("PayPal"),
                                                    onTap: () {
                                                      Navigator.pop(context);
                                                      showModalBottomSheet(
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.only(
                                                                  topLeft: Radius
                                                                      .circular(
                                                                          10),
                                                                  topRight: Radius
                                                                      .circular(
                                                                          10)),
                                                        ),
                                                        backgroundColor:
                                                            Colors.white,
                                                        context: context,
                                                        builder: (BuildContext
                                                            context) {
                                                          return Padding(
                                                            padding: EdgeInsets.only(
                                                                bottom: MediaQuery.of(
                                                                        context)
                                                                    .viewInsets
                                                                    .bottom),
                                                            child: Container(
                                                              width:
                                                                  MediaQuery.of(
                                                                          context)
                                                                      .size
                                                                      .width,
                                                              height: 220,
                                                              child: Column(
                                                                children: [
                                                                  Padding(
                                                                    padding:
                                                                        const EdgeInsets
                                                                            .all(
                                                                            8.0),
                                                                    child:
                                                                        Align(
                                                                      alignment:
                                                                          Alignment
                                                                              .topCenter,
                                                                      child:
                                                                          Container(
                                                                        width:
                                                                            60,
                                                                        height:
                                                                            5,
                                                                        decoration: BoxDecoration(
                                                                            borderRadius:
                                                                                BorderRadius.circular(5),
                                                                            color: Colors.black12),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  Padding(
                                                                    padding: EdgeInsetsDirectional
                                                                        .fromSTEB(
                                                                            10,
                                                                            30,
                                                                            10,
                                                                            16),
                                                                    child:
                                                                        Container(
                                                                      width: double
                                                                          .infinity,
                                                                      child:
                                                                          TextFormField(
                                                                        controller:
                                                                            username,
                                                                        autofocus:
                                                                            true,
                                                                        autofillHints: [
                                                                          AutofillHints
                                                                              .name
                                                                        ],
                                                                        obscureText:
                                                                            false,
                                                                        decoration:
                                                                            InputDecoration(
                                                                          labelText:
                                                                              'Username tag',
                                                                          // labelStyle:
                                                                          // FlutterFlowTheme.of(
                                                                          //     context)
                                                                          //     .titleMedium
                                                                          //     .override(
                                                                          //   fontFamily:
                                                                          //   'Poppins',
                                                                          //   color: FlutterFlowTheme.of(
                                                                          //       context)
                                                                          //       .secondaryText,
                                                                          // ),
                                                                          enabledBorder:
                                                                              OutlineInputBorder(
                                                                            // borderSide:
                                                                            // BorderSide(
                                                                            //   color: FlutterFlowTheme.of(
                                                                            //       context)
                                                                            //       .alternate,
                                                                            //   width: 2,
                                                                            // ),
                                                                            borderRadius:
                                                                                BorderRadius.circular(40),
                                                                          ),
                                                                          focusedBorder:
                                                                              OutlineInputBorder(
                                                                            // borderSide:
                                                                            // BorderSide(
                                                                            //   color: FlutterFlowTheme.of(
                                                                            //       context)
                                                                            //       .primary,
                                                                            //   width: 2,
                                                                            // ),
                                                                            borderRadius:
                                                                                BorderRadius.circular(40),
                                                                          ),
                                                                          errorBorder:
                                                                              OutlineInputBorder(
                                                                            // borderSide:
                                                                            // BorderSide(
                                                                            //   color: FlutterFlowTheme.of(
                                                                            //       context)
                                                                            //       .error,
                                                                            //   width: 2,
                                                                            // ),
                                                                            borderRadius:
                                                                                BorderRadius.circular(40),
                                                                          ),
                                                                          focusedErrorBorder:
                                                                              OutlineInputBorder(
                                                                            // borderSide:
                                                                            // BorderSide(
                                                                            //   color: FlutterFlowTheme.of(
                                                                            //       context)
                                                                            //       .error,
                                                                            //   width: 2,
                                                                            // ),
                                                                            borderRadius:
                                                                                BorderRadius.circular(40),
                                                                          ),
                                                                          filled:
                                                                              true,
                                                                          // fillColor: FlutterFlowTheme
                                                                          //     .of(context)
                                                                          //     .secondaryBackground,
                                                                          // contentPadding:
                                                                          // EdgeInsetsDirectional
                                                                          //     .fromSTEB(
                                                                          //     24,
                                                                          //     24,
                                                                          //     24,
                                                                          //     24),
                                                                        ),
                                                                        // style: FlutterFlowTheme
                                                                        //     .of(context)
                                                                        //     .titleMedium,
                                                                        keyboardType:
                                                                            TextInputType.text,
                                                                        // validator: _model
                                                                        //     .emailAddressController1Validator
                                                                        //     .asValidator(
                                                                        //     context),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  Align(
                                                                    alignment:
                                                                        Alignment
                                                                            .center,
                                                                    child:
                                                                        Padding(
                                                                      padding: const EdgeInsets
                                                                          .only(
                                                                          top:
                                                                              10.0,
                                                                          bottom:
                                                                              0,
                                                                          right:
                                                                              0),
                                                                      child:
                                                                          ElevatedButton(
                                                                        style: ButtonStyle(
                                                                            elevation: MaterialStateProperty.all(0),
                                                                            backgroundColor: MaterialStateProperty.all(Color(0xFF063a73)),
                                                                            shape: MaterialStateProperty.all<RoundedRectangleBorder>(RoundedRectangleBorder(
                                                                              borderRadius: BorderRadius.circular(50.0),
                                                                            ))),
                                                                        child:
                                                                            Container(
                                                                          width:
                                                                              MediaQuery.of(context).size.width * 0.35,
                                                                          height:
                                                                              45,
                                                                          alignment:
                                                                              Alignment.center,
                                                                          decoration:
                                                                              BoxDecoration(borderRadius: BorderRadius.circular(50)),
                                                                          child:
                                                                              Text(
                                                                            'SAVE',
                                                                            style:
                                                                                TextStyle(fontSize: 14, color: Colors.white),
                                                                          ),
                                                                        ),
                                                                        onPressed:
                                                                            () async {
                                                                          User?
                                                                              user =
                                                                              FirebaseAuth.instance.currentUser;
                                                                          final paymentMethodCreateData =
                                                                              {
                                                                            "username":
                                                                                username.text,
                                                                            'date':
                                                                                FieldValue.serverTimestamp(),
                                                                            'uid':
                                                                                user!.uid,
                                                                            "type":
                                                                                "paypal"
                                                                          };
                                                                          CollectionReference
                                                                              paymentMethod =
                                                                              FirebaseFirestore.instance.collection('paymentMethod');
                                                                          paymentMethod
                                                                              .doc(user!.uid)
                                                                              .set(paymentMethodCreateData);
                                                                          Navigator.pop(
                                                                              context);
                                                                        },
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                      );
                                                    },
                                                  ),
                                                ),
                                                Divider(),
                                                Container(
                                                  color: snapshot.data!
                                                              .data()
                                                              .toString() ==
                                                          "null"
                                                      ? Colors.transparent
                                                      : snapshot.data!
                                                                  .get("type")
                                                                  .toLowerCase() ==
                                                              "cashapp"
                                                                  .toLowerCase()
                                                          ? Colors.black26
                                                          : Colors.transparent,
                                                  child: ListTile(
                                                    onTap: () {
                                                      Navigator.pop(context);
                                                      showModalBottomSheet(
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.only(
                                                                  topLeft: Radius
                                                                      .circular(
                                                                          10),
                                                                  topRight: Radius
                                                                      .circular(
                                                                          10)),
                                                        ),
                                                        backgroundColor:
                                                            Colors.white,
                                                        context: context,
                                                        builder: (BuildContext
                                                            context) {
                                                          return Padding(
                                                            padding: EdgeInsets.only(
                                                                bottom: MediaQuery.of(
                                                                        context)
                                                                    .viewInsets
                                                                    .bottom),
                                                            child: Container(
                                                              width:
                                                                  MediaQuery.of(
                                                                          context)
                                                                      .size
                                                                      .width,
                                                              height: 220,
                                                              child: Column(
                                                                children: [
                                                                  Padding(
                                                                    padding:
                                                                        const EdgeInsets
                                                                            .all(
                                                                            8.0),
                                                                    child:
                                                                        Align(
                                                                      alignment:
                                                                          Alignment
                                                                              .topCenter,
                                                                      child:
                                                                          Container(
                                                                        width:
                                                                            60,
                                                                        height:
                                                                            5,
                                                                        decoration: BoxDecoration(
                                                                            borderRadius:
                                                                                BorderRadius.circular(5),
                                                                            color: Colors.black12),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  Padding(
                                                                    padding: EdgeInsetsDirectional
                                                                        .fromSTEB(
                                                                            10,
                                                                            30,
                                                                            10,
                                                                            16),
                                                                    child:
                                                                        Container(
                                                                      width: double
                                                                          .infinity,
                                                                      child:
                                                                          TextFormField(
                                                                        controller:
                                                                            username,
                                                                        autofocus:
                                                                            true,
                                                                        autofillHints: [
                                                                          AutofillHints
                                                                              .name
                                                                        ],
                                                                        obscureText:
                                                                            false,
                                                                        decoration:
                                                                            InputDecoration(
                                                                          labelText:
                                                                              'Username tag',
                                                                          // labelStyle:
                                                                          // FlutterFlowTheme.of(
                                                                          //     context)
                                                                          //     .titleMedium
                                                                          //     .override(
                                                                          //   fontFamily:
                                                                          //   'Poppins',
                                                                          //   color: FlutterFlowTheme.of(
                                                                          //       context)
                                                                          //       .secondaryText,
                                                                          // ),
                                                                          enabledBorder:
                                                                              OutlineInputBorder(
                                                                            // borderSide:
                                                                            // BorderSide(
                                                                            //   color: FlutterFlowTheme.of(
                                                                            //       context)
                                                                            //       .alternate,
                                                                            //   width: 2,
                                                                            // ),
                                                                            borderRadius:
                                                                                BorderRadius.circular(40),
                                                                          ),
                                                                          focusedBorder:
                                                                              OutlineInputBorder(
                                                                            // borderSide:
                                                                            // BorderSide(
                                                                            //   color: FlutterFlowTheme.of(
                                                                            //       context)
                                                                            //       .primary,
                                                                            //   width: 2,
                                                                            // ),
                                                                            borderRadius:
                                                                                BorderRadius.circular(40),
                                                                          ),
                                                                          errorBorder:
                                                                              OutlineInputBorder(
                                                                            // borderSide:
                                                                            // BorderSide(
                                                                            //   color: FlutterFlowTheme.of(
                                                                            //       context)
                                                                            //       .error,
                                                                            //   width: 2,
                                                                            // ),
                                                                            borderRadius:
                                                                                BorderRadius.circular(40),
                                                                          ),
                                                                          focusedErrorBorder:
                                                                              OutlineInputBorder(
                                                                            // borderSide:
                                                                            // BorderSide(
                                                                            //   color: FlutterFlowTheme.of(
                                                                            //       context)
                                                                            //       .error,
                                                                            //   width: 2,
                                                                            // ),
                                                                            borderRadius:
                                                                                BorderRadius.circular(40),
                                                                          ),
                                                                          filled:
                                                                              true,
                                                                          // fillColor: FlutterFlowTheme
                                                                          //     .of(context)
                                                                          //     .secondaryBackground,
                                                                          // contentPadding:
                                                                          // EdgeInsetsDirectional
                                                                          //     .fromSTEB(
                                                                          //     24,
                                                                          //     24,
                                                                          //     24,
                                                                          //     24),
                                                                        ),
                                                                        // style: FlutterFlowTheme
                                                                        //     .of(context)
                                                                        //     .titleMedium,
                                                                        keyboardType:
                                                                            TextInputType.text,
                                                                        // validator: _model
                                                                        //     .emailAddressController1Validator
                                                                        //     .asValidator(
                                                                        //     context),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  Align(
                                                                    alignment:
                                                                        Alignment
                                                                            .center,
                                                                    child:
                                                                        Padding(
                                                                      padding: const EdgeInsets
                                                                          .only(
                                                                          top:
                                                                              10.0,
                                                                          bottom:
                                                                              0,
                                                                          right:
                                                                              0),
                                                                      child:
                                                                          ElevatedButton(
                                                                        style: ButtonStyle(
                                                                            elevation: MaterialStateProperty.all(0),
                                                                            backgroundColor: MaterialStateProperty.all(Color(0xFF063a73)),
                                                                            shape: MaterialStateProperty.all<RoundedRectangleBorder>(RoundedRectangleBorder(
                                                                              borderRadius: BorderRadius.circular(50.0),
                                                                            ))),
                                                                        child:
                                                                            Container(
                                                                          width:
                                                                              MediaQuery.of(context).size.width * 0.35,
                                                                          height:
                                                                              45,
                                                                          alignment:
                                                                              Alignment.center,
                                                                          decoration:
                                                                              BoxDecoration(borderRadius: BorderRadius.circular(50)),
                                                                          child:
                                                                              Text(
                                                                            'SAVE',
                                                                            style:
                                                                                TextStyle(fontSize: 14, color: Colors.white),
                                                                          ),
                                                                        ),
                                                                        onPressed:
                                                                            () async {
                                                                          User?
                                                                              user =
                                                                              FirebaseAuth.instance.currentUser;
                                                                          final paymentMethodCreateData =
                                                                              {
                                                                            "username":
                                                                                username.text,
                                                                            'date':
                                                                                FieldValue.serverTimestamp(),
                                                                            'uid':
                                                                                user!.uid,
                                                                            "type":
                                                                                "cashapp"
                                                                          };
                                                                          CollectionReference
                                                                              paymentMethod =
                                                                              FirebaseFirestore.instance.collection('paymentMethod');
                                                                          paymentMethod
                                                                              .doc(user!.uid)
                                                                              .set(paymentMethodCreateData);
                                                                          Navigator.pop(
                                                                              context);
                                                                        },
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                      );
                                                    },
                                                    trailing: Icon(
                                                        Icons.arrow_forward_ios,
                                                        color:
                                                            Color(0xFF063a73)),
                                                    title: Text("CashApp"),
                                                  ),
                                                ),
                                                Divider(),
                                                Container(
                                                  color: snapshot.data!
                                                              .data()
                                                              .toString() ==
                                                          "null"
                                                      ? Colors.transparent
                                                      : snapshot.data!
                                                                  .get("type")
                                                                  .toLowerCase() ==
                                                              "venmo"
                                                                  .toLowerCase()
                                                          ? Colors.black26
                                                          : Colors.transparent,
                                                  child: ListTile(
                                                    onTap: () {
                                                      Navigator.pop(context);
                                                      showModalBottomSheet(
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.only(
                                                                  topLeft: Radius
                                                                      .circular(
                                                                          10),
                                                                  topRight: Radius
                                                                      .circular(
                                                                          10)),
                                                        ),
                                                        backgroundColor:
                                                            Colors.white,
                                                        context: context,
                                                        builder: (BuildContext
                                                            context) {
                                                          return Padding(
                                                            padding: EdgeInsets.only(
                                                                bottom: MediaQuery.of(
                                                                        context)
                                                                    .viewInsets
                                                                    .bottom),
                                                            child: Container(
                                                              width:
                                                                  MediaQuery.of(
                                                                          context)
                                                                      .size
                                                                      .width,
                                                              height: 220,
                                                              child: Column(
                                                                children: [
                                                                  Padding(
                                                                    padding:
                                                                        const EdgeInsets
                                                                            .all(
                                                                            8.0),
                                                                    child:
                                                                        Align(
                                                                      alignment:
                                                                          Alignment
                                                                              .topCenter,
                                                                      child:
                                                                          Container(
                                                                        width:
                                                                            60,
                                                                        height:
                                                                            5,
                                                                        decoration: BoxDecoration(
                                                                            borderRadius:
                                                                                BorderRadius.circular(5),
                                                                            color: Colors.black12),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  Padding(
                                                                    padding: EdgeInsetsDirectional
                                                                        .fromSTEB(
                                                                            10,
                                                                            30,
                                                                            10,
                                                                            16),
                                                                    child:
                                                                        Container(
                                                                      width: double
                                                                          .infinity,
                                                                      child:
                                                                          TextFormField(
                                                                        controller:
                                                                            username,
                                                                        autofocus:
                                                                            true,
                                                                        autofillHints: [
                                                                          AutofillHints
                                                                              .name
                                                                        ],
                                                                        obscureText:
                                                                            false,
                                                                        decoration:
                                                                            InputDecoration(
                                                                          labelText:
                                                                              'Username tag',
                                                                          // labelStyle:
                                                                          // FlutterFlowTheme.of(
                                                                          //     context)
                                                                          //     .titleMedium
                                                                          //     .override(
                                                                          //   fontFamily:
                                                                          //   'Poppins',
                                                                          //   color: FlutterFlowTheme.of(
                                                                          //       context)
                                                                          //       .secondaryText,
                                                                          // ),
                                                                          enabledBorder:
                                                                              OutlineInputBorder(
                                                                            // borderSide:
                                                                            // BorderSide(
                                                                            //   color: FlutterFlowTheme.of(
                                                                            //       context)
                                                                            //       .alternate,
                                                                            //   width: 2,
                                                                            // ),
                                                                            borderRadius:
                                                                                BorderRadius.circular(40),
                                                                          ),
                                                                          focusedBorder:
                                                                              OutlineInputBorder(
                                                                            // borderSide:
                                                                            // BorderSide(
                                                                            //   color: FlutterFlowTheme.of(
                                                                            //       context)
                                                                            //       .primary,
                                                                            //   width: 2,
                                                                            // ),
                                                                            borderRadius:
                                                                                BorderRadius.circular(40),
                                                                          ),
                                                                          errorBorder:
                                                                              OutlineInputBorder(
                                                                            // borderSide:
                                                                            // BorderSide(
                                                                            //   color: FlutterFlowTheme.of(
                                                                            //       context)
                                                                            //       .error,
                                                                            //   width: 2,
                                                                            // ),
                                                                            borderRadius:
                                                                                BorderRadius.circular(40),
                                                                          ),
                                                                          focusedErrorBorder:
                                                                              OutlineInputBorder(
                                                                            // borderSide:
                                                                            // BorderSide(
                                                                            //   color: FlutterFlowTheme.of(
                                                                            //       context)
                                                                            //       .error,
                                                                            //   width: 2,
                                                                            // ),
                                                                            borderRadius:
                                                                                BorderRadius.circular(40),
                                                                          ),
                                                                          filled:
                                                                              true,
                                                                          // fillColor: FlutterFlowTheme
                                                                          //     .of(context)
                                                                          //     .secondaryBackground,
                                                                          // contentPadding:
                                                                          // EdgeInsetsDirectional
                                                                          //     .fromSTEB(
                                                                          //     24,
                                                                          //     24,
                                                                          //     24,
                                                                          //     24),
                                                                        ),
                                                                        // style: FlutterFlowTheme
                                                                        //     .of(context)
                                                                        //     .titleMedium,
                                                                        keyboardType:
                                                                            TextInputType.text,
                                                                        // validator: _model
                                                                        //     .emailAddressController1Validator
                                                                        //     .asValidator(
                                                                        //     context),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  Align(
                                                                    alignment:
                                                                        Alignment
                                                                            .center,
                                                                    child:
                                                                        Padding(
                                                                      padding: const EdgeInsets
                                                                          .only(
                                                                          top:
                                                                              10.0,
                                                                          bottom:
                                                                              0,
                                                                          right:
                                                                              0),
                                                                      child:
                                                                          ElevatedButton(
                                                                        style: ButtonStyle(
                                                                            elevation: MaterialStateProperty.all(0),
                                                                            backgroundColor: MaterialStateProperty.all(Color(0xFF063a73)),
                                                                            shape: MaterialStateProperty.all<RoundedRectangleBorder>(RoundedRectangleBorder(
                                                                              borderRadius: BorderRadius.circular(50.0),
                                                                            ))),
                                                                        child:
                                                                            Container(
                                                                          width:
                                                                              MediaQuery.of(context).size.width * 0.35,
                                                                          height:
                                                                              45,
                                                                          alignment:
                                                                              Alignment.center,
                                                                          decoration:
                                                                              BoxDecoration(borderRadius: BorderRadius.circular(50)),
                                                                          child:
                                                                              Text(
                                                                            'SAVE',
                                                                            style:
                                                                                TextStyle(fontSize: 14, color: Colors.white),
                                                                          ),
                                                                        ),
                                                                        onPressed:
                                                                            () async {
                                                                          User?
                                                                              user =
                                                                              FirebaseAuth.instance.currentUser;
                                                                          final paymentMethodCreateData =
                                                                              {
                                                                            "username":
                                                                                username.text,
                                                                            'date':
                                                                                FieldValue.serverTimestamp(),
                                                                            'uid':
                                                                                user!.uid,
                                                                            "type":
                                                                                "venmo"
                                                                          };
                                                                          CollectionReference
                                                                              paymentMethod =
                                                                              FirebaseFirestore.instance.collection('paymentMethod');
                                                                          paymentMethod
                                                                              .doc(user!.uid)
                                                                              .set(paymentMethodCreateData);
                                                                          Navigator.pop(
                                                                              context);
                                                                        },
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                      );
                                                    },
                                                    trailing: Icon(
                                                        Icons.arrow_forward_ios,
                                                        color:
                                                            Color(0xFF063a73)),
                                                    title: Text("Venmo"),
                                                  ),
                                                ),
                                                Divider(),
                                              ],
                                            ),
                                          );
                                        },
                                      );
                                    },
                                    leading: Icon(Icons.chat_outlined,
                                        color: Color(0xFF063a73)),
                                    trailing: Icon(Icons.arrow_forward_ios,
                                        color: Color(0xFF063a73)),
                                    title: Text("Payment method"),
                                    subtitle: Text(
                                        "${snapshot.data!.data().toString() == "null" ? "" : snapshot.data!.get("type")}"
                                            .toUpperCase()),
                                  ),
                                  Divider(),
                                  ListTile(
                                    onTap: () {},
                                    leading: Icon(Icons.home_work_outlined,
                                        color: Color(0xFF063a73)),
                                    trailing: Icon(Icons.arrow_forward_ios,
                                        color: Color(0xFF063a73)),
                                    title: Text("Official"),
                                    subtitle: Text("Follow us on Social media"),
                                  ),
                                ],
                              ),
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(15)),
                            ),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 10.0, bottom: 15),
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.81,
                            height: 50,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.transparent),
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            child: ElevatedButton(
                              style: ButtonStyle(
                                  elevation: MaterialStateProperty.all(0),
                                  backgroundColor: MaterialStateProperty.all(
                                      Colors.transparent),
                                  shape: MaterialStateProperty.all<
                                          RoundedRectangleBorder>(
                                      RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                  ))),
                              child: Container(
                                width: MediaQuery.of(context).size.width * 0.81,
                                height: 50,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10)),
                                child: Text(
                                  'Change Password',
                                  style: TextStyle(
                                      fontSize: 20, color: Color(0xFF063a73)),
                                ),
                              ),
                              onPressed: () async {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ForgetWidget(),
                                  ),
                                );
                                // Navigator.push(
                                //   context,
                                //   PageRouteBuilder(
                                //     pageBuilder: (context, animation, secondaryAnimation) {
                                //       return ForgetPassword(); //SignUpAddress();
                                //     },
                                //     transitionsBuilder:
                                //         (context, animation, secondaryAnimation, child) {
                                //       return FadeTransition(
                                //         opacity: animation,
                                //         child: child,
                                //       );
                                //     },
                                //   ),
                                //
                                // );
                              },
                            ),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 0.0, bottom: 15),
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.81,
                            height: 50,
                            decoration: BoxDecoration(
                              border: Border.all(color: Color(0xFF063a73)),
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            child: ElevatedButton(
                              style: ButtonStyle(
                                  elevation: MaterialStateProperty.all(0),
                                  backgroundColor: MaterialStateProperty.all(
                                      Colors.transparent),
                                  shape: MaterialStateProperty.all<
                                          RoundedRectangleBorder>(
                                      RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                  ))),
                              child: Container(
                                width: MediaQuery.of(context).size.width * 0.81,
                                height: 50,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10)),
                                child: Text(
                                  'Sign Out',
                                  style: TextStyle(
                                      fontSize: 20, color: Color(0xFF063a73)),
                                ),
                              ),
                              onPressed: () async {
                                FirebaseAuth auth = FirebaseAuth.instance;
                                await auth.signOut();
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder: (context, animation,
                                        secondaryAnimation) {
                                      return RegisterWidget();
                                    },
                                    transitionsBuilder: (context, animation,
                                        secondaryAnimation, child) {
                                      return FadeTransition(
                                        opacity: animation,
                                        child: child,
                                      );
                                    },
                                  ),
                                  (route) => false,
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 0.0, bottom: 15),
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.81,
                            height: 50,
                            decoration: BoxDecoration(
                              border: Border.all(color: Color(0xFF063a73)),
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            child: ElevatedButton(
                              style: ButtonStyle(
                                  elevation: MaterialStateProperty.all(0),
                                  backgroundColor: MaterialStateProperty.all(
                                      Colors.transparent),
                                  shape: MaterialStateProperty.all<
                                          RoundedRectangleBorder>(
                                      RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                  ))),
                              child: Container(
                                width: MediaQuery.of(context).size.width * 0.81,
                                height: 50,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10)),
                                child: Text(
                                  'Share App',
                                  style: TextStyle(
                                      fontSize: 20, color: Color(0xFF063a73)),
                                ),
                              ),
                              onPressed: () async {
                                // Share.share(
                                //     """Hi!, I’m inviting you to come join our NFL football pool!

                                //   Download the app here:  https://poolq.app""",
                                //     subject: 'PoolQ App');
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          }),
    );

    return scaffold;
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
