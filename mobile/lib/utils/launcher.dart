import '../url_launcher_stub.dart' if (dart.library.js) '../url_launcher_web.dart';

void launchUrl(String url) {
  launchBrowser(url);
}
