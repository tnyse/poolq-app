// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:js_util' as js_util;

bool get isWebStandalone {
  final standaloneMedia =
      html.window.matchMedia('(display-mode: standalone)').matches;
  final iosStandalone =
      js_util.getProperty(html.window.navigator, 'standalone') == true;
  return standaloneMedia || iosStandalone;
}

bool get isIosWebBrowser {
  final ua = html.window.navigator.userAgent.toLowerCase();
  final platform = (html.window.navigator.platform ?? '').toLowerCase();
  final iPadOsDesktop =
      platform == 'macintel' && (html.window.navigator.maxTouchPoints ?? 0) > 1;
  return ua.contains('iphone') ||
      ua.contains('ipad') ||
      ua.contains('ipod') ||
      iPadOsDesktop;
}

bool get isAndroidWebBrowser {
  final ua = html.window.navigator.userAgent.toLowerCase();
  return ua.contains('android');
}
