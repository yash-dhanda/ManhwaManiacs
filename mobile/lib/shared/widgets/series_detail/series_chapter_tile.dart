import 'package:flutter/material.dart';
import 'package:manhwamaniacs/app/theme/app_colors.dart';
import 'package:manhwamaniacs/app/theme/app_presets.dart';
import 'package:manhwamaniacs/features/downloads/models/series_chapter_download_action.dart';
import 'package:manhwamaniacs/features/sources/utils/chapter_label.dart';
import 'package:manhwamaniacs/shared/widgets/glass_card.dart';

/// Multi-select state for one chapter row. Null on a list that cannot be
/// selected from (a library series with no source to download the rest from),
/// which is why this is a separate object rather than a nullable callback plus
/// a bool that would have to agree with it.
class SeriesChapterSelection {
  const SeriesChapterSelection({
    required this.selected,
    required this.onChanged,
    this.checkboxKey,
  });

  final bool selected;

  /// Null disables the checkbox without hiding it — used while a queue request
  /// is in flight, so the row does not jump as buttons appear and disappear.
  final ValueChanged<bool?>? onChanged;

  final Key? checkboxKey;
}

/// One chapter row, identical on the library and source series pages.
///
/// Every distinction the two pages used to draw differently — read state,
/// download state, the chapter currently being read — is a flag here, so the
/// pages can differ in what they know about a chapter but never in how that
/// knowledge looks.
class SeriesChapterTile extends StatelessWidget {
  const SeriesChapterTile({
    super.key,
    required this.label,
    this.progressText,
    this.uploadedLabel,
    this.inProgress = false,
    this.isRead = false,
    this.isCurrent = false,
    this.onTap,
    this.selection,
    this.download,
  });

  final ChapterLabel label;

  /// "7/20 pages" — see `seriesChapterProgressText`.
  final String? progressText;

  /// When the source says this chapter went up ("Today", "3d ago", "Aug 30,
  /// 2026"). Null for the many sources that publish no date at all, in which
  /// case the row simply carries no line for it. See `chapterDateLabel`.
  final String? uploadedLabel;

  /// Whether [progressText] describes a part-read chapter, which glows warm
  /// rather than staying muted like an untouched or finished one.
  final bool inProgress;

  /// Finished. Recedes the whole row so unread chapters stand out.
  final bool isRead;

  /// The chapter the reader would resume — carries the "Reading" pill.
  final bool isCurrent;

  final VoidCallback? onTap;
  final SeriesChapterSelection? selection;
  final SeriesChapterDownloadAction? download;

  @override
  Widget build(BuildContext context) {
    final selection = this.selection;
    final download = this.download;

    final card = Padding(
      padding: EdgeInsets.only(bottom: context.space.sm),
      child: GlassCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (selection != null)
              Checkbox(
                key: selection.checkboxKey,
                value: selection.selected,
                onChanged: selection.onChanged,
              ),
            Expanded(
              child: InkWell(
                onTap: onTap,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: context.space.sm,
                    // Rows without a checkbox would otherwise start hard against
                    // the card edge where selectable rows start inset.
                    horizontal: selection == null ? context.space.md : 0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              label.primary,
                              style: context.text.labelLg.copyWith(
                                color: isRead ? context.colors.muted : null,
                              ),
                            ),
                          ),
                          if (isCurrent) ...[
                            SizedBox(width: context.space.sm),
                            const _ReadingPill(),
                          ],
                        ],
                      ),
                      if (label.secondary != null)
                        Text(label.secondary!, style: context.text.bodySm),
                      if (progressText != null)
                        Text(
                          progressText!,
                          style: context.text.caption.copyWith(
                            color:
                                inProgress ? context.colors.primary : context.colors.muted,
                          ),
                        ),
                      if (uploadedLabel != null)
                        Text(
                          uploadedLabel!,
                          style: context.text.caption
                              .copyWith(color: context.colors.muted),
                        ),
                      if (download != null) _DownloadStatusLine(download: download),
                    ],
                  ),
                ),
              ),
            ),
            if (download != null)
              SeriesChapterDownloadControl(download: download),
          ],
        ),
      ),
    );

    // Read chapters recede: dropping the whole card's opacity over the dark
    // background reads as a darker, muted "already read" row.
    return isRead ? Opacity(opacity: 0.6, child: card) : card;
  }
}

/// The sentence under the chapter title describing its download, and the
/// determinate bar that goes with an in-flight one. Nothing at all for a
/// chapter that has never been queued — an untouched row must stay quiet.
class _DownloadStatusLine extends StatelessWidget {
  const _DownloadStatusLine({required this.download});

  final SeriesChapterDownloadAction download;

  @override
  Widget build(BuildContext context) {
    final text = download.statusText;
    if (text == null) return const SizedBox.shrink();

    final color = switch (download.phase) {
      SeriesChapterDownloadPhase.failed => context.colors.danger,
      SeriesChapterDownloadPhase.downloaded => context.colors.success,
      SeriesChapterDownloadPhase.downloading => context.colors.primary,
      SeriesChapterDownloadPhase.queued ||
      SeriesChapterDownloadPhase.notDownloaded =>
        context.colors.muted,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(text, style: context.text.caption.copyWith(color: color)),
        if (download.phase == SeriesChapterDownloadPhase.downloading) ...[
          SizedBox(height: context.space.xxs),
          ClipRRect(
            borderRadius: BorderRadius.circular(context.space.xs),
            child: LinearProgressIndicator(
              key: const Key('chapter-download-bar'),
              value: download.progressValue,
              minHeight: 3,
              backgroundColor: context.colors.fg.withAlpha(20),
              valueColor: AlwaysStoppedAnimation(context.colors.primary),
            ),
          ),
        ],
      ],
    );
  }
}

/// The trailing control. A button only where there is something to press:
/// every other phase is a badge occupying the same slot, so a row never jumps
/// as a chapter moves from queued to downloading to saved.
/// The trailing download control for one chapter row.
///
/// Public because the novel Contents list renders the same control beside a
/// table-of-contents row rather than a chapter tile — two renderings of the
/// four download phases would be two things to keep in step.
class SeriesChapterDownloadControl extends StatelessWidget {
  const SeriesChapterDownloadControl({super.key, required this.download});

  final SeriesChapterDownloadAction download;

  @override
  Widget build(BuildContext context) {
    return switch (download.phase) {
      SeriesChapterDownloadPhase.notDownloaded => IconButton(
          key: download.buttonKey,
          tooltip: download.tooltip,
          onPressed: download.onPressed,
          icon: const Icon(Icons.download_outlined),
        ),
      SeriesChapterDownloadPhase.failed => IconButton(
          key: download.buttonKey,
          tooltip: download.tooltip,
          onPressed: download.onPressed,
          icon: Icon(Icons.refresh, color: context.colors.danger),
        ),
      SeriesChapterDownloadPhase.queued => _DownloadBadge(
          badgeKey: download.buttonKey,
          tooltip: download.tooltip,
          child: Icon(Icons.schedule, color: context.colors.muted, size: 20),
        ),
      SeriesChapterDownloadPhase.downloading => _DownloadBadge(
          badgeKey: download.buttonKey,
          tooltip: download.tooltip,
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              value: download.progressValue,
              strokeWidth: 2,
              backgroundColor: context.colors.fg.withAlpha(20),
              valueColor: AlwaysStoppedAnimation(context.colors.primary),
            ),
          ),
        ),
      // Filled, coloured and permanent: the owner's complaint was that a
      // downloaded chapter was indistinguishable from one that merely could
      // not be pressed.
      SeriesChapterDownloadPhase.downloaded => _DownloadBadge(
          badgeKey: download.buttonKey,
          tooltip: download.tooltip,
          child: Icon(Icons.offline_pin, color: context.colors.success, size: 22),
        ),
    };
  }
}

/// A non-interactive stand-in sized like the [IconButton] it replaces.
class _DownloadBadge extends StatelessWidget {
  const _DownloadBadge({
    required this.child,
    required this.tooltip,
    this.badgeKey,
  });

  final Widget child;
  final String tooltip;
  final Key? badgeKey;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      key: badgeKey,
      message: tooltip,
      child: SizedBox(
        width: kMinInteractiveDimension,
        height: kMinInteractiveDimension,
        child: Center(child: child),
      ),
    );
  }
}

class _ReadingPill extends StatelessWidget {
  const _ReadingPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.space.md,
        vertical: context.space.xxs,
      ),
      decoration: BoxDecoration(
        color: context.colors.primary.withAlpha(40),
        borderRadius: BorderRadius.circular(context.radii.full),
        border: Border.all(color: context.colors.primary.withAlpha(80)),
      ),
      child: Text(
        'Reading',
        style: context.text.caption.copyWith(
          color: context.colors.primary,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
