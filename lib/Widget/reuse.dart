import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

customSnackbar(context, String text){

  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(text),
  ));
}


// convertDate(date){
//   String dateString = "SUNDAY, SEPTEMBER 11TH";
//   DateFormat dateFormat = DateFormat("EEEE, MMMM d 'TH'");
//   DateTime dateTime = dateFormat.parseLoose(dateString);
//
//   print(dateTime);  // Output: 2023-09-11 00:00:00.000
//   return dateTime;
// }
//
//

String getDaySuffix(int day) {
  if (day >= 11 && day <= 13) {
    return 'th';
  }

  switch (day % 10) {
    case 1:
      return 'st';
    case 2:
      return 'nd';
    case 3:
      return 'rd';
    default:
      return 'th';
  }
}

formateDate(String inputDate){
  DateTime dateTime = DateTime.parse(inputDate);
  DateFormat outputFormat = DateFormat('EEEE, MMMM d' "'${getDaySuffix(dateTime.day)}'");
  String formattedDate = outputFormat.format(dateTime);
  return formattedDate.toUpperCase();
}

bool shouldPop = true;

circularCustom(context)async{
  return showDialog(
      barrierDismissible: true,
      context: context,
      builder: (context) {
        return WillPopScope (
          onWillPop: () async {
            return shouldPop;
          },
          child: Dialog(
            elevation: 0,
            child:  CupertinoActivityIndicator(
              radius: 30,
              color: Colors.white70,
            ),
            backgroundColor: Colors.transparent,
          ),
        );
      });
}
