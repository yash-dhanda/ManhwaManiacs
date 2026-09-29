import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/app/switch_skin.dart';
import 'package:manhwamaniacs/skins/skins.dart';

const _dim = Color(0xA3FFFFFF);

/// The one skin-neutral screen for every unbuilt ScreenId of both new skins.
/// System font on purpose; no animation, haptic or sound.
class PendingScreen extends ConsumerWidget {
  const PendingScreen({super.key, required this.screenId, required this.location});

  final String screenId;
  final String location;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skin = ref.watch(skinIdProvider);
    final minHeight = defaultTargetPlatform == TargetPlatform.iOS ? 44.0 : 48.0;
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${skin.name.toUpperCase()} · NOT BUILT YET',
                      style: const TextStyle(
                        fontSize: 12,
                        height: 16 / 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.92,
                        color: _dim,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      screenId,
                      style: const TextStyle(
                        fontSize: 28,
                        height: 34 / 28,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFF5F5F5),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "This screen hasn't been built in this edition yet. It arrives in a later step of the redesign.",
                      style: TextStyle(fontSize: 16, height: 24 / 16, color: _dim),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      location,
                      style: const TextStyle(
                        fontFamily: 'Menlo',
                        fontFamilyFallback: ['monospace', 'Courier'],
                        fontSize: 13,
                        height: 16 / 13,
                        color: _dim,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Semantics(
                      button: true,
                      label: 'Leave the preview',
                      excludeSemantics: true,
                      child: OutlinedButton(
                        onPressed: () => leavePreview(context, ref),
                        style: ButtonStyle(
                          minimumSize: WidgetStatePropertyAll(Size(0, minHeight)),
                          padding: const WidgetStatePropertyAll(
                            EdgeInsets.symmetric(horizontal: 20),
                          ),
                          shape: WidgetStateProperty.resolveWith(
                            (s) => s.contains(WidgetState.focused)
                                ? const _FocusRingBorder()
                                : const RoundedRectangleBorder(),
                          ),
                          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
                          foregroundColor: const WidgetStatePropertyAll(Color(0xFFF5F5F5)),
                          textStyle: const WidgetStatePropertyAll(
                            TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                          side: WidgetStateProperty.resolveWith(
                            (s) => BorderSide(
                              color: s.contains(WidgetState.pressed)
                                  ? const Color(0xCCFFFFFF)
                                  : const Color(0x66FFFFFF),
                            ),
                          ),
                        ),
                        child: const Text('Leave the preview'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Square border that also paints a 2 px white outline 2 px outside it, used
/// only while the button has keyboard focus.
class _FocusRingBorder extends OutlinedBorder {
  const _FocusRingBorder({super.side = BorderSide.none});

  @override
  OutlinedBorder copyWith({BorderSide? side}) => _FocusRingBorder(side: side ?? this.side);
  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;
  @override
  ShapeBorder scale(double t) => this;
  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => Path()..addRect(rect);
  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) => Path()..addRect(rect);
  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style != BorderStyle.none) {
      canvas.drawRect(
        rect.deflate(side.width / 2),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = side.width
          ..color = side.color,
      );
    }
    canvas.drawRect(
      rect.inflate(3),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFFFFFFFF),
    );
  }
}
