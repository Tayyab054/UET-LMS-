import 'package:flutter/material.dart';

import '../../core/lms_config.dart';

class SplashView extends StatelessWidget {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      alignment: Alignment.center,
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(strokeWidth: 3, color: LmsConfig.primary),
          ),
          SizedBox(height: 18),
          Text(
            'LMS UET',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: LmsConfig.primary,
            ),
          ),
          SizedBox(height: 4),
          Text('Loading portal…', style: TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }
}
