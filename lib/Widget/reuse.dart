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

/// Hard fixed-width pick chip. Width never changes for 2/3-letter abbrs or selection.
class TeamPickAbbrButton extends StatelessWidget {
  final String abbr;
  final bool selected;
  final VoidCallback onPressed;

  static const double chipWidth = 96;
  static const double chipHeight = 36;
  static const double _letterSlot = 12;
  static const double _checkSlot = 20;

  const TeamPickAbbrButton({
    Key? key,
    required this.abbr,
    required this.selected,
    required this.onPressed,
    bool checkOnLeading = false, // ignored — layout identical for both sides
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cleaned = abbr.toUpperCase().replaceAll(' ', '').trim();
    final letters = <String>[
      for (var i = 0; i < cleaned.length && i < 3; i++) cleaned[i],
    ];

    return Center(
      child: SizedBox(
      width: chipWidth,
      height: chipHeight,
      child: Material(
        color: selected
            ? const Color(0xFF063a73).withOpacity(0.95)
            : Colors.white.withOpacity(0.22),
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: Colors.white.withOpacity(0.25),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            width: chipWidth,
            height: chipHeight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                // Exactly 3 letter cells — empty cells still take space.
                SizedBox(
                  width: _letterSlot * 3,
                  height: chipHeight,
                  child: Row(
                    children: List.generate(3, (i) {
                      final ch = i < letters.length ? letters[i] : '';
                      return SizedBox(
                        width: _letterSlot,
                        child: Center(
                          child: Text(
                            ch,
                            style: const TextStyle(
                              fontFamily: 'Lexend Deca',
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              height: 1,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                // Check slot always present (invisible placeholder when unselected).
                SizedBox(
                  width: _checkSlot,
                  height: chipHeight,
                  child: Center(
                    child: selected
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : const SizedBox(width: 16, height: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
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
