import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

/// A screen-reader announcement ("Ready", a moved row, an error toast).
void cineAnnounce(BuildContext context, String message) {
  try {
    SemanticsService.sendAnnouncement(View.of(context), message, Directionality.of(context));
  } catch (_) {}
}
