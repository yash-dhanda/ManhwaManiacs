import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/stock.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

/// The profile's mood grade colour, or null for none (cinematic 2.1.6).
Color? cineMoodColor(String? mood) => switch (mood) {
      'romantic' => CineColors.moodRomantic,
      'action' => CineColors.moodAction,
      'comedy' => CineColors.moodComedy,
      'horror' => CineColors.moodHorror,
      'slice_of_life' => CineColors.moodSliceOfLife,
      'fantasy' => CineColors.moodFantasy,
      _ => null,
    };

/// A gradient over the top 30 % of the screen height from the grade colour to `#000`; the [child]
/// (the masthead) sits in `CineStock.raised` while a grade is present.
class CineMoodGrade extends StatelessWidget {
  const CineMoodGrade({super.key, required this.mood, required this.child});
  final String? mood;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final grade = cineMoodColor(mood);
    if (grade == null) return child;
    final h = MediaQuery.sizeOf(context).height * 0.3;
    return Stack(children: [
      Positioned(
        left: 0,
        right: 0,
        top: 0,
        height: h,
        child: IgnorePointer(
          child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [grade, const Color(0xFF000000)]))),
        ),
      ),
      CineStock.raised(child),
    ],);
  }
}
