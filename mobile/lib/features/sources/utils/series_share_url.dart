/// The web app's origin when a build names it (`--dart-define=WEB_URL=...`).
const String _webUrl = String.fromEnvironment('WEB_URL');

/// The link a series' Share / Copy link hands out: [path] on the web app, never on the API host (which
/// answers a signed-out browser with a 401 JSON body). The web app sits on the API host minus its
/// `app.` label (`app.manhwamaniacs.xyz` -> `manhwamaniacs.xyz`) unless WEB_URL says otherwise.
String seriesShareUrl(String apiBase, String path) {
  if (_webUrl.isNotEmpty) return '${_webUrl.replaceFirst(RegExp(r'/+$'), '')}$path';
  final u = Uri.parse(apiBase.replaceFirst(RegExp(r'/api/?$'), ''));
  final host = u.host.startsWith('app.') ? u.host.substring(4) : u.host;
  return '${u.scheme}://$host${u.hasPort ? ':${u.port}' : ''}$path';
}
