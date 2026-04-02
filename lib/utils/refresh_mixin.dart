import 'dart:async';
import 'package:flutter/widgets.dart';

/// Interval for periodic refresh so Django admin changes show in the app.
const Duration kDataRefreshInterval = Duration(seconds: 30);

/// Observer that reacts to app lifecycle and forwards to callbacks.
class _ResumeObserver with WidgetsBindingObserver {
  _ResumeObserver({required this.onResume, required this.onPause});
  final VoidCallback onResume;
  final VoidCallback onPause;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) onResume();
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) onPause();
  }
}

/// Mixin that runs [onRefresh] periodically and when app resumes.
/// Use so data updated in Django admin appears without restarting the app.
mixin PeriodicRefreshMixin<T extends StatefulWidget> on State<T> {
  Timer? _refreshTimer;
  late final WidgetsBindingObserver _observer = _ResumeObserver(
    onResume: () {
      onRefresh();
      _startRefreshTimer();
    },
    onPause: () => _refreshTimer?.cancel(),
  );

  /// Override: call your load method (e.g. _loadAppointments).
  Future<void> onRefresh();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(_observer);
    _startRefreshTimer();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(_observer);
    super.dispose();
  }

  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(kDataRefreshInterval, (_) {
      if (mounted) onRefresh();
    });
  }
}
