import 'dart:js' as js;

void launchBrowser(String url) {
  js.context.callMethod('open', [url]);
}
