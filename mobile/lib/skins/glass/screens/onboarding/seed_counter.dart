/// "Your home has 7 titles to start with" (glass 8.7, step 6): the follows plus the kept seeds. Pure.
String seedCounterLine(int follows, int keptSeeds) {
  final n = follows + keptSeeds;
  return 'Your home has $n ${n == 1 ? 'title' : 'titles'} to start with';
}
