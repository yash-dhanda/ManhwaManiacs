import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/contents_list.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// The left `Contents` column panel on tablets (cinematic 8.14.12): a kicker header with a quiet
/// close, then the [ContentsList].
class ContentsPanel extends StatelessWidget {
  const ContentsPanel({super.key, required this.list, required this.onClose});

  final ContentsList list;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final top = MediaQuery.viewPaddingOf(context).top;
    return Padding(
      padding: EdgeInsets.only(top: top),
      child: Column(
        children: [
          SizedBox(
            height: 56,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: c.space4),
              child: Row(
                children: [
                  Expanded(child: CineRoleText('CONTENTS', c.typeKicker, color: c.colorInk60)),
                  CineButton(label: 'Close', variant: CineButtonVariant.quiet, size: CineButtonSize.sm, onPressed: onClose),
                ],
              ),
            ),
          ),
          SizedBox(height: 1, child: ColoredBox(color: c.colorRule1)),
          Expanded(child: list),
        ],
      ),
    );
  }
}
