// // Copyright 2013 The Flutter Authors. All rights reserved.
// // Use of this source code is governed by a BSD-style license that can be
// // found in the LICENSE file.

// // ignore_for_file: public_member_api_docs

// import 'dart:async';
// import 'dart:convert';
// import 'dart:js_interop_unsafe';
// import 'dart:typed_data';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:get_storage/get_storage.dart';
// import 'package:provider/provider.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:webview_all/webview_all.dart';
// import 'package:http/http.dart' as http;
// import '../../../Provider/homeProvider.dart';
// import '../../../Widget/reuse.dart';
// import 'LeaderbpardWidget.dart';



// class HomeWebViewExample extends StatefulWidget {
//   // const _WebViewExample();

//   @override
//   _WebViewExampleState createState() => _WebViewExampleState();
// }

// class _WebViewExampleState extends State<WebViewExample> {
//   Stream<QuerySnapshot> ?_pickrecord;
//   User? user = FirebaseAuth.instance.currentUser;

//   @override
//   void initState() {
//     super.initState();
//     // user!.uid
//     DataProvider dataProvider = Provider.of<DataProvider>(context, listen: false);
//     _pickrecord = FirebaseFirestore.instance.collection('payment').where("uid", isEqualTo: "1").snapshots();
//     dataProvider.initPayment(context, data:{
//           "week": dataProvider.game!["name"],
//         "tiebreaker": dataProvider.tiebreaker.toString(),
//         'date': FieldValue.serverTimestamp(),
//         'picks': dataProvider.playerPicks,
//         'uid': user!.uid,
//         "displayName": user!.displayName,
//         "photoURL": user!.photoURL
//       });
//     // dataProvider.initPayment(context, data:{
//     //   "week": "REG1",
//     //   "tiebreaker": "10",
//     //   'date': FieldValue.serverTimestamp(),
//     //   'picks': ["NEW", "ERE"],
//     //   'uid': "10",
//     //   "displayName": "frank",
//     //   "photoURL": ""
//     // });
//   }


//   @override
//   Widget build(BuildContext context) {
//     DataProvider dataProvider = Provider.of<DataProvider>(context);
//     return Scaffold(
//       body:Center(
//         // Look here!
//           child: Webview(url: "${mainUrl}/pay?id=1")
//       )
//     );
//   }





// }









// class ProcessingPayment extends StatefulWidget {
//   const ProcessingPayment({Key? key}) : super(key: key);

//   @override
//   State<ProcessingPayment> createState() => _ProcessingPaymentState();
// }

// class _ProcessingPaymentState extends State<ProcessingPayment> {


//   @override
//   void initState() {
//     // TODO: implement initState
//     super.initState();
//     print("press");
//     print("press");
//     print("press");
//     print("press");
//     DataProvider dataProvider = Provider.of<DataProvider>(context, listen: false);
//     processPaymentData(context).then((value){

//       processPayment(dataProvider, value);
//     });
//     // processPayment(dataProvider);

//   }
//   User? user = FirebaseAuth.instance.currentUser;

//   List ?data;
//   Future calculateScore(context) async {
//     var response =
//     await http.get(Uri.parse('${mainUrl}/calculate_score'), headers: {
//       'Content-Type': 'application/json; charset=UTF-8',
//         'Access-Control-Allow-Origin': '*',
//     }).timeout(Duration(seconds: 20));
//     var body = json.decode(response.body);
//     if(body.runtimeType.toString() == "_Map<String, dynamic>"){
//       Map body1 = body;
//       // setState(() {
//       //   data = body1;
//       // });
//       return body;
//     }else{

//       List body1 = body;
//       setState(() {
//         data = body1;
//       });
//       return body;
//     }
//     // if(body.runtimeType.toString() == )

//   }

//   final box = GetStorage();
//   Future processPaymentData(context) async {
//     final SharedPreferences prefs = await SharedPreferences.getInstance();

//     var week  = prefs.getString("week");
//     var tiebreaker =  prefs.getString("tiebreaker");
//     // var date = prefs.getString("date");
//     var picks = prefs.getStringList("picks");
//     var uid = prefs.getString("uid");
//     var displayName = prefs.getString("displayName");
//     var photoURL = prefs.getString("photoURL");

//    var body = {
//       "week": week,
//     "tiebreaker": tiebreaker,
//     // 'date': date,
//     'picks': picks,
//     'uid': uid,
//     "displayName": displayName,
//     "photoURL": photoURL
//     };
//    print(body);
//     print(body);
//     // var response =
//     // await http.get(Uri.parse('${mainUrl}/payment_update'), headers: {
//     //   'Content-Type': 'application/json; charset=UTF-8',
//     //   'Access-Control-Allow-Origin': '*',
//     // }).timeout(Duration(seconds: 20));
//     // print(response.body);
//     // print(response.body);
//     // print(response.body);
//     // var body = json.decode(response.body);
//      return body;
//     // if(body.runtimeType.toString() == )
//   }


//   processPayment(DataProvider dataProvider, data) async {
//     // final SharedPreferences prefs = await SharedPreferences.getInstance();
//     circularCustom(context);

//     final picksCreateData = {
//     "tiebreaker": data["tiebreaker"],
//       "week": data["week"],
//       "date": FieldValue.serverTimestamp(),
//     "picks": data["picks"],
//     "uid": data["uid"],
//     "displayName": data["displayName"],
//     "photoURL": data["photoURL"],
//     };
//     CollectionReference pickrecord = FirebaseFirestore.instance.collection('pickrecord');
//     await pickrecord.add(picksCreateData);
//     await calculateScore(context);
//     // ${mainUrl}/calculate_score
//     // await prefs.remove("week");
//     // await prefs.remove("tiebreaker");
//     // await prefs.remove("date");
//     // await prefs.remove("picks");
//     // await prefs.remove("uid");
//     // await prefs.remove("displayName");
//     // await prefs.remove("photoURL");
//     Navigator.pop(context);
//     // Navigator.pop(context);
//     // Navigator.pop(context);
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => LeaderboardWidget(),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return  Material(
//       child: Center(child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         crossAxisAlignment: CrossAxisAlignment.center,
//         children: [
//           Theme(
//               data: Theme.of(context).copyWith(
//                 colorScheme: ColorScheme.fromSwatch().copyWith(secondary: Color(0xFF063a73)),),
//               child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF063a73)),
//                 strokeWidth: 2,
//                 backgroundColor: Colors.white,
//                 //  valueColor: new AlwaysStoppedAnimation<Color>(color: Color(0xFF9B049B)),
//               )),
//           SizedBox(
//             height: 10,
//           ),
//           Text('Processing...',
//               style: TextStyle(
//                   color: Color(0xFF333333),
//                   fontSize: 18,
//                   fontWeight: FontWeight.w600)),
//         ],
//       )),
//     );();
//   }
// }
