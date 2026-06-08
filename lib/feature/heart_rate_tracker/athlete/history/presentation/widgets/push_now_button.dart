import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/core/theme/app_colors.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/heart_rate_bluetooth/cubit/heart_ble_cubit.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/heart_rate_bluetooth/cubit/push_status_event.dart';

class PushNowButton extends StatefulWidget {
  final VoidCallback? onPushComplete;
  const PushNowButton({super.key, this.onPushComplete});

  @override
  State<PushNowButton> createState() => _PushNowButtonState();
}

class _PushNowButtonState extends State<PushNowButton> {
  bool _pushing = false;
  StreamSubscription<PushStatusEvent>? _eventsSub;

  @override
  void initState() {
    super.initState();
    _eventsSub =
        context.read<HeartBleCubit>().pushEvents.listen(_onPushEvent);
  }

  @override
  void dispose() {
    _eventsSub?.cancel();
    super.dispose();
  }

  void _onPushEvent(PushStatusEvent event) {
    if (!mounted) return;

    String message;
    Color bg = AppColors.primary;
    Duration duration = const Duration(seconds: 3);
    bool stillPushing = true;

    switch (event) {
      case PushAlreadyInFlight():
        message = 'Already pushing… please wait';
        bg = AppColors.warning;
        stillPushing = true;
      case PushPreparing():
        message = 'Preparing data…';
        stillPushing = true;
        duration = const Duration(seconds: 2);
      case PushAnonymous():
        message = 'Not logged in — please sign in again';
        bg = AppColors.error;
        stillPushing = false;
      case PushNothingNew():
        message = 'Nothing new to push — already up to date';
        bg = AppColors.success;
        stillPushing = false;
      case PushCooldownActive(:final minutesRemaining):
        message =
            'Pushed recently — try again in $minutesRemaining min';
        bg = AppColors.warning;
        stillPushing = false;
      case PushMissingAuth():
        message = 'Auth missing — please log in again';
        bg = AppColors.error;
        stillPushing = false;
      case PushConnecting():
        message = 'Connecting to server…';
        stillPushing = true;
        duration = const Duration(seconds: 2);
      case PushUploading(:final hrCount, :final rrCount, :final sleepCount):
        final parts = <String>[
          if (hrCount > 0) '$hrCount HR',
          if (rrCount > 0) '$rrCount RR',
          if (sleepCount > 0) '$sleepCount sleep',
        ];
        message = 'Uploading ${parts.join(' • ')}…';
        stillPushing = true;
        duration = const Duration(seconds: 3);
      case PushSucceeded():
        message = '✓ Data saved on server';
        bg = AppColors.success;
        stillPushing = false;
      case PushFailed(message: final m):
        message = 'Server error: $m';
        bg = AppColors.error;
        stillPushing = false;
      case PushAuthFailed(message: final m):
        message = 'Auth rejected: $m';
        bg = AppColors.error;
        stillPushing = false;
      case PushTimedOut():
        message = 'Timed out — no response from server';
        bg = AppColors.error;
        stillPushing = false;
      case PushDisconnected():
        message = 'Connection dropped — try again';
        bg = AppColors.error;
        stillPushing = false;
      case PushBuildFailed(message: final m):
        message = 'Could not build payload: $m';
        bg = AppColors.error;
        stillPushing = false;
      case PushNotConnected():
        message = 'Connect device first';
        bg = AppColors.error;
        stillPushing = false;
      case PushPolling():
        message = 'Processing on server…';
        stillPushing = true;
        // Polling 60s tak chal sakti hai — snackbar tab tak dikhe
        duration = const Duration(seconds: 60);
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: bg,
        duration: duration,
        behavior: SnackBarBehavior.floating,
      ));

    if (_pushing != stillPushing) {
      setState(() => _pushing = stillPushing);
      if (!stillPushing) widget.onPushComplete?.call();
    }
  }

  Future<void> _onPush() async {
    if (_pushing) return;
    setState(() => _pushing = true);
    try {
      await context.read<HeartBleCubit>().syncAndPush();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Push failed: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() => _pushing = false);
      }
    }
    // Safety: if no PushStatusEvent arrived to reset _pushing, reset after timeout
    // V3 polling can take up to 60s — keep safety timeout above that
    Future.delayed(const Duration(seconds: 75), () {
      if (mounted && _pushing) {
        setState(() => _pushing = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _pushing ? null : _onPush,
          icon: _pushing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
              : const Icon(Icons.cloud_upload_outlined, size: 18),
          label: Text(_pushing ? "Pushing…" : "Push to Server Now"),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            textStyle: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.3),
          ),
        ),
      ),
    );
  }
}
