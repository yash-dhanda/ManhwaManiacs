import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/glass/shape.dart';
import 'package:manhwamaniacs/skins/glass/icons/icon_roles.g.dart' show GlassIconWeight;
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/magnet_targets.dart';
import 'package:manhwamaniacs/skins/glass/primitives/press.dart';
import 'package:manhwamaniacs/skins/glass/primitives/progress.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';

/// The twelve avatar presets (glass 7.26): two-colour gradient top-left to bottom-right and a Light glyph.
/// The colours come from `GlassTokens.colorAvatar<Preset>`.
enum GlassAvatarPreset {
  violetSpark('Violet Spark'),
  cyanRocket('Cyan Rocket'),
  roseHeart('Rose Heart'),
  amberCoffee('Amber Coffee'),
  emeraldCat('Emerald Cat'),
  emberFlame('Ember Flame'),
  steelBlade('Steel Blade'),
  phantom('Phantom'),
  arcaneWand('Arcane Wand'),
  lunarMoon('Lunar Moon'),
  starlight('Starlight'),
  bookworm('Bookworm');

  const GlassAvatarPreset(this.label);
  final String label;

  (Color, Color, Color) get colours => switch (this) {
        violetSpark => (gt.colorAvatarVioletSparkFrom, gt.colorAvatarVioletSparkTo, gt.colorAvatarVioletSparkGlyph),
        cyanRocket => (gt.colorAvatarCyanRocketFrom, gt.colorAvatarCyanRocketTo, gt.colorAvatarCyanRocketGlyph),
        roseHeart => (gt.colorAvatarRoseHeartFrom, gt.colorAvatarRoseHeartTo, gt.colorAvatarRoseHeartGlyph),
        amberCoffee => (gt.colorAvatarAmberCoffeeFrom, gt.colorAvatarAmberCoffeeTo, gt.colorAvatarAmberCoffeeGlyph),
        emeraldCat => (gt.colorAvatarEmeraldCatFrom, gt.colorAvatarEmeraldCatTo, gt.colorAvatarEmeraldCatGlyph),
        emberFlame => (gt.colorAvatarEmberFlameFrom, gt.colorAvatarEmberFlameTo, gt.colorAvatarEmberFlameGlyph),
        steelBlade => (gt.colorAvatarSteelBladeFrom, gt.colorAvatarSteelBladeTo, gt.colorAvatarSteelBladeGlyph),
        phantom => (gt.colorAvatarPhantomFrom, gt.colorAvatarPhantomTo, gt.colorAvatarPhantomGlyph),
        arcaneWand => (gt.colorAvatarArcaneWandFrom, gt.colorAvatarArcaneWandTo, gt.colorAvatarArcaneWandGlyph),
        lunarMoon => (gt.colorAvatarLunarMoonFrom, gt.colorAvatarLunarMoonTo, gt.colorAvatarLunarMoonGlyph),
        starlight => (gt.colorAvatarStarlightFrom, gt.colorAvatarStarlightTo, gt.colorAvatarStarlightGlyph),
        bookworm => (gt.colorAvatarBookwormFrom, gt.colorAvatarBookwormTo, gt.colorAvatarBookwormGlyph),
      };

  Glyph get glyph => switch (this) {
        violetSpark => GlassGlyph.sparkle,
        cyanRocket => GlassGlyph.rocketLaunch,
        roseHeart => GlassGlyph.heart,
        amberCoffee => GlassGlyph.coffee,
        emeraldCat => GlassGlyph.cat,
        emberFlame => GlassGlyph.flame,
        steelBlade => GlassGlyph.sword,
        phantom => GlassGlyph.ghost,
        arcaneWand => GlassGlyph.magicWand,
        lunarMoon => GlassGlyph.moon,
        starlight => GlassGlyph.star,
        bookworm => GlassGlyph.bookOpen,
      };
}

/// The orb sizes of glass 7.26.
const List<double> kProfileOrbSizes = [18, 20, 24, 32, 44, 56, 64, 72, 96, 112, 128, 132];

/// A profile orb (glass 7.26): the preset's gradient and Light glyph; a 2 px ring in the mood colour at 60 %;
/// on glass surfaces a glass bezel (0.5 px rim and a specular). [friend] swaps the mood ring for the
/// `bloom` ring; a friend orb can register as a [Magnet] drop target ([targetId]). [drift] is the picker's
/// idle drift: 3 px on a sine with a 5 to 7 s period, frozen under reduced motion.
class GlassProfileOrb extends ConsumerStatefulWidget {
  const GlassProfileOrb({
    super.key,
    required this.preset,
    this.size = 44,
    this.mood,
    this.name,
    this.onPressed,
    this.drift = false,
    this.friend = false,
    this.targetId,
    this.loading = false,
    this.selected = false,
    this.error = false,
    this.enabled = true,
    this.forceStates = GlassWidgetStates.none,
    this.phase,
  });

  final GlassAvatarPreset preset;
  final double size;
  final Color? mood;

  /// The full name, for the semantics label (names beside orbs truncate with an ellipsis).
  final String? name;
  final VoidCallback? onPressed;
  final bool drift;
  final bool friend;
  final Object? targetId;
  final bool loading;
  final bool selected;
  final bool error;
  final bool enabled;
  final GlassWidgetStates forceStates;

  /// For tests: the drift phase 0..1 (random by default).
  final double? phase;

  @override
  ConsumerState<GlassProfileOrb> createState() => _GlassProfileOrbState();
}

class _GlassProfileOrbState extends ConsumerState<GlassProfileOrb> with SingleTickerProviderStateMixin {
  late final AnimationController _drift = AnimationController(vsync: this, duration: Duration(milliseconds: 5000 + (widget.size * 7).toInt() % 2000));
  late final double _phase = widget.phase ?? math.Random().nextDouble();
  final GlobalKey _key = GlobalKey();
  GlassMagnetRegistry? _reg;

  @override
  void initState() {
    super.initState();
    _drift.value = 0;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final r = widget.targetId == null ? null : GlassMagnetScope.maybeOf(context);
    if (r != _reg) {
      if (widget.targetId != null) _reg?.unregister(widget.targetId!);
      _reg = r;
      if (widget.targetId != null) {
        r?.register(widget.targetId!, () {
          final ro = _key.currentContext?.findRenderObject();
          return ro is RenderBox && ro.attached ? ro.localToGlobal(ro.size.center(Offset.zero)) : null;
        });
      }
    }
  }

  @override
  void dispose() {
    if (widget.targetId != null) _reg?.unregister(widget.targetId!);
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = ref.watch(glassReducedProvider);
    final inHost = GlassHost.of(context);
    final s = widget.size;
    final (from, to, glyphColor) = widget.preset.colours;
    final states = widget.forceStates;
    final disabled = !widget.enabled || states.disabled;
    final loading = widget.loading || states.loading;
    final selected = widget.selected || states.selected;
    final err = widget.error || states.error;
    if (widget.drift && !reduced) {
      if (!_drift.isAnimating) _drift.repeat();
    } else {
      _drift.stop();
    }
    final ringColour = widget.friend ? gt.colorBloom.withValues(alpha: 0.6) : (widget.mood ?? gt.colorMoodDefault).withValues(alpha: 0.6);
    final ringW = selected ? 3.0 : (s >= 24 || widget.friend ? 2.0 : 0.0);
    final ringC = selected ? gt.colorIris300 : ringColour;

    Widget orb(bool hovered) => SizedBox(
          key: _key,
          width: s,
          height: s,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: s,
                height: s,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [from, to]),
                  border: ringW > 0 ? Border.all(color: ringC, width: ringW) : null,
                ),
              ),
              if (inHost) Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: _BezelPainter()))),
              if (loading)
                GlassSpinner(size: s >= 32 ? 24 : 16, color: glyphColor)
              else
                Icon(widget.preset.glyph.light, size: s * 0.5, color: glyphColor),
              if (err) Positioned(right: 0, bottom: 0, child: GlyphIcon(GlassGlyph.warningCircle, size: math.max(12, s * 0.3), color: gt.colorDanger, weight: GlassIconWeight.fill)),
            ],
          ),
        );

    Widget body = AnimatedBuilder(
      animation: _drift,
      builder: (context, _) {
        final dy = widget.drift && !reduced ? 3 * math.sin(2 * math.pi * (_drift.value + _phase)) : 0.0;
        return Transform.translate(offset: Offset(0, dy), child: orb(false));
      },
    );

    if (widget.onPressed != null || states.pressed || states.hovered) {
      body = GlassPressable(
        material: GlassMaterial.glass,
        growth: GlassGrowth.medium,
        shape: const GlassShape.circle(),
        onTap: disabled ? null : widget.onPressed,
        enabled: !disabled,
        forceStates: states,
        haptic: HapticEvent.profileSelect,
        semanticsLabel: widget.name ?? widget.preset.label,
        hoverGlow: false,
        focusScale: 1,
        builder: (context, info) => Transform.scale(
          scale: info.states.hovered && !reduced ? (s >= 96 && widget.drift ? 1.08 : 1.04) : 1,
          child: body,
        ),
      );
    } else {
      body = Semantics(label: widget.name ?? widget.preset.label, image: true, child: ExcludeSemantics(child: body));
    }
    return Opacity(opacity: disabled ? 0.4 : 1, child: body);
  }
}

class _BezelPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = size.shortestSide / 2;
    final c = size.center(Offset.zero);
    canvas.drawCircle(c, r - 0.25, Paint()..style = PaintingStyle.stroke..strokeWidth = 0.5..color = const Color(0x38FFFFFF));
    canvas.drawCircle(
      c,
      r,
      Paint()..shader = const RadialGradient(center: Alignment(-0.5, -0.6), radius: 0.9, colors: [Color(0x40FFFFFF), Color(0x00FFFFFF)]).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(_BezelPainter old) => false;
}

/// A friend badge: an 18 px friend orb with a `bloom` ring (glass 7.20).
class GlassFriendBadge extends StatelessWidget {
  const GlassFriendBadge(this.preset, {super.key, this.name});
  final GlassAvatarPreset preset;
  final String? name;

  @override
  Widget build(BuildContext context) => GlassProfileOrb(preset: preset, size: 18, friend: true, name: name);
}
