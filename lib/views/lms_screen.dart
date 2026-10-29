import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/lms_config.dart';
import '../services/script_builder.dart';
import 'widgets/error_view.dart';
import 'widgets/splash_view.dart';

class LmsScreen extends StatefulWidget {
  const LmsScreen({super.key});

  @override
  State<LmsScreen> createState() => _LmsScreenState();
}

class _LmsScreenState extends State<LmsScreen> {
  InAppWebViewController? _controller;
  PullToRefreshController? _pull;
  UnmodifiableListView<UserScript>? _scripts;
  Timer? _fallback;

  double _progress = 0;
  bool _ready = false;
  bool _hasError = false;

  static final InAppWebViewSettings _settings = InAppWebViewSettings(
    javaScriptEnabled: true,
    domStorageEnabled: true,
    databaseEnabled: true,
    cacheEnabled: true,
    cacheMode: CacheMode.LOAD_DEFAULT,
    useShouldOverrideUrlLoading: true,
    useOnDownloadStart: true,
    mediaPlaybackRequiresUserGesture: true,
    allowsInlineMediaPlayback: true,
    allowsBackForwardNavigationGestures: true,
    mixedContentMode: MixedContentMode.MIXED_CONTENT_NEVER_ALLOW,
    useHybridComposition: true,
    transparentBackground: false,
    supportZoom: false,
    builtInZoomControls: false,
    displayZoomControls: false,
    useWideViewPort: true,
    loadWithOverviewMode: false, // real mobile layout — media queries must match
    applicationNameForUserAgent: 'UETLMSApp/1.0',
    isInspectable: kDebugMode,   // chrome://inspect in debug builds
  );

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ));

    _pull = PullToRefreshController(
      settings: PullToRefreshSettings(color: LmsConfig.primary),
      onRefresh: _refresh,
    );

    // The WebView is built only AFTER the script bundle is ready, so the very
    // first page already gets the CSS (no race with evaluateJavascript).
    ScriptBuilder.build().then((s) {
      if (mounted) setState(() => _scripts = s);
    });

    _fallback = Timer(const Duration(seconds: 8), _markReady);
  }

  @override
  void dispose() {
    _fallback?.cancel();
    _pull?.dispose();
    super.dispose();
  }

  void _markReady() {
    if (mounted && !_ready) setState(() => _ready = true);
  }

  Future<void> _refresh() async {
    final c = _controller;
    if (c == null) return;
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await c.loadUrl(urlRequest: URLRequest(url: await c.getUrl()));
    } else {
      await c.reload();
    }
  }

  Future<void> _openExternal(Uri uri) async {
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('[LMS] Could not open $uri: $e');
    }
  }

  Future<NavigationActionPolicy> _onNavigate(
    InAppWebViewController controller,
    NavigationAction action,
  ) async {
    final webUri = action.request.url;
    if (webUri == null) return NavigationActionPolicy.ALLOW;
    final uri = webUri.uriValue;

    const inApp = {'about', 'data', 'blob', 'file', 'javascript'};
    if (inApp.contains(uri.scheme)) return NavigationActionPolicy.ALLOW;

    if (uri.scheme == 'http' || uri.scheme == 'https') {
      if (LmsConfig.isInternalHost(uri.host)) return NavigationActionPolicy.ALLOW;
      await _openExternal(uri);
      return NavigationActionPolicy.CANCEL;
    }

    await _openExternal(uri); // tel:, mailto:, whatsapp: …
    return NavigationActionPolicy.CANCEL;
  }

  Future<void> _onBack(bool didPop, Object? result) async {
    if (didPop) return;
    final c = _controller;
    if (c != null && await c.canGoBack()) {
      await c.goBack();
    } else {
      await SystemNavigator.pop();
    }
  }

  /// Debug builds only: print which CSS files the page actually received.
  Future<void> _printDebug(InAppWebViewController c) async {
    if (!kDebugMode) return;
    final r = await c.evaluateJavascript(
      source: 'JSON.stringify(window.__lmsDebug ? window.__lmsDebug() : "ENGINE NOT RUNNING")',
    );
    debugPrint('[LMS] page state: $r');
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _onBack,
      child: Scaffold(
        backgroundColor: LmsConfig.pageBg,
        body: SafeArea(
          child: Stack(
            children: [
              if (_scripts != null)
                AnimatedOpacity(
                  opacity: _ready ? 1 : 0,
                  duration: const Duration(milliseconds: 220),
                  child: InAppWebView(
                    initialUrlRequest: URLRequest(url: WebUri(LmsConfig.startUrl)),
                    initialUserScripts: _scripts,
                    initialSettings: _settings,
                    pullToRefreshController: _pull,
                    onWebViewCreated: (c) => _controller = c,
                    onLoadStart: (c, url) {
                      if (_hasError) setState(() => _hasError = false);
                    },
                    onProgressChanged: (c, p) {
                      final v = p / 100;
                      if ((v - _progress).abs() >= 0.05 || p == 100) {
                        setState(() => _progress = v);
                      }
                      if (p >= 70) _markReady();
                    },
                    onLoadStop: (c, url) {
                      _pull?.endRefreshing();
                      _markReady();
                      _printDebug(c);
                    },
                    onReceivedError: (c, request, error) {
                      if (request.isForMainFrame != true) return;
                      if (error.type == WebResourceErrorType.CANCELLED) return;
                      _pull?.endRefreshing();
                      setState(() => _hasError = true);
                    },
                    onConsoleMessage: (c, m) {
                      if (kDebugMode && m.message.startsWith('[LMS]')) {
                        debugPrint(m.message);
                      }
                    },
                    shouldOverrideUrlLoading: _onNavigate,
                    onDownloadStartRequest: (c, req) => _openExternal(req.url.uriValue),
                  ),
                ),
              if (_ready && _progress < 1)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(
                    value: _progress,
                    minHeight: 3,
                    color: LmsConfig.primary,
                    backgroundColor: Colors.transparent,
                  ),
                ),
              if (_hasError)
                ErrorView(onRetry: () {
                  setState(() => _hasError = false);
                  _controller?.reload();
                }),
              if (!_ready) const SplashView(),
            ],
          ),
        ),
      ),
    );
  }
}
