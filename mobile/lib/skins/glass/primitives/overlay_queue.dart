
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Things that share the top band (glass 7.12, 7.30, 15.7), highest priority first.
enum OverlayKind { alert, toast, newChapters, appUpdate }

/// Which bottom bar shows: the bulk-selection toolbar or the "Unsaved changes" bar (set by `mobile/28`'s floating bar).
enum GlassBottomBar { none, bulk, unsaved }

final glassBottomBarProvider = StateProvider<GlassBottomBar>((ref) => GlassBottomBar.none);

/// True while a toast shows, so the shell's top edge plateau extends to safe-top + 104 (`mobile/29`).
final glassToastShowingProvider = StateProvider<bool>((ref) => false);

/// The sidebar's trailing edge on tablet and desktop frames, 0 until `mobile/29` sets it.
final glassSidebarEdgeProvider = StateProvider<double>((ref) => 0);

/// True inside the readers: toasts sit top-centre at 60 px.
final glassReaderActiveProvider = StateProvider<bool>((ref) => false);

/// What may show right now. Pure, so the phone priorities and the shared tablet queue are unit tests.
@immutable
class OverlayQueueState {
  const OverlayQueueState({
    this.requested = const [],
    this.blockers = 0,
    this.phone = true,
    this.bottomBar = false,
  });

  /// Requested kinds in request order.
  final List<OverlayKind> requested;

  /// Open menus and context menus.
  final int blockers;
  final bool phone;
  final bool bottomBar;

  Set<OverlayKind> get visible {
    final want = requested.toSet();
    final out = <OverlayKind>{};
    if (want.contains(OverlayKind.alert)) out.add(OverlayKind.alert);
    if (blockers > 0) return out;
    if (phone) {
      // One slot under the nav row: alert > toast > new-chapters > app-update.
      if (out.isNotEmpty) return out;
      for (final k in OverlayKind.values) {
        if (want.contains(k)) return {k};
      }
      return out;
    }
    // Tablet and desktop: toasts and the capsule share one queue (a toast waits while the capsule shows).
    if (want.contains(OverlayKind.newChapters)) {
      out.add(OverlayKind.newChapters);
    } else if (want.contains(OverlayKind.toast)) {
      out.add(OverlayKind.toast);
    }
    if (want.contains(OverlayKind.appUpdate) && !bottomBar) out.add(OverlayKind.appUpdate);
    return out;
  }

  OverlayQueueState copyWith({List<OverlayKind>? requested, int? blockers, bool? phone, bool? bottomBar}) => OverlayQueueState(
        requested: requested ?? this.requested,
        blockers: blockers ?? this.blockers,
        phone: phone ?? this.phone,
        bottomBar: bottomBar ?? this.bottomBar,
      );
}

class OverlayQueue extends Notifier<OverlayQueueState> {
  @override
  OverlayQueueState build() {
    ref.listen(glassBottomBarProvider, (_, v) => state = state.copyWith(bottomBar: v != GlassBottomBar.none));
    return OverlayQueueState(bottomBar: ref.read(glassBottomBarProvider) != GlassBottomBar.none);
  }

  /// The host sets the frame kind (phone or not).
  void setPhone(bool phone) {
    if (state.phone != phone) state = state.copyWith(phone: phone);
  }

  void requestSlot(OverlayKind kind) {
    if (state.requested.contains(kind)) return;
    state = state.copyWith(requested: [...state.requested, kind]);
  }

  void release(OverlayKind kind) {
    if (!state.requested.contains(kind)) return;
    state = state.copyWith(requested: [for (final k in state.requested) if (k != kind) k]);
  }

  /// Opens a blocker (a menu); call the returned disposer when it closes.
  VoidCallback registerBlocker() {
    state = state.copyWith(blockers: state.blockers + 1);
    var done = false;
    return () {
      if (done) return;
      done = true;
      try {
        state = state.copyWith(blockers: state.blockers - 1);
      } on StateError {
        // The container was disposed first.
      }
    };
  }
}

final overlayQueueProvider = NotifierProvider<OverlayQueue, OverlayQueueState>(OverlayQueue.new);

/// Whether [kind] may show now.
final overlaySlotVisibleProvider = Provider.family<bool, OverlayKind>(
  (ref, kind) => ref.watch(overlayQueueProvider.select((s) => s.visible.contains(kind))),
);
