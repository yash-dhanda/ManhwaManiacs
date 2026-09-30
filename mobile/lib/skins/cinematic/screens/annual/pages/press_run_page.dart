import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/annual/pages/page_frame.dart';
import 'package:manhwamaniacs/skins/cinematic/share/press_run.dart';
import 'package:manhwamaniacs/skins/cinematic/share/share_card_model.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// Page 11: the press run inline; the story ends here.
class AnnualPressRunPage extends StatelessWidget {
  const AnnualPressRunPage({super.key, required this.env});
  final AnnualEnv env;

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: CineColors.paper0,
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                      padding: const EdgeInsets.only(top: 48),
                      child: CineRoleText('PRESS RUN', context.cine.typeKicker,
                          color: CineColors.ink60,),),
                  Flexible(
                      child: PressRunBody(
                          input: ShareInput.annual(env.annual, env.profileName),
                          inline: true,
                          onReadNumbers: env.readNumbers,),),
                ],
              ),
            ),
          ),
        ),
      );
}
