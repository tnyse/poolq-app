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

class TeamLogo extends StatelessWidget {
  final String abbr;
  final double size;
  const TeamLogo({required this.abbr, this.size = 40, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Clean up abbreviation: trim, remove spaces, uppercase
    final cleanAbbr = abbr.toUpperCase().replaceAll(' ', '').trim();
    final assetPath = 'assets/images/teams/$cleanAbbr.png';

    return Image.asset(
      assetPath,
      width: size,
      height: size,
      errorBuilder: (context, error, stackTrace) {
        return Icon(Icons.sports_football, size: size);
      },
      fit: BoxFit.contain,
    );
  }
}

/// Wrap/grid of picked teams with logos (review + admin pick views).
class PicksLogoGrid extends StatelessWidget {
  final List<String> picks;
  final double logoSize;

  const PicksLogoGrid({
    Key? key,
    required this.picks,
    this.logoSize = 40,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (picks.isEmpty) {
      return const Text('No picks');
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.start,
      children: [
        for (final raw in picks)
          _PickChip(abbr: raw.toString(), logoSize: logoSize),
      ],
    );
  }
}

class _PickChip extends StatelessWidget {
  final String abbr;
  final double logoSize;

  const _PickChip({required this.abbr, required this.logoSize});

  @override
  Widget build(BuildContext context) {
    final label = abbr.toUpperCase().replaceAll(' ', '').trim();
    return Container(
      width: 72,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TeamLogo(abbr: label, size: logoSize),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF424242),
            ),
          ),
        ],
      ),
    );
  }
}
