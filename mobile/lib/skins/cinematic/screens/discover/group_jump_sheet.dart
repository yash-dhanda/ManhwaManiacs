import 'package:flutter/material.dart';
import 'package:manhwamaniacs/features/sources/models/source_search_group.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/cine_kit.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

/// The `Jump to source` sheet: groups with counts; returns the tapped key.
Future<String?> showGroupJumpSheet(BuildContext context, List<SourceSearchGroup> groups) =>
    showModalBottomSheet<String>(
      context: context,
      backgroundColor: context.cine.colorPaper2,
      barrierColor: CineScrim.modal,
      shape: const RoundedRectangleBorder(),
      builder: (context) {
        final t = context.cine;
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: CineSpace.s2),
                  width: 32,
                  height: 3,
                  color: t.colorInk30,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: CineSpace.s4),
                child: Kicker('Jump to source'),
              ),
              for (final g in groups)
                InkWell(
                  onTap: () => Navigator.of(context).pop(g.key),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: CineSpace.s4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              g.isLocal ? 'In your library' : g.sourceName,
                              style: cineText(context, t.typeTitle),
                            ),
                          ),
                          Text(
                            '${g.items.length}',
                            style: cineText(context, t.typeFolio, color: t.colorInk60),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
