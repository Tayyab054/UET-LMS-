import 'package:flutter/material.dart';

import '../../core/lms_config.dart';

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: LmsConfig.pageBg,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 56, color: LmsConfig.primary),
          const SizedBox(height: 16),
          const Text('No connection',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text('Check your internet and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try again'),
            style: FilledButton.styleFrom(
              backgroundColor: LmsConfig.primary,
              minimumSize: const Size(160, 48),
            ),
          ),
        ],
      ),
    );
  }
}
