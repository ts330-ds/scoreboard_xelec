import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xelex_esp/core/pref_keys.dart';
import 'package:xelex_esp/core/theme/app_colors.dart';

class BatteryOptimizationScreen extends StatefulWidget {
  const BatteryOptimizationScreen({super.key});

  @override
  State<BatteryOptimizationScreen> createState() => _BatteryOptimizationScreenState();

  static Future<void> showIfNeeded(BuildContext context) async {
    if (!Platform.isAndroid) return;
    final prefs = await SharedPreferences.getInstance();
    if (!context.mounted) return;
    if (prefs.getBool(PrefKeys.batteryOptPromptShown) ?? false) return;
    final ignoring = await FlutterForegroundTask.isIgnoringBatteryOptimizations;
    if (!context.mounted) return;
    if (ignoring) {
      await prefs.setBool(PrefKeys.batteryOptPromptShown, true);
      return;
    }
    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => const BatteryOptimizationScreen(),
        fullscreenDialog: true,
      ),
    );
  }
}

class _BatteryOptimizationScreenState extends State<BatteryOptimizationScreen>
    with WidgetsBindingObserver {
  bool _ignoring = false;
  String _manufacturer = '';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshIgnoringStatus();
    }
  }

  Future<void> _refreshIgnoringStatus() async {
    final ignoring = await FlutterForegroundTask.isIgnoringBatteryOptimizations;
    if (!context.mounted) return;
    setState(() => _ignoring = ignoring);
  }

  Future<void> _load() async {
    final ignoring = await FlutterForegroundTask.isIgnoringBatteryOptimizations;
    String mfr = '';
    if (Platform.isAndroid) {
      final info = await DeviceInfoPlugin().androidInfo;
      mfr = info.manufacturer.toLowerCase();
    }
    if (!context.mounted) return;
    setState(() {
      _ignoring = ignoring;
      _manufacturer = mfr;
    });
  }

  bool get _isAggressiveOem {
    const aggressive = ['xiaomi', 'redmi', 'poco', 'vivo', 'oppo', 'realme', 'oneplus', 'honor', 'huawei'];
    return aggressive.any(_manufacturer.contains);
  }

  Future<void> _requestIgnore() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await FlutterForegroundTask.requestIgnoreBatteryOptimization();
      await Future.delayed(const Duration(milliseconds: 400));
      final ignoring = await FlutterForegroundTask.isIgnoringBatteryOptimizations;
      if (!context.mounted) return;
      setState(() => _ignoring = ignoring);
    } catch (_) {
      // Some devices throw when the system dialog is dismissed or unsupported.
    } finally {
      if (context.mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openAutoStart() async {
    // No standard API exists for OEM-specific Auto-start toggles, so we
    // open the app-info screen — that's where Vivo/Xiaomi/Oppo expose
    // their custom "Auto-start", "Background activity" and
    // "Battery usage" entries.
    await openAppSettings();
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PrefKeys.batteryOptPromptShown, true);
    if (!context.mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.text,
        elevation: 0,
        title: const Text('Background Permission'),
        actions: [
          TextButton(
            onPressed: _finish,
            child: const Text('Skip', style: TextStyle(color: AppColors.subtext)),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.battery_saver, color: AppColors.primary, size: 36),
              ),
              const SizedBox(height: 20),
              const Text(
                'Keep monitoring while screen is off',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.text),
              ),
              const SizedBox(height: 8),
              const Text(
                'To send your watch data to the server every second, Android needs to be told that Sports IQ is allowed to run in the background.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.subtext, height: 1.45),
              ),
              const SizedBox(height: 24),
              _StepCard(
                done: _ignoring,
                title: 'Disable Battery Optimization',
                body: 'Tell Android not to restrict this app in the background.',
                buttonLabel: _ignoring ? 'Already allowed' : 'Allow',
                onTap: _ignoring || _busy ? null : _requestIgnore,
              ),
              if (_isAggressiveOem) ...[
                const SizedBox(height: 12),
                _StepCard(
                  done: false,
                  title: 'Enable Auto-Start (${_manufacturerLabel()})',
                  body: 'Your phone manufacturer applies extra restrictions. Open Settings and enable "Auto-start" / "Background activity", and set "Battery usage" to Unrestricted.',
                  buttonLabel: 'Open Settings',
                  onTap: _openAutoStart,
                ),
              ],
              const SizedBox(height: 28),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _finish,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Done', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _manufacturerLabel() {
    if (_manufacturer.isEmpty) return 'your phone';
    return _manufacturer[0].toUpperCase() + _manufacturer.substring(1);
  }
}

class _StepCard extends StatelessWidget {
  final bool done;
  final String title;
  final String body;
  final String buttonLabel;
  final VoidCallback? onTap;

  const _StepCard({
    required this.done,
    required this.title,
    required this.body,
    required this.buttonLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                done ? Icons.check_circle : Icons.radio_button_unchecked,
                color: done ? AppColors.success : AppColors.subtext,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(title,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.text)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 32),
            child: Text(body,
                style: const TextStyle(fontSize: 13, color: AppColors.subtext, height: 1.4)),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onTap,
              style: TextButton.styleFrom(
                backgroundColor: done ? AppColors.successBg : AppColors.primaryLight,
                foregroundColor: done ? AppColors.success : AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(buttonLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}
