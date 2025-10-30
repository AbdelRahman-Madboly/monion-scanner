// lib/screens/admin/recording_view.dart
// This file redirects to the proper recordings_screen.dart

import 'package:flutter/material.dart';
import 'recordings_screen.dart';

class RecordingView extends StatelessWidget {
  const RecordingView({super.key});

  @override
  Widget build(BuildContext context) {
    // Automatically redirect to the proper recordings screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const RecordingsScreen()),
      );
    });

    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}