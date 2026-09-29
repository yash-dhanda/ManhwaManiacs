/// Pure decisions of the profile form (cinematic 8.6).
library;

enum EditionSaveKind { none, saveWithForm, confirmRestart }

class EditionSaveAction {
  const EditionSaveAction(this.kind, {this.value});
  final EditionSaveKind kind;
  final String? value;

  @override
  bool operator ==(Object other) => other is EditionSaveAction && other.kind == kind && other.value == value;
  @override
  int get hashCode => Object.hash(kind, value);
}

/// A new or non-active profile saves the edition with the form and applies it at the next pick;
/// the active profile with a changed edition saves the other fields first, then asks to restart.
EditionSaveAction decideEditionSave({
  required bool isActiveProfile,
  required String? before,
  required String? after,
  required bool glassAvailable,
}) {
  if (!glassAvailable || after == null) return const EditionSaveAction(EditionSaveKind.none);
  if (!isActiveProfile) return EditionSaveAction(EditionSaveKind.saveWithForm, value: after);
  if (before == after) return const EditionSaveAction(EditionSaveKind.none);
  return EditionSaveAction(EditionSaveKind.confirmRestart, value: after);
}

/// The name counter `12/30`.
String nameCounter(int length) => '$length/30';

/// The certificate's headline when the name is empty.
String certificateHeadline(String name) =>
    name.trim().isEmpty ? 'Show mature content on this profile?' : 'Show mature content on ${name.trim()}?';

/// Restart dialog body, with the downloads line when the queue is not empty.
String restartBody({required bool downloadsQueued}) =>
    'The app closes and reopens in the Glass edition, on this page.${downloadsQueued ? ' Downloads resume after the restart.' : ''}';

/// Where an avatar arrow key moves the selection (row-major grid, wraps at the ends).
int moveAvatar(int index, int count, {required bool forward}) => (index + (forward ? 1 : count - 1)) % count;
