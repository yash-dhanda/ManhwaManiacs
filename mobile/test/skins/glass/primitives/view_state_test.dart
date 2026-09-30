import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/skins/glass/primitives/states/lens_glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/states/view_state.dart';

void main() {
  GlassViewState r({bool loading = false, bool data = false, AppError? error, bool online = true}) =>
      resolveViewState(isLoading: loading, hasData: data, error: error, online: online);

  test('resolves loading, offline, error, empty and content', () {
    expect(r(loading: true), GlassViewState.loading);
    expect(r(data: true), GlassViewState.content);
    expect(r(data: true, error: const TimeoutError()), GlassViewState.content, reason: 'stale rows stay');
    expect(r(error: const NetworkError(message: 'x')), GlassViewState.offline);
    expect(r(error: const TimeoutError()), GlassViewState.offline);
    expect(r(online: false), GlassViewState.offline);
    expect(r(error: const ApiError(statusCode: 500, code: 'x', message: 'x')), GlassViewState.error);
    expect(r(), GlassViewState.empty);
  });

  test('every situation of the 7.24 table has a glyph', () {
    for (final s in LensSituation.values) {
      expect(lensGlyph(s), isA<IconData>(), reason: '$s');
    }
    expect(lensGlyph(LensSituation.library), lensGlyph(LensSituation.shelf));
    expect(lensGlyph(LensSituation.dialogueIdle), lensGlyph(LensSituation.noRecapSource));
    expect(lensGlyphIsNeutral(LensSituation.aiUnavailable), isTrue);
    expect(lensGlyphIsNeutral(LensSituation.offline), isFalse);
    expect(LensSituation.values.length, 21);
  });
}
