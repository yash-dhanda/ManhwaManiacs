import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/network/api_image.dart';
import 'package:manhwamaniacs/features/sources/models/source.dart';
import 'package:manhwamaniacs/features/sources/utils/source_health.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/icons/cine_glyphs.g.dart';
import 'package:manhwamaniacs/skins/cinematic/icons/phosphor.g.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/cine_extras.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/cine_kit.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/cine_poster.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/sources/source_table.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

/// One directory row (64 dp): logo, name + description, health, 18, pin,
/// menu. On tablets the health text and KIND sit on aligned columns
/// (the festival-listing table; dead sources struck through).
class SourceRow extends ConsumerWidget {
  const SourceRow({
    super.key,
    required this.source,
    required this.pinned,
    required this.pinEnabled,
    required this.pinReason,
    required this.onOpen,
    required this.onTogglePin,
    required this.onMenu,
    this.trailingHandle,
    this.focusNode,
  });

  final SourceSummary source;
  final bool pinned;
  final bool pinEnabled;
  final String? pinReason;
  final VoidCallback onOpen;
  final VoidCallback onTogglePin;
  final VoidCallback onMenu;
  final Widget? trailingHandle;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.cine;
    final base = ref.watch(apiBaseUrlProvider);
    final health = describeHealth(source.health, DateTime.now());
    final tablet = isTablet(context);
    final dead = health.state == HealthState.dead;
    final demoted = health.state == HealthState.demoted;
    final label =
        '${source.name}, ${health.label}${source.mature ? ', 18+' : ''}'
        '${pinned ? ', pinned' : ''}';
    return Semantics(
      label: label,
      button: true,
      excludeSemantics: true,
      onTap: onOpen,
      onLongPress: onMenu,
      child: ChildFocusRing(child: CineLongPress(
          onLongPress: onMenu,
          child: InkWell(
            focusNode: focusNode,
            onTap: onOpen,
            child: SizedBox(
              height: 64,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: CineSpace.s4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: source.iconUrl == null
                          ? ColoredBox(
                              color: t.colorPaper1,
                              child: Center(
                                child: Text(
                                  source.name.characters.first,
                                  style: cineText(context, t.typeSubhead),
                                ),
                              ),
                            )
                          : CineCover(
                              url: resolveApiResourceUrl(base, source.iconUrl!),
                              displayWidth: 32,
                            ),
                    ),
                    const SizedBox(width: CineSpace.s3),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            source.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: cineText(context, t.typeTitle).copyWith(
                              decoration: dead && tablet
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          Text(
                            source.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: cineText(
                              context,
                              t.typeCaption,
                              color: t.colorInk60,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (tablet) ...[
                      SizedBox(
                        width: 72,
                        child: Text(
                          source.contentKind == kNovelContentKind
                              ? 'NOVEL'
                              : 'MANGA',
                          style: cineText(
                            context,
                            t.typeFolio,
                            color: t.colorInk60,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 200,
                        child: Text(
                          health.label,
                          style: cineText(
                            context,
                            t.typeFolio,
                            color: t.colorInk60,
                          ).copyWith(
                            decoration:
                                demoted ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ),
                    ],
                    HealthMark(health.state),
                    if (source.mature) ...[
                      const SizedBox(width: CineSpace.s2),
                      ExcludeSemantics(
                        child: Icon(
                          CineGlyphs.certificate18Regular,
                          size: 16,
                          color: t.colorInk100,
                        ),
                      ),
                    ],
                    const SizedBox(width: CineSpace.s2),
                    Tooltip(
                      message: pinEnabled ? '' : (pinReason ?? ''),
                      child: Semantics(
                        toggled: pinned,
                        label: 'Pin ${source.name}',
                        button: true,
                        enabled: pinEnabled,
                        excludeSemantics: true,
                        child: SizedBox(
                          width: 48,
                          height: 48,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              if (pinned)
                                Positioned(
                                  bottom: 8,
                                  width: 24,
                                  height: 2,
                                  child: ColoredBox(color: t.colorSpot),
                                ),
                              IconButton(
                                onPressed: pinEnabled ? onTogglePin : null,
                                icon: Icon(
                                  pinned
                                      ? PhosphorFill.pushPin
                                      : PhosphorLight.pushPin,
                                  size: 24,
                                  color:
                                      pinEnabled ? t.colorInk100 : t.colorInk30,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: IconButton(
                        tooltip: 'More for ${source.name}',
                        onPressed: onMenu,
                        icon: Icon(
                          PhosphorRegular.dotsThree,
                          size: 24,
                          color: t.colorInk100,
                        ),
                      ),
                    ),
                    if (trailingHandle != null)
                      trailingHandle!
                    else if (tablet)
                      const SizedBox(width: SourceTableHead.handleWidth),
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
