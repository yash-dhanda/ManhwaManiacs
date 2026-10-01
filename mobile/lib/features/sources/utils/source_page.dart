import 'package:url_launcher/url_launcher.dart';

/// "Open source page in browser" (glass 8.12 ⋯ menu, cinematic 8.17 DETAILS): the series' page on its source site, in the system browser.
/// False when nothing could open it.
Future<bool> openSourcePage(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null || !uri.hasScheme) return false;
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}
