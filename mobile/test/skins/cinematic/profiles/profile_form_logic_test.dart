import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/profiles/profile_form_logic.dart';

void main() {
  EditionSaveAction d({required bool active, String? before, String? after, bool glass = true}) =>
      decideEditionSave(isActiveProfile: active, before: before, after: after, glassAvailable: glass);

  test('nothing while glass is unavailable or no edition is chosen', () {
    expect(d(active: true, before: 'cinematic', after: 'glass', glass: false).kind, EditionSaveKind.none);
    expect(d(active: false).kind, EditionSaveKind.none);
  });

  test('a new or non-active profile saves with the form', () {
    final a = d(active: false, before: 'cinematic', after: 'glass');
    expect(a.kind, EditionSaveKind.saveWithForm);
    expect(a.value, 'glass');
  });

  test('the active profile confirms a restart only when the edition changed', () {
    expect(d(active: true, before: 'cinematic', after: 'glass').kind, EditionSaveKind.confirmRestart);
    expect(d(active: true, before: 'glass', after: 'glass').kind, EditionSaveKind.none);
  });

  test('strings and avatar movement', () {
    expect(nameCounter(12), '12/30');
    expect(certificateHeadline(''), 'Show mature content on this profile?');
    expect(certificateHeadline(' Yash '), 'Show mature content on Yash?');
    expect(restartBody(downloadsQueued: true), endsWith('Downloads resume after the restart.'));
    expect(restartBody(downloadsQueued: false), isNot(contains('Downloads')));
    expect(moveAvatar(11, 12, forward: true), 0);
    expect(moveAvatar(0, 12, forward: false), 11);
  });
}
