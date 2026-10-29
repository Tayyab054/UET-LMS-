import 'package:flutter/material.dart';

import 'core/lms_config.dart';
import 'views/lms_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const UetLmsApp());
}

class UetLmsApp extends StatelessWidget {
  const UetLmsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UET LMS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: LmsConfig.primary),
        scaffoldBackgroundColor: LmsConfig.pageBg,
      ),
      home: const LmsScreen(),
    );
  }
}
