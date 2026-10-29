/// Which CSS files belong to which page.
///
/// IMPORTANT: [base] is ALWAYS applied. The page files depend on the design
/// tokens (--uet-*) defined in global.css, so a page file loaded on its own
/// would render with every var() undefined.
class RouteRule {
  const RouteRule(this.pattern, this.files);

  /// JavaScript-compatible regular expression, tested against location.pathname.
  final String pattern;
  final List<String> files;

  Map<String, Object> toJson() => {'p': pattern, 'files': files};
}

class RouteClassifier {
  RouteClassifier._();

  static const List<String> base = ['global'];

  /// First matching rule wins — keep specific rules above general ones.
  static const List<RouteRule> rules = [
    RouteRule(r'^/web/(login|signup|reset_password)', ['login', 'auth']),
    RouteRule(r'/(verify|verification|alumni)', ['verifications']),
    RouteRule(r'/(downloads?|attachment)', ['downloads']),
    RouteRule(r'^/(my(/|$)|home|$)', ['home', 'dashboard']),
    RouteRule(r'/(support|contactus|helpdesk|help)(/|$)', ['support']),
    RouteRule(r'^/(blog|forum)(/|$)', ['blog']),
  ];

  static List<Map<String, Object>> get rulesJson =>
      rules.map((r) => r.toJson()).toList();

  /// Dart-side twin of the JS logic — handy for unit tests.
  static List<String> filesFor(String url) {
    final path = Uri.parse(url).path.toLowerCase();
    for (final r in rules) {
      if (RegExp(r.pattern).hasMatch(path)) return [...base, ...r.files];
    }
    return List.of(base);
  }
}
