import 'package:flutter/material.dart';

/// Every app-wide constant lives here.
class LmsConfig {
  LmsConfig._();

  static const String startUrl = 'https://lms.uet.edu.pk/web/login';
  static const String rootDomain = 'uet.edu.pk';

  static const String cssDir = 'assets/css';
  static const String engineAsset = 'assets/js/lms_engine.js';

  /// File stems inside assets/css/ (name.css). Missing files are skipped
  /// with a debug warning instead of breaking everything.
  static const List<String> cssFiles = [
    'global',
    'login',
    'auth',
    'home',
    'dashboard',
    'downloads',
    'support',
    'verifications',
    'blog',
  ];

  static const Color primary = Color(0xFF0056B3);
  static const Color pageBg = Color(0xFFF4F6F9);

  static bool isInternalHost(String host) =>
      host == rootDomain || host.endsWith('.$rootDomain');
}
