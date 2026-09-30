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
    this.disabledReason,
  });

  final String id;
  final String label;
  final int? count;

  /// Set while the tab cannot be opened (`04 CIRCLE` for a profile that does not share): the tab is
  /// `ink.30`, exposes `enabled: false` and this text as its tooltip and hint.
  final String? disabledReason;

  bool get disabled => disabledReason != null;
  final Widget Function(BuildContext context) panelBuilder;

  String folio(int index) => (index + 1).toString().padLeft(2, '0');
}
