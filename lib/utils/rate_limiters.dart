import 'dart:async';
import 'package:flutter/foundation.dart';

/// A utility class for debouncing actions.
/// 
/// Debouncing ensures that a function is only executed after a certain amount 
/// of time has passed since it was last called. Useful for search bars, 
/// text input, or window resizing.
class Debouncer {
  final int milliseconds;
  Timer? _timer;

  Debouncer({required this.milliseconds});

  void run(VoidCallback action) {
    // Cancel the active timer if the function is called again.
    _timer?.cancel();
    // Start a new timer.
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }

  void cancel() {
    _timer?.cancel();
  }
}

/// A utility class for throttling actions.
/// 
/// Throttling ensures that a function is executed at most once in a specified 
/// time period. Useful for preventing double-clicks on buttons, scrolling 
/// events, or rapidly tapping a refresh button.
class Throttler {
  final int milliseconds;
  bool _isReady = true;
  Timer? _timer;

  Throttler({required this.milliseconds});

  void run(VoidCallback action) {
    if (_isReady) {
      // Execute immediately
      action();
      _isReady = false;
      
      // Prevent further executions until the timer completes
      _timer = Timer(Duration(milliseconds: milliseconds), () {
        _isReady = true;
      });
    }
  }

  void cancel() {
    _timer?.cancel();
    _isReady = true;
  }
}
