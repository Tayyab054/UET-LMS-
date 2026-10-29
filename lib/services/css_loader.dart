import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../core/lms_config.dart';

/// Reads the bundled CSS once, minifies it and keeps it in memory.
class CssLoader {
  CssLoader._();

  static Map<String, String>? _cache;

  static Future<Map<String, String>> load() async {
    final cached = _cache;
    if (cached != null) return cached;

    final result = <String, String>{};
    await Future.wait(LmsConfig.cssFiles.map((name) async {
      try {
        final raw =
            await rootBundle.loadString('${LmsConfig.cssDir}/$name.css');
        result[name] = _minify(raw);
      } catch (e) {
        debugPrint('[LMS] CSS asset missing or unreadable: $name.css  ($e)');
      }
    }));

    if (!result.containsKey('global')) {
      debugPrint('[LMS] WARNING: global.css not loaded — check pubspec assets.');
    }
    debugPrint('[LMS] CSS loaded: ${result.keys.join(', ')}');
    return _cache = result;
  }

  static String _minify(String css) => css
      .replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
