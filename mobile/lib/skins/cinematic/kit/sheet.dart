import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/kit/buttons.dart';
import 'package:manhwamaniacs/skins/cinematic/kit/cine_text.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

/// A `[0.92]` detent sheet (§7.9): `paper.2`, grabber 32 x 3 `ink.30`, a 56 px
/// header with a kicker and a quiet `Done`. Max 720 wide, centred.
///
/// TODO(mobile/05): `CineSheetRoute` owns this; call it instead.
Future<T?> showCineSheet<T>(BuildContext context, {required String kicker, required WidgetBuilder builder, double detent = 0.92}) => showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      barrierColor: CineScrim.modal,
      constraints: const BoxConstraints(maxWidth: 720),
      builder: (context) => FractionallySizedBox(
        heightFactor: detent,
        child: Container(
          color: CineColors.paper2,
          child: SafeArea(
            top: false,
            child: Column(children: [
              const SizedBox(height: 8),
              ExcludeSemantics(child: Container(width: 32, height: 3, color: CineColors.ink30)),
              SizedBox(
                height: 56,
                child: Padding(
                  padding: const EdgeInsets.only(left: 20, right: 8),
                  child: Row(children: [
                    Expanded(child: Semantics(header: true, child: CineText(kicker, context.cine.typeKicker, color: CineColors.ink60))),
                    CineButton('Done', kind: CineButtonKind.quiet, onPressed: () => Navigator.of(context).pop()),
                  ],),
                ),
              ),
              Expanded(child: builder(context)),
            ],),
          ),
        ),
      ),
    );
