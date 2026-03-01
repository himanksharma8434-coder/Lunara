// lib/screens/app_entry_checker.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cycle_provider.dart';
import 'body_metrics_screen.dart';
import 'main_screen.dart';

class AppEntryChecker extends StatelessWidget {
  const AppEntryChecker({super.key});

  @override
  Widget build(BuildContext context) {
    final cycleProvider = Provider.of<CycleProvider>(context);

    // Check if body metrics are already completed
    if (cycleProvider.bodyMetricsCompleted) {
      return const MainScreen();
    } else {
      return const BodyMetricsScreen();
    }
  }
}
