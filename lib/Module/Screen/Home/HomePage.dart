import 'LeaderbpardWidget.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../Provider/homeProvider.dart';
import '../../../Provider/AuthProviders.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:poolqapp/Module/Screen/Home/landingPage.dart';
import 'package:poolqapp/Module/Screen/Profile/UserProfile.dart';
import 'package:flutter_phosphor_icons/flutter_phosphor_icons.dart';

// import 'package:phosphor_flutter/phosphor_flutter.dart';

class HomePage extends StatefulWidget {
  final initial;
  HomePage({this.initial});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  PageController? controller;
  User? user = FirebaseAuth.instance.currentUser;
  Stream<QuerySnapshot>? _pickrecord;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    var authProvider = Provider.of<AuthProviders>(context, listen: false);
    DataProvider dataProvider =
        Provider.of<DataProvider>(context, listen: false);
    controller = PageController(
        viewportFraction: 1,
        initialPage: widget.initial == null ? 0 : widget.initial);
    dataProvider.pageIndex = widget.initial == null ? 0 : widget.initial;
    _pickrecord = FirebaseFirestore.instance
        .collection('pickrecord')
        .where("uid", isEqualTo: user!.uid)
        .where("week", isEqualTo: dataProvider.game!["name"])
        .snapshots();
    authProvider.getUserInfo();
  }

  @override
  Widget build(BuildContext context) {
    DataProvider dataProvider =
        Provider.of<DataProvider>(context, listen: true);
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
          stream: _pickrecord,
          builder:
              (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
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

            return PageView(
              controller: controller,
              children: [
                HomePageWidget(
                    controller: controller,
                    isEmpty: snapshot.data!.docs.isEmpty),
                LeaderboardWidget(),
                UserProfile()
              ],
            );
          }),
      bottomNavigationBar: buildMyNavBar(context, dataProvider),
    );
  }

  Container buildMyNavBar(BuildContext context, DataProvider dataProvider) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Color(0xFF063A73),
        borderRadius: const BorderRadius.only(
            // topLeft: Radius.circular(20),
            // topRight: Radius.circular(20),
            ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            enableFeedback: false,
            onPressed: () {
              setState(() {
                dataProvider.setValue(0);
                // print(pageIndex);
              });
              controller!.jumpToPage(0);
            },
            icon: dataProvider.pageIndex != 0
                ? Icon(
                    PhosphorIcons.house,
                    color: Colors.white,
                    size: 40,
                  )
                : Icon(
                    PhosphorIcons.house,
                    color: Colors.white,
                    size: 40,
                  ),
          ),
          InkWell(
            // enableFeedback: false,
            onTap: () {
              setState(() {
                dataProvider.setValue(1);
              });
              controller!.jumpToPage(1);
            },
            child: dataProvider.pageIndex == 1
                ? Image.asset(
                    "assets/images/lb-full.png",
                    width: 45,
                    height: 45,
                  )
                : Image.asset(
                    "assets/images/lb-outline.png",
                    width: 45,
                    height: 45,
                    // color: Colors.white,
                  ),
          ),
          IconButton(
            enableFeedback: false,
            onPressed: () {
              setState(() {
                dataProvider.setValue(2);
              });
              controller!.jumpToPage(2);
            },
            icon: dataProvider.pageIndex == 2
                ? Icon(
                    PhosphorIcons.user,
                    color: Colors.white,
                    size: 40,
                  )
                : Icon(
                    PhosphorIcons.user,
                    color: Colors.white70,
                    size: 40,
                  ),
          ),
        ],
      ),
    );
  }
}
