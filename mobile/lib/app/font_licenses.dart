import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Package name -> licence asset, listed by Flutter's licence page.
const Map<String, String> kFontLicenseAssets = {
  'Bodoni Moda': 'assets/licenses/OFL-BodoniModa.txt',
  'Archivo': 'assets/licenses/OFL-Archivo.txt',
  'Newsreader': 'assets/licenses/OFL-Newsreader.txt',
  'IBM Plex Mono': 'assets/licenses/OFL-IBMPlexMono.txt',
  'Literata': 'assets/licenses/OFL-Literata.txt',
  'Source Serif 4': 'assets/licenses/OFL-SourceSerif4.txt',
  'Atkinson Hyperlegible Next': 'assets/licenses/OFL-AtkinsonHyperlegibleNext.txt',
  'Google Sans Flex': 'assets/licenses/OFL-GoogleSansFlex.txt',
  'Google Sans Code': 'assets/licenses/OFL-GoogleSansCode.txt',
  'Phosphor Icons': 'assets/licenses/MIT-Phosphor.txt',
};

/// Registers every bundled font's licence once (cinematic 3.1).
void registerFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    for (final e in kFontLicenseAssets.entries) {
      yield LicenseEntryWithLineBreaks([e.key], await rootBundle.loadString(e.value));
    }
  });
}
