// ignore_for_file: require_trailing_commas, avoid_redundant_argument_values, prefer_const_constructors
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/onboarding/models/taste.dart';
import 'package:manhwamaniacs/features/onboarding/repositories/onboarding_repository_impl.dart';
import 'package:manhwamaniacs/features/onboarding/store/onboarding_draft.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Adapter implements HttpClientAdapter {
  _Adapter(this.respond);
  final ResponseBody Function(RequestOptions o) respond;
  final List<RequestOptions> seen = [];
  @override
  Future<ResponseBody> fetch(RequestOptions o, Stream<List<int>>? body, Future<void>? cancel) async {
    seen.add(o);
    return respond(o);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Object body, [int code = 200]) => ResponseBody.fromString(jsonEncode(body), code, headers: {
      Headers.contentTypeHeader: ['application/json'],
    });

void main() {
  test('catalog query omits empty values; PUT carries touched fields only; 404 reads as null', () async {
    final a = _Adapter((o) {
      if (o.method == 'GET' && o.path.endsWith('/taste')) return _json({}, 404);
      return _json({'formats': <Object>[], 'genres': <Object>[], 'seeds': <Object>[]});
    });
    final repo = OnboardingRepositoryImpl(Dio()..httpClientAdapter = a);
    await repo.catalog(formats: ['manga', 'novel'], genres: const [], styles: ['noir']);
    expect(a.seen.last.queryParameters, {'formats': 'manga,novel', 'styles': 'noir'});
    await repo.catalog();
    expect(a.seen.last.queryParameters, isEmpty);
    await repo.saveTaste(4, TasteUpdate(step: OnboardingStep.at(3), partial: const Taste(formats: [FormatId.manga]), touched: {TasteField.formats}));
    expect(a.seen.last.method, 'PUT');
    expect(a.seen.last.path, '/profiles/4/taste');
    expect(a.seen.last.data, {'step': 3, 'formats': ['manga']});
    final t = await repo.getTaste(4);
    expect(t.isOk, isTrue);
    expect(t.value, isNull);
  });

  Future<ProviderContainer> box(Map<String, Object> initial) async {
    SharedPreferences.setMockInitialValues(initial);
    final prefs = await SharedPreferences.getInstance();
    return ProviderContainer(overrides: [sharedPrefsProvider.overrideWithValue(prefs)]);
  }

  test('draft round trip, touched-only body, corrupt blob', () async {
    final c = await box({});
    final s = c.read(onboardingStoreProvider);
    expect(s.readDraft().isEmpty, isTrue);
    final d = OnboardingDraft(taste: const Taste(genres: {'A': GenreMark.love, 'B': null}), touched: {TasteField.genres}, picks: const [3, 4]);
    await s.writeDraft(d);
    final back = s.readDraft();
    expect(back.taste.genres, {'A': GenreMark.love, 'B': null});
    expect(back.touched, {TasteField.genres});
    expect(back.picks, [3, 4]);
    expect(tasteBody(back, OnboardingStep.at(4)).toJson(), {
      'step': 4,
      'genres': {'A': 2, 'B': 0},
    });
    await s.clearDraft();
    expect(s.readDraft().isEmpty, isTrue);
  });

  test('pending done round trip', () async {
    final c = await box({});
    final s = c.read(onboardingStoreProvider);
    expect(s.readPending(), isNull);
    await s.writePending(const OnboardingDraft(taste: Taste(styles: [StyleId.noir]), touched: {TasteField.styles}));
    expect(s.readPending()!.toJson(), {
      'step': 'done',
      'styles': ['noir'],
    });
    await s.clearPending();
    expect(s.readPending(), isNull);
  });

  test('a corrupt blob reads as an empty draft', () async {
    final c = await box({'mm.onboarding.draft.device': '{nope'});
    expect(c.read(onboardingStoreProvider).readDraft().isEmpty, isTrue);
  });
}
