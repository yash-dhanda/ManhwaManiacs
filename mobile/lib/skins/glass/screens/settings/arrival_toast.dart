/// Whether the Glass side shows "Switched to Glass" + Undo on arrival (glass 8.25.2 step 7): the skin it came from is Cinematic and
/// the switch is less than 10 s old. [t0Ms] is `mm.skin.t0`; the boot timing log consumes that key at the first frame, so a null
/// means "already consumed", which is fresh by construction (the `from` key is cleared after it shows).
bool glassArrivalToastDue(String? from, int? t0Ms, DateTime now) {
  if (from != 'cinematic') return false;
  if (t0Ms == null) return true;
  final age = now.millisecondsSinceEpoch - t0Ms;
  return age >= 0 && age < 10000;
}
