import 'package:flutter/material.dart';
import 'package:manhwamaniacs/features/updates/models/update_settings.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/sheet_route.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

String _interval(int minutes) {
  if (minutes % 60 == 0) {
    final h = minutes ~/ 60;
    return h == 1 ? 'hour' : '$h hours';
  }
  return '$minutes minutes';
}

/// "checking every 30 min": the deck's schedule part.
String scheduleShort(UpdateSettings s) => s.checkIntervalMinutes % 60 == 0 && s.checkIntervalMinutes >= 60
    ? 'checking every ${s.checkIntervalMinutes ~/ 60} h'
    : 'checking every ${s.checkIntervalMinutes} min';

String _clock(DateTime t) {
  final l = t.toLocal();
  return '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
}

/// "When chapters are checked" (cinematic 8.10): the deck for everyone who cannot change it.
Future<void> showScheduleSheet(BuildContext context, {required UpdateSettings? settings, required bool notifyOff}) => showCineSheet<void>(
      context,
      kicker: 'SCHEDULE',
      title: 'When chapters are checked',
      builder: (ctx) {
        final c = ctx.cine;
        return Padding(
          padding: EdgeInsets.fromLTRB(c.space4, 0, c.space4, c.space4),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            if (settings != null) CineRoleText('Checking every ${_interval(settings.checkIntervalMinutes)}.', c.typeBody),
            if (settings?.lastRunAt != null) CineRoleText('Last check: ${_clock(settings!.lastRunAt!)}.', c.typeBody),
            if (notifyOff) CineRoleText('New-chapter notices are off for this profile.', c.typeBody, color: c.colorSpot),
          ],),
        );
      },
    );
