import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart' show Material, MaterialType;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/keyboard/shortcut_registry.dart';
import 'package:manhwamaniacs/features/profiles/models/mood.dart';
import 'package:manhwamaniacs/features/profiles/models/profile.dart';
import 'package:manhwamaniacs/features/profiles/models/profile_extras.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/features/profiles/utils/daily_goal_options.dart';
import 'package:manhwamaniacs/features/settings/utils/mature_gate_effects.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/copy/errors.dart';
import 'package:manhwamaniacs/skins/glass/glass/ambient_field.dart' show moodColour;
import 'package:manhwamaniacs/skins/glass/motion.dart';
import 'package:manhwamaniacs/skins/glass/motion_names.g.dart';
import 'package:manhwamaniacs/skins/glass/primitives/chip.dart';
import 'package:manhwamaniacs/skins/glass/primitives/chip_row.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/gate/mature_gate_switch.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/list/grouped_list.dart';
import 'package:manhwamaniacs/skins/glass/primitives/list/list_row.dart';
import 'package:manhwamaniacs/skins/glass/primitives/menu.dart';
import 'package:manhwamaniacs/skins/glass/primitives/profile_orb.dart';
import 'package:manhwamaniacs/skins/glass/primitives/skeleton.dart';
import 'package:manhwamaniacs/skins/glass/primitives/text_field.dart';
import 'package:manhwamaniacs/skins/glass/screens/auth/overlay_run.dart';
import 'package:manhwamaniacs/skins/glass/screens/profiles/avatar_arc.dart';
import 'package:manhwamaniacs/skins/glass/screens/profiles/avatar_map.dart';
import 'package:manhwamaniacs/skins/glass/screens/profiles/delete_profile_alert.dart';
import 'package:manhwamaniacs/skins/glass/screens/profiles/profile_form_field.dart';
import 'package:manhwamaniacs/skins/glass/shell/purge.dart' show glassPurgeProbeProvider;
import 'package:manhwamaniacs/skins/glass/shell/shell_providers.dart' show glassOfflineProvider;
import 'package:manhwamaniacs/skins/glass/shell/skin_switch_flow.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';
import 'package:manhwamaniacs/skins/glass/splash/glass_mark.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';
import 'package:manhwamaniacs/skins/skins.dart';

/// The picker's orb for a saved profile hops once (glass 8.6); the form writes the id, the picker reads and clears it.
final glassProfileHopProvider = StateProvider<int?>((ref) => null, name: 'glassProfileHop');

/// Whether the Skin row shows: Glass is available, or this device previews it (glass 8.6).
bool glassSkinRowShown(WidgetRef ref) => Flags.glassAvailable;

/// The body of the profile form (glass 8.6, mobile S06 and S07): a live orb, the name, the avatar grid with its arc, the mood chips
/// that retint the sheet's field, the daily goal, the Skin row, the 18+ flow and the save. [profileId] is null for a new profile.
class GlassProfileForm extends ConsumerStatefulWidget {
  const GlassProfileForm({super.key, this.profileId, required this.onClose, this.embedded = false});
  final int? profileId;

  /// Inside another scroll view (the full-page form): no scroll view of its own.
  final bool embedded;

  /// Dismisses the sheet or page.
  final VoidCallback onClose;

  @override
  ConsumerState<GlassProfileForm> createState() => _GlassProfileFormState();
}

class _GlassProfileFormState extends ConsumerState<GlassProfileForm> with TickerProviderStateMixin {
  final _name = TextEditingController();
  final _nameNode = FocusNode(debugLabel: 'profile-name');
  final GlobalKey _previewKey = GlobalKey();
  final GlobalKey _skinKey = GlobalKey();
  final Map<int, GlobalKey> _avatarKeys = {};
  late final AnimationController _pop = AnimationController(vsync: this, value: 1);
  Profile? _existing;
  bool _initialised = false;
  int _avatar = 0;
  Mood _mood = Mood.neutral;
  int? _goal;
  String _skin = 'glass';
  bool _mature = false;
  bool _saving = false;
  String? _line;
  String? _nameError;
  int _nameTrigger = 0;
  bool _limit = false;
  Profile? _createdNeedsExtras;

  bool get _isNew => widget.profileId == null;

  @override
  void initState() {
    super.initState();
    _pop.value = 1; // created now, not lazily inside dispose
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    _nameNode.dispose();
    _pop.dispose();
    super.dispose();
  }

  void _seed(Profile? p) {
    if (_initialised) return;
    _initialised = true;
    _existing = p;
    if (p != null) {
      _name.text = p.name;
      _avatar = glassPresetFor(p.avatarKey).index;
      _mood = p.mood;
      _goal = p.dailyGoalMinutes;
      _skin = p.skin ?? kDefaultSkin.name;
      _mature = p.matureContentEnabled;
    } else {
      _skin = ref.read(skinIdProvider).name;
    }
  }

  String get _trimmed => _name.text.trim();
  bool get _canSave => _trimmed.isNotEmpty && !_saving;
  GlassAvatarPreset get _preset => GlassAvatarPreset.values[_avatar];

  void _pickAvatar(int i, {Rect? from}) {
    if (i == _avatar) return;
    setState(() => _avatar = i);
    glassFire(ref, HapticEvent.select);
    final reduced = glassReduced(ref);
    final target = globalRectOfKey(_previewKey);
    if (reduced || from == null || target == null) {
      unawaited(_popPreview());
      return;
    }
    final arc = AvatarArc.solve(from: from.center, to: target.center);
    unawaited(
      playRootOverlay(
        context,
        (done) => _ArcFlight(arc: arc, preset: GlassAvatarPreset.values[i], size: from.width, mood: moodColour(_mood), onLand: () => unawaited(_popPreview()), done: done),
      ),
    );
  }

  Future<void> _popPreview() async {
    _pop.value = 0.86;
    await GlassMotion.play(MotionName.avatarArc, controller: _pop, target: 1);
  }

  Future<void> _save() async {
    if (!_canSave) return;
    final offline = ref.read(glassOfflineProvider);
    if (offline) return;
    setState(() {
      _saving = true;
      _line = null;
      _nameError = null;
      _limit = false;
    });
    final notifier = ref.read(profilesProvider.notifier);
    final key = avatarKeyFor(_preset);
    AppError? err;
    final existing = _existing;
    var extrasOnly = false;
    if (_createdNeedsExtras != null) {
      extrasOnly = true;
    }
    if (existing == null && !extrasOnly) {
      final out = await notifier.createWithExtras(
        name: _trimmed,
        avatarKey: key,
        mood: _mood,
        matureContentEnabled: _mature,
        extras: ProfileExtras(skin: _skin, dailyGoal: _goal == null ? null : (minutes: _goal)),
      );
      if (!mounted) return;
      err = out.error;
      if (err == null && out.extrasFailed) {
        // The profile exists: the sheet stays open as its edit form, "Save changes" retries only the PATCH.
        setState(() {
          _saving = false;
          _createdNeedsExtras = out.created;
          _existing = out.created;
          _line = "Couldn't save the skin and daily goal. Try again.";
        });
        return;
      }
      if (err == null) ref.read(glassProfileHopProvider.notifier).state = out.created?.id;
    } else {
      final target = existing ?? _createdNeedsExtras!;
      final active = ref.read(activeProfileProvider);
      final isActive = active?.id == target.id;
      final skinChanged = _skin != (target.skin ?? kDefaultSkin.name);
      final goalChanged = _goal != target.dailyGoalMinutes;
      final extras = ProfileExtras(skin: skinChanged && !isActive ? _skin : null, dailyGoal: goalChanged || extrasOnly ? (minutes: _goal) : null);
      err = await notifier.edit(
        target.id,
        name: extrasOnly ? null : _trimmed,
        avatarKey: extrasOnly ? null : key,
        mood: extrasOnly ? null : _mood,
        matureContentEnabled: extrasOnly ? null : _mature,
        extras: extras.isEmpty ? null : extras,
      );
      if (!mounted) return;
      if (err == null) {
        if (isActive && target.matureContentEnabled != _mature) {
          applyMatureGateChanged(ref);
          // mobile/29 has no gate watcher: closing the ACTIVE profile's gate runs the 18+ purge from here (glass 8.0.8).
          if (!_mature) ref.read(glassPurgeProbeProvider)();
        }
        ref.read(glassProfileHopProvider.notifier).state = target.id;
        if (isActive && skinChanged) {
          setState(() => _saving = false);
          final rect = globalRectOfKey(_skinKey) ?? Rect.zero;
          await startSkinSwitch(context, ref, sourceRect: rect);
          if (!mounted) return;
          // "Stay in Glass": the saved fields stay, the thumb springs back and the skin is unchanged.
          setState(() => _skin = target.skin ?? kDefaultSkin.name);
          return;
        }
      }
    }
    if (!mounted) return;
    if (err != null) {
      final e = errorEntry(err);
      glassFire(ref, HapticEvent.error);
      setState(() {
        _saving = false;
        if (err is ApiError && err.code == 'profile_limit_reached') {
          _limit = true;
          _line = e.copy;
        } else if (err is ApiError && err.code == 'invalid_profile_name') {
          _nameError = e.copy;
          _nameTrigger++;
          _nameNode.requestFocus();
        } else {
          _line = e.copy;
        }
      });
      return;
    }
    widget.onClose();
  }

  Future<void> _delete() async {
    final p = _existing;
    if (p == null) return;
    final rect = globalRectOfKey(_deleteKey);
    final ok = await showDeleteProfileAlert(context, ref, profile: p, sourceRect: rect);
    if (ok && mounted) widget.onClose();
  }

  final GlobalKey _deleteKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final profiles = ref.watch(profilesProvider);
    final offline = ref.watch(glassOfflineProvider);
    Profile? existing;
    if (!_isNew) {
      final list = profiles.valueOrNull;
      if (list == null) {
        if (profiles.hasError) return _notFound();
        return _loading();
      }
      existing = list.where((p) => p.id == widget.profileId).firstOrNull;
      if (existing == null && !_initialised) return _notFound();
    }
    _seed(existing);
    return _content(offline);
  }

  Widget _notFound() => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GlassText('This profile may have been removed.', role: gt.typeCallout, onGlass: true, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            GlassButton(label: 'Back', onPressed: widget.onClose),
          ],
        ),
      );

  Widget _loading() => GlassSkeletonGroup(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Column(
            children: [
              const GlassSkeleton(width: 96, height: 96, circle: true),
              const SizedBox(height: 16),
              for (var i = 0; i < 4; i++) Padding(padding: const EdgeInsets.only(bottom: 12), child: GlassSkeleton(height: 50, index: i)),
            ],
          ),
        ),
      );

  Widget _content(bool offline) {
    final width = MediaQuery.sizeOf(context).width;
    final cols = width < 360 ? 4 : 6;
    final skinShown = glassSkinRowShown(ref);
    final label = _isNew && _createdNeedsExtras == null ? 'Create profile' : 'Save changes';
    final reason = offline ? 'Profiles need a connection to save' : null;
    final nameLen = _name.text.characters.length;
    final showCounter = nameLen >= 24;
    final column = Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: AnimatedBuilder(
              animation: _pop,
              builder: (context, child) => Transform.scale(scale: _pop.value.clamp(0.0, 1.2), child: child),
              child: SizedBox(
                key: _previewKey,
                width: 96,
                height: 96,
                child: AnimatedSwitcher(
                  duration: gt.curveColorShift.duration,
                  child: GlassProfileOrb(key: ValueKey('${_avatar}_${_mood.name}'), preset: _preset, size: 96, mood: moodColour(_mood), name: _trimmed.isEmpty ? _preset.label : _trimmed),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          GlassTextField(
            controller: _name,
            focusNode: _nameNode,
            label: 'Name',
            hint: 'e.g. Late-night reads',
            autofocus: _isNew,
            onSheet: true,
            textCapitalization: TextCapitalization.words,
            inputFormatters: [LengthLimitingTextInputFormatter(30)],
            counter: showCounter ? '$nameLen/30' : null,
            error: _nameError,
            errorTrigger: _nameTrigger,
            enabled: !_saving,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => FocusScope.of(context).nextFocus(),
          ),
          const SizedBox(height: 20),
          _label('Avatar'),
          const SizedBox(height: 8),
          Semantics(
            container: true,
            label: 'Avatar',
            child: FocusTraversalGroup(
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < GlassAvatarPreset.values.length; i++)
                    SizedBox(
                      width: math.min(56.0, (width - 32 - 8 * (cols - 1)) / cols),
                      child: _AvatarChoice(
                        key: _avatarKeys.putIfAbsent(i, GlobalKey.new),
                        preset: GlassAvatarPreset.values[i],
                        selected: i == _avatar,
                        mood: moodColour(_mood),
                        onPick: (rect) => _pickAvatar(i, from: rect),
                        onArrow: (delta) {
                          final n = (_avatar + delta) % GlassAvatarPreset.values.length;
                          _pickAvatar(n < 0 ? n + GlassAvatarPreset.values.length : n);
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _label('Mood'),
          const SizedBox(height: 8),
          Semantics(
            container: true,
            label: 'Mood',
            child: GlassChipRow(
              padding: EdgeInsets.zero,
              children: [GlassChoiceChips<Mood>(
                options: Mood.values,
                selected: _mood,
                onSelected: (m) {
                  setState(() => _mood = m);
                  glassFire(ref, HapticEvent.select);
                },
                labelOf: (m) => m.label,
                dotOf: moodColour,
              ),],
            ),
          ),
          const SizedBox(height: 20),
          GlassGroupedList(
            inset: false,
            children: [
              GlassMenu(
                title: 'Daily goal',
                entries: [
                  for (final m in kDailyGoalOptions)
                    GlassMenuEntry(label: dailyGoalLabel(m), checked: m == _goal, onSelected: () => setState(() => _goal = m)),
                ],
                builder: (context, menu) => GlassListRow(title: 'Daily goal', value: dailyGoalLabel(_goal), caret: true, onTap: menu.open),
              ),
              GlassMatureGate(mode: MatureGateMode.form, value: _mature, onChanged: (v) => setState(() => _mature = v)),
            ],
          ),
          if (skinShown) ...[
            const SizedBox(height: 20),
            _label('Skin'),
            const SizedBox(height: 8),
            KeyedSubtree(key: _skinKey, child: _SkinChoice(value: _skin, onChanged: (v) => setState(() => _skin = v))),
          ],
          if (_line != null) ...[
            const SizedBox(height: 16),
            Semantics(liveRegion: true, child: GlassFieldMessage(text: _line, error: true)),
            if (_limit) Align(alignment: Alignment.centerLeft, child: GlassButton(label: 'Manage profiles', variant: GlassButtonVariant.plain, onPressed: () {
              widget.onClose();
              context.go(Routes.profilesManage());
            },),),
          ],
          const SizedBox(height: 24),
          GlassButton(
            label: label,
            variant: GlassButtonVariant.primary,
            size: GlassButtonSize.large,
            fullWidth: true,
            loading: _saving,
            twin: GlassTwin.tinted,
            onPressed: _canSave && !offline ? () => unawaited(_save()) : null,
            disabledReason: reason,
          ),
          if (reason != null) ...[
            const SizedBox(height: 8),
            Center(child: GlassText(reason, role: gt.typeFootnote, onGlass: true, color: gt.colorLabel2, textAlign: TextAlign.center)),
          ],
          if (_existing != null) ...[
            const SizedBox(height: 16),
            KeyedSubtree(
              key: _deleteKey,
              child: GlassButton(label: 'Delete profile', variant: GlassButtonVariant.destructive, fullWidth: true, onPressed: () => unawaited(_delete())),
            ),
          ],
        ],
      ),
    );
    final body = widget.embedded ? column : SingleChildScrollView(keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag, child: column);
    return Material(
      type: MaterialType.transparency,
      child: RegisteredShortcuts(
      group: 'Profile form',
      entries: [
        ShortcutEntry(group: 'Profile form', activator: const SingleActivator(LogicalKeyboardKey.enter), description: 'Save the profile', keys: const ['Enter'], onInvoke: () => unawaited(_save())),
        ShortcutEntry(group: 'Profile form', activator: const SingleActivator(LogicalKeyboardKey.escape), description: 'Close the form', keys: const ['Esc'], onInvoke: widget.onClose),
      ],
      child: ProfileFormField(mood: _mood, child: body),
    ),
    );
  }

  Widget _label(String t) => Semantics(header: true, headingLevel: 2, child: GlassText(t, role: gt.typeFootnote, wght: 600, onGlass: true, color: gt.colorOnGlass));
}

/// One avatar radio: a 56 px orb, `Semantics(inMutuallyExclusiveGroup, checked)`, arrows move the selection.
class _AvatarChoice extends StatefulWidget {
  const _AvatarChoice({super.key, required this.preset, required this.selected, required this.mood, required this.onPick, required this.onArrow});
  final GlassAvatarPreset preset;
  final bool selected;
  final Color mood;
  final ValueChanged<Rect?> onPick;
  final ValueChanged<int> onArrow;

  @override
  State<_AvatarChoice> createState() => _AvatarChoiceState();
}

class _AvatarChoiceState extends State<_AvatarChoice> {
  final GlobalKey _orb = GlobalKey();

  void _tap() => widget.onPick(globalRectOfKey(_orb));

  @override
  Widget build(BuildContext context) => Semantics(
        inMutuallyExclusiveGroup: true,
        checked: widget.selected,
        button: true,
        label: widget.preset.label,
        excludeSemantics: true,
        onTap: _tap,
        child: Focus(
          onKeyEvent: (n, e) {
            if (e is! KeyDownEvent) return KeyEventResult.ignored;
            final k = e.logicalKey;
            if (k == LogicalKeyboardKey.arrowRight || k == LogicalKeyboardKey.arrowDown) {
              widget.onArrow(1);
              return KeyEventResult.handled;
            }
            if (k == LogicalKeyboardKey.arrowLeft || k == LogicalKeyboardKey.arrowUp) {
              widget.onArrow(-1);
              return KeyEventResult.handled;
            }
            if (k == LogicalKeyboardKey.enter || k == LogicalKeyboardKey.space) {
              _tap();
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _tap,
            child: SizedBox(
              key: _orb,
              height: 56,
              child: Center(child: GlassProfileOrb(preset: widget.preset, size: 56, mood: widget.selected ? gt.colorIris300 : null, selected: widget.selected)),
            ),
          ),
        ),
      );
}

/// The launched copy of the chosen avatar on its arc into the preview (glass 4.10, Avatar arc): 280 ms under 3,000 px/s².
class _ArcFlight extends StatefulWidget {
  const _ArcFlight({required this.arc, required this.preset, required this.size, required this.mood, required this.onLand, required this.done});
  final AvatarArc arc;
  final GlassAvatarPreset preset;
  final double size;
  final Color mood;
  final VoidCallback onLand;
  final VoidCallback done;

  @override
  State<_ArcFlight> createState() => _ArcFlightState();
}

class _ArcFlightState extends State<_ArcFlight> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: Duration(milliseconds: widget.arc.flightMs));

  @override
  void initState() {
    super.initState();
    unawaited(_c.forward().whenComplete(() {
      widget.onLand();
      widget.done();
    }),);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final p = widget.arc.at(_c.value * widget.arc.flightMs);
            final s = widget.size + (96 - widget.size) * _c.value;
            return Stack(children: [Positioned(left: p.dx - s / 2, top: p.dy - s / 2, width: s, height: s, child: GlassProfileOrb(preset: widget.preset, size: s, mood: widget.mood))]);
          },
        ),
      );
}

/// Glass · Cinematic, each led by a 32 px circular mini preview (frame `000.png` of the skin's loop; the neutral mark while Glass's
/// frames do not exist). A radio group; the thumb slides on `springTab`.
class _SkinChoice extends ConsumerWidget {
  const _SkinChoice({required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reduced = glassReduced(ref);
    final glassSel = value == 'glass';
    return Semantics(
      container: true,
      label: 'Skin',
      child: SizedBox(
        height: 52,
        child: DecoratedBox(
          decoration: BoxDecoration(color: gt.colorFill3, borderRadius: BorderRadius.circular(26)),
          child: Stack(
            children: [
              AnimatedAlign(
                duration: reduced ? Duration.zero : Duration(milliseconds: gt.springTab.ms),
                curve: Curves.easeOutBack,
                alignment: glassSel ? Alignment.centerLeft : Alignment.centerRight,
                child: FractionallySizedBox(
                  widthFactor: 0.5,
                  heightFactor: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: DecoratedBox(decoration: BoxDecoration(color: gt.colorFill2, borderRadius: BorderRadius.circular(24), border: Border.all(color: gt.colorIris500, width: 1.5))),
                  ),
                ),
              ),
              Positioned.fill(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch, // each segment is a 52 px tall target
                  children: [
                    Expanded(child: _SkinSegment(skin: 'glass', label: 'Glass', selected: glassSel, onTap: () => onChanged('glass'))),
                    Expanded(child: _SkinSegment(skin: 'cinematic', label: 'Cinematic', selected: !glassSel, onTap: () => onChanged('cinematic'))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkinSegment extends StatelessWidget {
  const _SkinSegment({required this.skin, required this.label, required this.selected, required this.onTap});
  final String skin;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        inMutuallyExclusiveGroup: true,
        checked: selected,
        button: true,
        label: label,
        excludeSemantics: true,
        onTap: onTap,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SkinMiniPreview(skin: skin),
              const SizedBox(width: 8),
              Flexible(child: GlassLabel(label, role: gt.typeSubhead, wght: selected ? 620 : 460, color: selected ? gt.colorLabel1 : gt.colorLabel2)),
            ],
          ),
        ),
      );
}

/// A 32 px circular mini preview of a skin: frame `000.png` of its preview loop, else the neutral mark on the brand aurora.
class SkinMiniPreview extends StatelessWidget {
  const SkinMiniPreview({super.key, required this.skin, this.size = 32});
  final String skin;
  final double size;

  /// Both skins' frames ship (`mobile/39` captured Glass's).
  static const bool glassFramesBundled = true;

  @override
  Widget build(BuildContext context) {
    final bundled = skin == 'cinematic' || glassFramesBundled;
    return ClipOval(
      child: SizedBox.square(
        dimension: size,
        child: bundled
            ? Image.asset('assets/skin_previews/$skin/000.png', fit: BoxFit.cover, gaplessPlayback: true, errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFF131317)))
            : DecoratedBox(
                decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [gt.colorAurora1.withValues(alpha: 0.5), gt.colorAurora2.withValues(alpha: 0.5), gt.colorAurora3.withValues(alpha: 0.5)])),
                child: Center(child: GlassMark(height: size * 0.5)),
              ),
      ),
    );
  }
}
