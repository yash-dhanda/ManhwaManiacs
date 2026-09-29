import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:manhwamaniacs/skins/cinematic/feedback.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_certificate.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_checkbox.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/layout/cine_measure.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/transitions.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// The certificate dialog shell (cinematic 7.24): a full-screen takeover at every width. The gate
/// flow (the mutation, invalidation, toasts, rating card, local filtering) is mobile/07;
/// [onConfirm] reports whether it worked: on `true` the stamp plays and the route pops `true`
/// after 480 ms, on `false` the button shows its error state.
class CineCertificateDialog extends StatefulWidget {
  const CineCertificateDialog({super.key, this.profileName = '', required this.onConfirm, this.onCancel});

  final String profileName;
  final Future<bool> Function() onConfirm;
  final VoidCallback? onCancel;

  @override
  State<CineCertificateDialog> createState() => _CineCertificateDialogState();
}

class _CineCertificateDialogState extends State<CineCertificateDialog> {
  final _stamp = CineCertificateController();
  bool _ok = false, _busy = false, _failed = false;

  @override
  void dispose() {
    _stamp.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    setState(() {
      _busy = true;
      _failed = false;
    });
    final good = await widget.onConfirm();
    if (!mounted) return;
    if (good) {
      cineFeedback(context, HapticEvent.gateConfirm, sound: SoundEvent.gateConfirm);
      _stamp.stamp();
      await Future<void>.delayed(const Duration(milliseconds: 480));
      if (mounted) Navigator.of(context).pop(true);
    } else {
      setState(() {
        _busy = false;
        _failed = true;
      });
    }
  }

  void _cancel() {
    widget.onCancel?.call();
    Navigator.of(context).maybePop(false);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final name = widget.profileName.trim();
    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.escape): _cancel},
      child: Scaffold(
        backgroundColor: const Color(0xFF000000),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(c.space6),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Align(alignment: Alignment.centerLeft, child: CineButton(key: const Key('cert-cancel-top'), label: 'Cancel', variant: CineButtonVariant.quiet, onPressed: _busy ? null : _cancel)),
                  SizedBox(height: c.space6),
                  Center(child: CineCertificate(controller: _stamp)),
                  SizedBox(height: c.space6),
                  CineRoleText('RESTRICTED · THIS PROFILE ONLY', c.typeKicker, color: c.colorProof),
                  SizedBox(height: c.space2),
                  CineRoleText(name.isEmpty ? 'Show mature content on this profile?' : 'Show mature content on $name?', c.typeSubhead),
                  SizedBox(height: c.space4),
                  CineMeasure(
                    ch: 48,
                    style: CineText.style(context, c.typeBody),
                    child: CineRoleText(
                      'Adult (18+) sources, series, search results and recommendations will appear throughout ManhwaManiacs for this profile. Only continue if you are of legal age where you live. You can turn this off any time.',
                      c.typeBody,
                      color: c.colorInk60,
                    ),
                  ),
                  SizedBox(height: c.space6),
                  CineCheckbox(key: const Key('cert-check'), value: _ok, label: 'I am 18 or older', onChanged: _busy ? null : (v) => setState(() => _ok = v)),
                  SizedBox(height: c.space6),
                  CineButton(
                    key: const Key('cert-enable'),
                    label: 'Enable 18+',
                    loading: _busy,
                    loadingLabel: 'Enabling…',
                    errorText: _failed ? 'That didn’t go through. Try again.' : null,
                    disabledReason: _ok ? null : 'Confirm you are 18 or older first',
                    onPressed: _ok && !_busy ? _confirm : null,
                  ),
                  SizedBox(height: c.space2),
                  CineButton(label: 'Cancel', variant: CineButtonVariant.quiet, onPressed: _busy ? null : _cancel),
                ],),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Pushes the shell on the shared Dip (out 160 ms `lift` to `#000`, hold 40 ms, in 240 ms
/// `settle`, 440 ms both directions; reduced motion a 150 ms fade): the takeover move of
/// `transitions.dart`.
Future<bool?> openCineCertificateDialog(BuildContext context, {String profileName = '', required Future<bool> Function() onConfirm, VoidCallback? onCancel}) {
  final navigator = Navigator.of(context, rootNavigator: true);
  final themes = InheritedTheme.capture(from: context, to: navigator.context);
  return navigator.push<bool>(
    PageRouteBuilder<bool>(
      transitionDuration: CineRouteMotion.forward(CineTransitionKind.dip),
      reverseTransitionDuration: CineRouteMotion.reverse(CineTransitionKind.dip),
      pageBuilder: (_, __, ___) => themes.wrap(CineCertificateDialog(profileName: profileName, onConfirm: onConfirm, onCancel: onCancel)),
      transitionsBuilder: (context, a, _, child) => cineDipTransition(context: context, animation: a, child: child),
    ),
  );
}
