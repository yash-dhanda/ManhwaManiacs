import 'package:flutter/material.dart';
import 'package:manhwamaniacs/features/sources/models/source.dart';
import 'package:manhwamaniacs/features/sources/utils/source_health.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/cine_kit.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

/// Health details: state text, last OK time, last error in Plex Mono on
/// `paper.1` (`ink.60`: inside a sheet, never `ink.45`).
Future<void> showHealthDetails(BuildContext context, SourceSummary source) =>
    showCineSheet<void>(
      context,
      title: 'Health details',
      body: (context) {
        final t = context.cine;
        final d = describeHealth(source.health, DateTime.now());
        final h = source.health;
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(CineSpace.s4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    source.name,
                    style: cineText(context, t.typeSubhead),
                  ),
                ),
                const SizedBox(height: CineSpace.s3),
                Row(
                  children: [
                    HealthMark(d.state),
                    const SizedBox(width: CineSpace.s2),
                    Text(d.label, style: cineText(context, t.typeUi)),
                  ],
                ),
                if (h?.lastOkAt != null) ...[
                  const SizedBox(height: CineSpace.s2),
                  Text(
                    'Last OK ${h!.lastOkAt}',
                    style:
                        cineText(context, t.typeCaption, color: t.colorInk60),
                  ),
                ],
                if (h?.lastError != null) ...[
                  const SizedBox(height: CineSpace.s3),
                  ColoredBox(
                    color: t.colorPaper1,
                    child: Padding(
                      padding: const EdgeInsets.all(CineSpace.s3),
                      child: Text(
                        h!.lastError!,
                        style:
                            cineText(context, t.typeFolio, color: t.colorInk60),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
