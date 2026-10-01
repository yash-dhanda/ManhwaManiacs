import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/features/reader/models/reader_page.dart';

/// The image proxy's width parameter on a page URL (`w=240` for the scrub lens and the go-to thumbnail, `w=96` for the panel rows).
String proxiedPageUrl(String url, int width) {
  final u = Uri.tryParse(url);
  if (u == null || url.isEmpty) return url;
  return u.replace(queryParameters: {...u.queryParameters, 'w': '$width'}).toString();
}

/// A page thumbnail: the saved file when the chapter is on the device, else the proxied image; `#0B0B0F` until it lands.
class ReaderPageThumb extends StatelessWidget {
  const ReaderPageThumb({super.key, required this.page, this.width = 240});
  final ReaderPage? page;
  final int width;

  @override
  Widget build(BuildContext context) {
    final p = page;
    const ground = ColoredBox(color: Color(0xFF0B0B0F));
    if (p == null) return ground;
    final file = p.localFile;
    final Widget img = file != null
        ? Image.file(file, fit: BoxFit.cover, cacheWidth: width, errorBuilder: (_, __, ___) => ground)
        : p.imageUrl.isEmpty
            ? ground
            : Image.network(proxiedPageUrl(p.imageUrl, width), fit: BoxFit.cover, errorBuilder: (_, __, ___) => ground);
    return ClipRRect(borderRadius: BorderRadius.circular(8), child: Stack(fit: StackFit.expand, children: [ground, img]));
  }
}
