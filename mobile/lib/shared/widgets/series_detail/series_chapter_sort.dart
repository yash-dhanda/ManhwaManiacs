import 'package:flutter/material.dart';
import 'package:manhwamaniacs/app/theme/app_colors.dart';
import 'package:manhwamaniacs/app/theme/app_presets.dart';
import 'package:manhwamaniacs/features/library/utils/series_chapter_sort.dart';

/// Compact Newest/Oldest segmented toggle for the chapter list header.
class SeriesChapterSortToggle extends StatelessWidget {
  const SeriesChapterSortToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final SeriesChapterSortOrder value;
  final ValueChanged<SeriesChapterSortOrder> onChanged;

  @override
  Widget build(BuildContext context) {
    final motion = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 150);
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: context.colors.surface2,
        borderRadius: BorderRadius.circular(context.radii.lg),
        border: Border.all(color: context.colors.glassEdge),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _segment(context, 'Newest', SeriesChapterSortOrder.newest, motion),
          _segment(context, 'Oldest', SeriesChapterSortOrder.oldest, motion),
        ],
      ),
    );
  }

  Widget _segment(
    BuildContext context,
    String label,
    SeriesChapterSortOrder order,
    Duration motion,
  ) {
    final selected = value == order;
    return GestureDetector(
      onTap: selected ? null : () => onChanged(order),
      child: AnimatedContainer(
        duration: motion,
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(
          horizontal: context.space.md,
          vertical: context.space.xs,
        ),
        decoration: BoxDecoration(
          color: selected ? context.colors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(context.radii.md),
        ),
        child: Text(
          label,
          style: context.text.caption.copyWith(
            color: selected ? context.colors.primaryFg : context.colors.muted,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
