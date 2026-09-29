import 'package:flutter/widgets.dart';

/// One contents tab of the series page. `mobile/19` appends `03 MORE LIKE
/// THIS` and `mobile/22` appends `04 CIRCLE` by adding entries to the list the
/// page is built from; folios follow the list order.
class FeatureTab {
  const FeatureTab({
    required this.id,
    required this.label,
    required this.panelBuilder,
    this.count,
  });

  final String id;
  final String label;
  final int? count;
  final Widget Function(BuildContext context) panelBuilder;

  String folio(int index) => (index + 1).toString().padLeft(2, '0');
}
