import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:manhwamaniacs/skins/cinematic/icons/icon_roles.g.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_progress.dart';
import 'package:manhwamaniacs/skins/cinematic/stock.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

class CineSelectAction {
  const CineSelectAction(this.label, this.icon, this.onPressed, {this.destructive = false});
  final String label;
  final CineIconRole icon;
  final VoidCallback? onPressed;
  final bool destructive;
}

/// A bulk run in progress: `4 OF 12 · 1 FAILED`.
typedef CineSelectRun = ({int done, int total, int failed});

/// The select-mode bar (cinematic 7.29): over the thumb index and above the safe area, `paper.2`
/// raised with a 1 px `rule.2` top. Shows `12 SELECTED`, `Select all 40`, the caller's actions as
/// `quiet` buttons (Unfollow in `proof`, which should open a [CineConfirmDialog] with the arm) and
/// `Done`. While [run] is set it shows the progress and `Stop`; a [result] line has `Dismiss` and,
/// for destructive runs, `Undo`. `Esc` equals `Done`; Android back is bound by the shell.
class CineSelectModeBar extends StatelessWidget {
  const CineSelectModeBar({
    super.key,
    required this.selected,
    required this.total,
    required this.actions,
    required this.onDone,
    this.onSelectAll,
    this.run,
    this.onStop,
    this.result,
    this.onDismissResult,
    this.onUndo,
  });

  final int selected, total;
  final List<CineSelectAction> actions;
  final VoidCallback onDone;
  final VoidCallback? onSelectAll, onStop, onDismissResult, onUndo;
  final CineSelectRun? run;
  final String? result;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final safe = MediaQuery.viewPaddingOf(context).bottom;
    Widget body;
    if (run != null) {
      final r = run!;
      body = Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Wrap(alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center, children: [
          CineRoleText('${r.done} OF ${r.total}${r.failed > 0 ? ' · ${r.failed} FAILED' : ''}', c.typeFolio),
          CineButton(label: 'Stop', variant: CineButtonVariant.quiet, onPressed: onStop),
        ],),
        CineRuleProgress(value: r.total == 0 ? 0 : r.done / r.total, semanticLabel: 'Progress'),
      ],);
    } else if (result != null) {
      body = Wrap(alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center, children: [
        Semantics(liveRegion: true, child: CineRoleText(result!, c.typeUi)),
        if (onUndo != null) CineButton(label: 'Undo', variant: CineButtonVariant.quiet, onPressed: onUndo),
        CineButton(label: 'Dismiss', variant: CineButtonVariant.quiet, onPressed: onDismissResult),
      ],);
    } else {
      body = Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Wrap(alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center, children: [
          CineRoleText('$selected SELECTED', c.typeFolio),
          if (onSelectAll != null && selected < total) CineButton(label: 'Select all $total', variant: CineButtonVariant.quiet, onPressed: onSelectAll),
          CineButton(label: 'Done', variant: CineButtonVariant.quiet, onPressed: onDone),
        ],),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            for (final a in actions)
              Padding(
                padding: EdgeInsets.only(right: c.space2),
                child: a.destructive
                    ? CineButton(label: a.label, icon: a.icon, variant: CineButtonVariant.destructive, onPressed: selected == 0 ? null : a.onPressed)
                    : CineButton(label: a.label, icon: a.icon, variant: CineButtonVariant.quiet, onPressed: selected == 0 ? null : a.onPressed),
              ),
          ],),
        ),
      ],);
    }
    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.escape): onDone},
      child: CineStock.raised(
        Container(
          decoration: BoxDecoration(color: c.colorPaper2, border: Border(top: BorderSide(color: c.colorRule2))),
          padding: EdgeInsets.fromLTRB(c.space4, c.space2, c.space4, c.space2 + safe),
          child: body,
        ),
      ),
    );
  }
}
