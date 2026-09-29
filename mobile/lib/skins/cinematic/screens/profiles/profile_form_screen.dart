import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/app/switch_skin.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/keyboard/shortcut_registry.dart';
import 'package:manhwamaniacs/features/downloads/providers/active_download_queue_provider.dart';
import 'package:manhwamaniacs/features/profiles/models/mood.dart';
import 'package:manhwamaniacs/features/profiles/models/profile.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/features/settings/providers/settings_provider.dart';
import 'package:manhwamaniacs/skins/cinematic/feedback.dart';
import 'package:manhwamaniacs/skins/cinematic/focus_ring.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/avatar_presets.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_avatar.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_confirm_dialog.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_galley.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_masthead.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_mood_grade.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_notice.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_segmented_control.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_slug_lines.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_text_field.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/toasts.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/profiles/profile_form_logic.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/profiles/profiles_copy.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/shared/mature_gate_switch.dart';
import 'package:manhwamaniacs/skins/cinematic/shell/cine_scaffold.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/skin.dart';

/// The profile form, new and edit (mobile S06 and S07, cinematic 8.6): name, avatar radiogroup,
/// mood chips, the 18+ switch through the certificate, the Edition row (behind `glass_available`),
/// and on edit a destructive Delete.
class ProfileFormScreen extends ConsumerStatefulWidget {
  const ProfileFormScreen({super.key, this.profileId});

  /// Null on New.
  final int? profileId;

  @override
  ConsumerState<ProfileFormScreen> createState() => _ProfileFormScreenState();
}

class _ProfileFormScreenState extends ConsumerState<ProfileFormScreen> {
  final _name = TextEditingController();
  final _nameNode = FocusNode(debugLabel: 'profile-name');
  bool _seeded = false;
  String _avatar = kAvatarPresets.first.key;
  String _mood = 'default';
  bool _mature = false;
  String _skin = 'cinematic';
  String? _skinBefore;
  bool _saving = false;
  bool _deleting = false;
  String? _nameError;
  String? _serverError;

  bool get _isNew => widget.profileId == null;

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
    if (_isNew) _seeded = true;
  }

  @override
  void dispose() {
    _name.dispose();
    _nameNode.dispose();
    super.dispose();
  }

  void _seed(Profile p) {
    if (_seeded) return;
    _seeded = true;
    _name.text = p.name;
    _avatar = p.avatarKey ?? kAvatarPresets.first.key;
    _mood = p.mood.wire;
    _mature = p.matureContentEnabled;
    _skin = p.skin ?? 'cinematic';
    _skinBefore = p.skin ?? 'cinematic';
  }

  void _leave() => context.canPop() ? context.pop() : context.go(Routes.profiles());

  Future<void> _save(Profile? existing) async {
    if (_saving) return;
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = kNameEmpty);
      _nameNode.requestFocus();
      return;
    }
    setState(() {
      _saving = true;
      _nameError = null;
      _serverError = null;
    });
    final notifier = ref.read(profilesProvider.notifier);
    final mood = Mood.fromWire(_mood);
    final active = ref.read(activeProfileProvider);
    final isActive = existing != null && active?.id == existing.id;
    final edition = decideEditionSave(
      isActiveProfile: isActive,
      before: _skinBefore,
      after: _skin,
      glassAvailable: Flags.glassAvailable,
    );
    final skinToSend = edition.kind == EditionSaveKind.saveWithForm ? edition.value : null;
    final AppError? err = existing == null
        ? await notifier.create(name: name, avatarKey: _avatar, mood: mood, matureContentEnabled: _mature, skin: skinToSend)
        : await notifier.edit(
            existing.id,
            name: name,
            avatarKey: _avatar,
            mood: mood,
            matureContentEnabled: _mature,
            skin: skinToSend,
          );
    if (!mounted) return;
    if (err != null) {
      setState(() {
        _saving = false;
        _serverError = profileSaveError(err);
      });
      return;
    }
    if (existing != null && isActive && existing.matureContentEnabled != _mature) {
      // The gate changed on the active profile: the server value, every gated cache and the device
      // stores (through `matureGateOpenProvider`) follow.
      ref.invalidate(matureContentProvider);
      ref.read(matureOverrideChangedProvider)();
      if (!_mature) ref.read(cineToastsProvider.notifier).info(matureHiddenToast(name));
    }
    ref.read(cineToastsProvider.notifier).success(savedToast(name));
    if (edition.kind == EditionSaveKind.confirmRestart) {
      final queued = ref.read(activeDownloadCountProvider) > 0;
      final ok = await showCineConfirm(
        context,
        title: 'Restart in Glass?',
        body: restartBody(downloadsQueued: queued),
        confirmLabel: 'Restart in Glass',
      );
      if (!mounted) return;
      if (ok) {
        await notifier.edit(existing!.id, skin: 'glass');
        if (!mounted) return;
        await switchSkinFrom(context, ref, to: SkinId.glass, outgoing: () async {});
        return;
      }
    }
    setState(() => _saving = false);
    _leave();
  }

  Future<void> _delete(Profile p) async {
    final ok = await showCineConfirm(
      context,
      title: deleteTitle(p.name),
      body: kDeleteBody,
      confirmLabel: 'Delete profile',
      destructive: true,
    );
    if (!ok || !mounted) return;
    final wasActive = ref.read(activeProfileProvider)?.id == p.id;
    setState(() => _deleting = true);
    final err = await ref.read(profilesProvider.notifier).delete(p.id);
    if (!mounted) return;
    if (err != null) {
      setState(() {
        _deleting = false;
        _serverError = profileSaveError(err);
      });
      return;
    }
    ref.read(cineToastsProvider.notifier).info(deletedToast(p.name));
    if (wasActive) {
      context.go(Routes.profiles());
    } else {
      _leave();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final profiles = ref.watch(profilesProvider);
    Profile? existing;
    Widget? gate;
    if (!_isNew) {
      final list = profiles.valueOrNull;
      if (list == null) {
        gate = profiles.hasError
            ? _NotFound(onBack: _leave)
            : const _FormGalley();
      } else {
        for (final p in list) {
          if (p.id == widget.profileId) existing = p;
        }
        if (existing == null) {
          gate = _NotFound(onBack: _leave);
        } else {
          _seed(existing);
        }
      }
    }
    final title = _isNew ? 'New profile' : 'Edit ${existing?.name ?? ''}'.trim();
    return RegisteredShortcuts(
      group: 'Profile form',
      entries: [
        ShortcutEntry(
          group: 'Profile form',
          activator: const SingleActivator(LogicalKeyboardKey.enter),
          description: 'Save',
          onInvoke: () => _save(existing),
          keys: const ['Enter'],
        ),
        ShortcutEntry(
          group: 'Profile form',
          activator: const SingleActivator(LogicalKeyboardKey.escape),
          description: 'Cancel',
          onInvoke: _leave,
          keys: const ['Esc'],
        ),
      ],
      child: CineScaffold(
        runningTitle: 'PROFILE',
        back: const CineBack(),
        firstRunNote: false,
        body: gate ??
            CineMoodGrade(
              mood: _mood == 'default' ? null : _mood,
              child: _WithTop(builder: (top) => SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(c.space4, top + c.space6, c.space4, c.space12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  CineMasthead(kicker: 'CASTING', title: title, id: 'profile-form'),
                  Center(child: CineAvatar(avatarKey: _avatar, size: 96)),
                  SizedBox(height: c.space6),
                  _nameField(context),
                  SizedBox(height: c.space6),
                  _avatarGrid(context),
                  SizedBox(height: c.space6),
                  _moodRow(context),
                  SizedBox(height: c.space6),
                  MatureGateSwitch.form(value: _mature, formProfileName: _name.text, onChanged: (v) => setState(() => _mature = v)),
                  if (Flags.glassAvailable) ...[SizedBox(height: c.space6), _edition(context)],
                  SizedBox(height: c.space8),
                  CineButton(
                    label: _isNew ? 'Create profile' : 'Save changes',
                    loadingLabel: 'Saving…',
                    loading: _saving,
                    onPressed: _saving || _deleting ? null : () => _save(existing),
                  ),
                  if (_serverError != null)
                    Padding(
                      padding: EdgeInsets.only(top: c.space3),
                      child: Semantics(liveRegion: true, child: CineRoleText(_serverError!, c.typeCaption, color: c.colorProof)),
                    ),
                  SizedBox(height: c.space3),
                  CineButton(label: 'Cancel', variant: CineButtonVariant.quiet, onPressed: _saving ? null : _leave),
                  if (existing != null) ...[
                    SizedBox(height: c.space8),
                    CineButton(
                      label: 'Delete profile',
                      variant: CineButtonVariant.destructive,
                      loading: _deleting,
                      onPressed: _saving || _deleting ? null : () => _delete(existing!),
                    ),
                  ],
                ],),
              ),),
            ),
      ),
    );
  }

  Widget _nameField(BuildContext context) {
    final c = context.cine;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      CineTextField(
        label: 'Name',
        controller: _name,
        focusNode: _nameNode,
        size: CineFieldSize.field,
        errorText: _nameError,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.done,
        inputFormatters: [LengthLimitingTextInputFormatter(30)],
        onChanged: (_) {
          if (_nameError != null) setState(() => _nameError = null);
        },
      ),
      Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: EdgeInsets.only(top: c.space1),
          child: CineRoleText(nameCounter(_name.text.characters.length), c.typeFolio, color: c.colorInk45),
        ),
      ),
    ],);
  }

  Widget _avatarGrid(BuildContext context) {
    final c = context.cine;
    final wide = MediaQuery.sizeOf(context).width >= 600;
    final cols = wide ? 6 : 4;
    return Semantics(
      container: true,
      label: 'Avatar',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        CineRoleText('Avatar', c.typeKicker, color: c.colorInk45, upper: true),
        SizedBox(height: c.space3),
        LayoutBuilder(builder: (context, box) {
          // 4 x 3 on phones, 6 x 2 from 600 px: the gap makes exactly [cols] fit a row.
          final gap = cols == 1 ? 0.0 : ((box.maxWidth - cols * 56) / (cols - 1)).clamp(8.0, 48.0);
          return Wrap(
          spacing: gap,
          runSpacing: c.space4,
          children: [
            for (var i = 0; i < kAvatarPresets.length; i++)
              _AvatarChoice(
                preset: kAvatarPresets[i],
                selected: kAvatarPresets[i].key == _avatar,
                onSelect: () {
                  cineFeedback(context, HapticEvent.select);
                  setState(() => _avatar = kAvatarPresets[i].key);
                },
                onArrow: (forward) {
                  final i2 = moveAvatar(i, kAvatarPresets.length, forward: forward);
                  cineFeedback(context, HapticEvent.select);
                  setState(() => _avatar = kAvatarPresets[i2].key);
                },
              ),
          ],
        );
        },),
      ],),
    );
  }

  Widget _moodRow(BuildContext context) {
    final c = context.cine;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      CineRoleText('Mood', c.typeKicker, color: c.colorInk45, upper: true),
      SizedBox(height: c.space2),
      CineSlugLines(
        items: [
          for (final m in kMoodChips)
            CineSlug(
              m.$1,
              m.$2,
              leading: kMoodSquares[m.$1] == null
                  ? null
                  : Container(key: Key('mood-square-${m.$1}'), width: 10, height: 10, color: Color(kMoodSquares[m.$1]!)),
            ),
        ],
        selected: {_mood},
        onChanged: (id) => setState(() => _mood = id),
      ),
      SizedBox(height: c.space2),
      CineRoleText(kMoodHelper, c.typeCaption, color: c.colorInk45),
    ],);
  }

  Widget _edition(BuildContext context) {
    final c = context.cine;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      CineRoleText('Edition', c.typeKicker, color: c.colorInk45, upper: true),
      SizedBox(height: c.space2),
      CineSegmentedControl(
        labels: const ['CINEMATIC', 'GLASS'],
        index: _skin == 'glass' ? 1 : 0,
        onChanged: (i) => setState(() => _skin = i == 1 ? 'glass' : 'cinematic'),
      ),
      SizedBox(height: c.space2),
      CineRoleText(kEditionCaption, c.typeCaption, color: c.colorInk45),
    ],);
  }
}

class _AvatarChoice extends StatelessWidget {
  const _AvatarChoice({required this.preset, required this.selected, required this.onSelect, required this.onArrow});
  final AvatarPreset preset;
  final bool selected;
  final VoidCallback onSelect;
  final ValueChanged<bool> onArrow;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      label: preset.name,
      excludeSemantics: true,
      onTap: onSelect,
      child: Tooltip(
        message: preset.name,
        child: Focus(
          canRequestFocus: false,
          skipTraversal: true,
          onKeyEvent: (n, e) {
            if (e is! KeyDownEvent) return KeyEventResult.ignored;
            if (e.logicalKey == LogicalKeyboardKey.arrowRight || e.logicalKey == LogicalKeyboardKey.arrowDown) {
              onArrow(true);
              return KeyEventResult.handled;
            }
            if (e.logicalKey == LogicalKeyboardKey.arrowLeft || e.logicalKey == LogicalKeyboardKey.arrowUp) {
              onArrow(false);
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: CinePressable(
            round: true,
            onTap: onSelect,
            builder: (_, __) => CineAvatar(avatarKey: preset.key, size: 56, selected: selected),
          ),
        ),
      ),
    );
  }
}

class _NotFound extends StatelessWidget {
  const _NotFound({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.all(context.cine.space4),
        child: CineNotice(
          tone: CineNoticeTone.empty,
          headline: kProfileNotFound,
          primary: CineNoticeAction('Back', onBack),
        ),
      );
}

/// Galley lines at the field heights while an edit loads.
class _FormGalley extends StatelessWidget {
  const _FormGalley();

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    return Padding(
      padding: EdgeInsets.all(c.space4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const CineGalleyHeadline(lineHeight: 48),
        SizedBox(height: c.space6),
        for (var i = 0; i < 4; i++) ...[CineGalleyLine(lineHeight: 48, index: i), SizedBox(height: c.space4)],
      ],),
    );
  }
}

/// Hands its builder the height the running head takes, which the scaffold reports to what sits inside it.
class _WithTop extends StatelessWidget {
  const _WithTop({required this.builder});
  final Widget Function(double top) builder;

  @override
  Widget build(BuildContext context) => builder(CineScaffoldScope.topExtentOf(context));
}
