

import 'package:flutter/material.dart';
import 'package:pollapp/Module/Screen/Home/landingPage.dart';
import 'package:pollapp/Module/Screen/Profile/UserProfile.dart';
import 'package:provider/provider.dart';

import '../../../Provider/AuthProvider.dart';
import 'LeaderbpardWidget.dart';

class HomePage extends StatefulWidget {
  final initial;
  HomePage({this.initial});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int pageIndex = 0;

  PageController ?controller;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    var authProvider = Provider.of<AuthProvider>(context, listen: false);
    controller = PageController(viewportFraction: 1, initialPage: widget.initial==null?0:
        widget.initial);
    pageIndex = widget.initial==null?0:widget.initial;
    authProvider.getUserInfo();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: controller,
        children: [
          HomePageWidget(),
          LeaderboardWidget(),
          UserProfile()
        ],
      ),
      bottomNavigationBar: buildMyNavBar(context),
    );
  }

  Container buildMyNavBar(BuildContext context) {
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
                pageIndex = 0;
              });
              controller!.jumpToPage(0);
            },
            icon: pageIndex == 0
                ? const Icon(
              Icons.home_filled,
              color: Colors.white,
              size: 35,
            )
                : const Icon(
              Icons.home_outlined,
              color: Colors.white,
              size: 35,
            ),
          ),

          IconButton(
            enableFeedback: false,
            onPressed: () {
              setState(() {
                pageIndex = 1;
              });
              controller!.jumpToPage(1);
            },
            icon: pageIndex == 1
                ? const Icon(
              Icons.widgets_rounded,
              color: Colors.white,
              size: 35,
            )
                : const Icon(
              Icons.widgets_outlined,
              color: Colors.white,
              size: 35,
            ),
          ),
          IconButton(
            enableFeedback: false,
            onPressed: () {
              setState(() {
                pageIndex = 2;
              });
              controller!.jumpToPage(2);
            },
            icon: pageIndex == 2
                ? const Icon(
              Icons.person,
              color: Colors.white,
              size: 35,
            )
                : const Icon(
              Icons.person_outline,
              color: Colors.white,
              size: 35,
            ),
          ),
        ],
      ),
    );
  }
}
