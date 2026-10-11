import 'package:flutter/material.dart';

import '../theme.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 3),
            const AppLogo(size: 84),
            const SizedBox(height: 24),
            const Text('Firebase Task Manager',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.dark)),
            const SizedBox(height: 8),
            const Text(
              'A simple task manager powered by Flutter\n& Firestore',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.muted, height: 1.4),
            ),
            const Spacer(flex: 3),
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
            ),
            const SizedBox(height: 8),
            const Text('Initializing app...',
                style: TextStyle(fontSize: 11, color: AppColors.hint)),
            const SizedBox(height: 28),
            const Text('FLUTTER  •  FIREBASE',
                style: TextStyle(fontSize: 10, letterSpacing: 1.5, color: AppColors.hint)),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
