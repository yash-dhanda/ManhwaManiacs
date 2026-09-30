import 'package:flutter/services.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/discover_keys.dart';

/// The Picks hardware-keyboard group (`Picks`): `/` focuses the ask field, `Enter` asks, `j` / `k`
/// move through the cards in reading order. `Delete` is Not for me on the focused card (the card
/// handles it). Bindings that would type a letter wait while a text field owns the keyboard.
List<CineKey> picksKeys({required void Function() focusAsk, required void Function() ask, required void Function(bool forward) step}) => [
      CineKey(key(LogicalKeyboardKey.slash), focusAsk, whenTextFieldFree: true),
      CineKey(key(LogicalKeyboardKey.enter), ask, whenTextFieldFree: true),
      CineKey(key(LogicalKeyboardKey.keyJ), () => step(true), whenTextFieldFree: true),
      CineKey(key(LogicalKeyboardKey.keyK), () => step(false), whenTextFieldFree: true),
    ];

const picksKeyGroup = 'Picks';
