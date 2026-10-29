import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../core/lms_config.dart';
import '../core/route_classifier.dart';
import 'css_loader.dart';

/// Builds the one user-script that runs at the very start of every page.
class ScriptBuilder {
  ScriptBuilder._();

  static UnmodifiableListView<UserScript>? _cache;

  static Future<UnmodifiableListView<UserScript>> build() async {
    final cached = _cache;
    if (cached != null) return cached;

    final template = await rootBundle.loadString(LmsConfig.engineAsset);
    final css = await CssLoader.load();

    final payload = jsonEncode({
      'debug': kDebugMode,
      'base': RouteClassifier.base,
      'routes': RouteClassifier.rulesJson,
      'css': css,
    });

    // split/join = plain-text replace (no special characters to worry about)
    final source = template.split('__LMS_PAYLOAD__').join(payload);

    return _cache = UnmodifiableListView<UserScript>([
      UserScript(
        source: source,
        injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
        forMainFrameOnly: true,
      ),
    ]);
  }
}
