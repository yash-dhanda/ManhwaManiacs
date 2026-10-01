import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/features/circle/models/circle_models.dart';
import 'package:manhwamaniacs/skins/glass/primitives/profile_orb.dart';
import 'package:manhwamaniacs/skins/glass/screens/profiles/avatar_map.dart';

/// Who added a poster to a shared shelf, or who owns it (glass 9.3.3): a 20 px orb (24 for an owner) on a 24 px (28)
/// `rgba(0,0,0,0.72)` disc at the bottom-left. Decoration: the poster's own semantics names it.
class AdderOrb extends StatelessWidget {
  const AdderOrb({super.key, required this.member, this.size = 20, this.verb = 'Added by'});
  final ProfileRef member;
  final double size;
  final String verb;

  @override
  Widget build(BuildContext context) => Semantics(
        label: '$verb ${member.name}',
        excludeSemantics: true,
        child: Container(
          width: size + 4,
          height: size + 4,
          alignment: Alignment.center,
          decoration: const BoxDecoration(color: Color(0xB8000000), shape: BoxShape.circle),
          child: GlassProfileOrb(preset: glassPresetFor(member.avatarKey), size: size, friend: true, name: member.name),
        ),
      );
}
