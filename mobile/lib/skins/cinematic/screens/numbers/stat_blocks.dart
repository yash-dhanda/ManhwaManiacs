import 'package:flutter/material.dart';

/// The four blocks 2 x 2 on phones and 4 across on tablets.
class StatGrid extends StatelessWidget {
  const StatGrid({super.key, required this.blocks, required this.wide});
  final List<Widget> blocks;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    if (wide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < blocks.length; i++) ...[
            if (i > 0) const SizedBox(width: 24),
            Expanded(child: blocks[i]),
          ],
        ],
      );
    }
    return Column(
      children: [
        for (var r = 0; r < blocks.length; r += 2) ...[
          if (r > 0) const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: blocks[r]),
              const SizedBox(width: 24),
              Expanded(
                  child: r + 1 < blocks.length
                      ? blocks[r + 1]
                      : const SizedBox.shrink(),),
            ],
          ),
        ],
      ],
    );
  }
}
