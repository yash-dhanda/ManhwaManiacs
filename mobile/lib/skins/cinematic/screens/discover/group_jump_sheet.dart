import 'package:flutter/material.dart';
import 'package:manhwamaniacs/features/sources/models/source_search_group.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/cine_kit.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

/// The `Jump to source` sheet: groups with counts; returns the tapped key.
Future<String?> showGroupJumpSheet(
        BuildContext context, List<SourceSearchGroup> groups,) =>
    showCineSheet<String>(
      context,
      title: 'Jump to source',
      body: (context) {
        final t = context.cine;
        return ListView(
          shrinkWrap: true,
          children: [
            for (final g in groups)
              InkWell(
                onTap: () => Navigator.of(context).pop(g.key),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: CineSpace.s4),
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
                          style: cineText(context, t.typeFolio,
                              color: t.colorInk60,),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
