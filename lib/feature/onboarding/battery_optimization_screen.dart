import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xelex_esp/core/pref_keys.dart';
import 'package:xelex_esp/core/theme/app_colors.dart';
import 'package:xelex_esp/service/foreground/athlete_foreground_service.dart';

class BatteryOptimizationScreen extends StatefulWidget {
  const BatteryOptimizationScreen({super.key});

  @override
  State<BatteryOptimizationScreen> createState() => _BatteryOptimizationScreenState();

  // Native (MainActivity) ka system-checks channel — background-restriction
  // detect karne ke liye.
  static const MethodChannel _sysChannel =
      MethodChannel('com.example.cl800/sdk_methods');

  /// App Info → Battery → "Restricted" state (Android 9+). Battery-optimization
  /// exemption se ALAG setting — koi API isse SET nahi kar sakti, sirf detect.
  /// true = user ne app ko background me restrict kiya hua hai.
  static Future<bool> isBackgroundRestricted() async {
    if (!Platform.isAndroid) return false;
    try {
      final r =
          (await _sysChannel.invokeMethod<bool>('isBackgroundRestricted')) ??
              false;
      debugPrint('[BATTERY] isBackgroundRestricted → $r');
      return r;
    } catch (e) {
      // MissingPluginException dikhe → native rebuild nahi hua.
      debugPrint('[BATTERY] isBackgroundRestricted FAILED → $e');
      return false; // API < 28 / unsupported → block mat karo
    }
  }

  static Future<void> showIfNeeded(BuildContext context) async {
    if (!Platform.isAndroid) return; // iOS: koi battery-opt concept nahi
    final ignoring = await FlutterForegroundTask.isIgnoringBatteryOptimizations;
    final restricted = await isBackgroundRestricted();
    final allowed = ignoring && !restricted; // dono chahiye
    debugPrint('[BATTERY] gate — ignoring=$ignoring restricted=$restricted '
        'allowed=$allowed (allowed=true → screen NAHI khulti)');
    if (!context.mounted) return;
    // Track: har check pe last-known FULL status persist karo.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PrefKeys.batteryOptGranted, allowed);
    if (allowed) return; // dono theek → koi block nahi
    if (!context.mounted) return;
    // HARD BLOCK: screen sirf tab pop hoti hai jab exemption ON aur background
    // restriction OFF — dono ho. One-time flag hata diya — har launch pe re-check.
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
  bool _bgRestricted = false;
  String _manufacturer = '';
  bool _busy = false;

  // Dono chahiye tabhi aage: exemption granted AND background restricted nahi.
  bool get _fullyAllowed => _ignoring && !_bgRestricted;

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
    final restricted = await BatteryOptimizationScreen.isBackgroundRestricted();
    if (!context.mounted) return;
    setState(() {
      _ignoring = ignoring;
      _bgRestricted = restricted;
    });
    // Track: user settings se laut ke aaya — full status update karo.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PrefKeys.batteryOptGranted, ignoring && !restricted);
  }

  Future<void> _load() async {
    final ignoring = await FlutterForegroundTask.isIgnoringBatteryOptimizations;
    final restricted = await BatteryOptimizationScreen.isBackgroundRestricted();
    String mfr = '';
    if (Platform.isAndroid) {
      final info = await DeviceInfoPlugin().androidInfo;
      mfr = info.manufacturer.toLowerCase();
    }
    if (!context.mounted) return;
    setState(() {
      _ignoring = ignoring;
      _bgRestricted = restricted;
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
      final restricted = await BatteryOptimizationScreen.isBackgroundRestricted();
      if (!context.mounted) return;
      setState(() {
        _ignoring = ignoring;
        _bgRestricted = restricted;
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(PrefKeys.batteryOptGranted, ignoring && !restricted);
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

  Future<void> _continue() async {
    // Safety: sirf tab pop karo jab dono theek ho — exemption ON + restriction
    // OFF (hard block).
    if (!_fullyAllowed) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PrefKeys.batteryOptGranted, true);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  /// Back button pe: screen ko app ke andar dismiss NAHI karte (hard block).
  /// Sirf exit-app confirmation dikhate hain — user ya to yahin ruke (grant
  /// kare) ya app se bahar nikal jaye. Hamesha `true` return karke event
  /// consume karte hain taaki shell ka BackButtonListener (GoRouter.of) na chale.
  Future<bool> _onBackPressed() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.exit_to_app, color: AppColors.primary),
            SizedBox(width: 8),
            Expanded(
              child: Text('Exit app?',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        content: const Text(
          'To keep sending your watch data while the screen is off, Sports IQ '
          'needs Battery Restriction turned OFF for this app.\n\n'
          'Without it, your live session data may not be saved. You can allow '
          'it now, or exit the app.',
          style: TextStyle(color: AppColors.subtext, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Stay & allow'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Exit app'),
          ),
        ],
      ),
    );
    if (shouldExit == true) {
      // App-exit: foreground service + BG isolate band karo, par server ko stop
      // mat bhejo (session in_progress rahe — recovery agli launch pe resume
      // karega). Idle me safe no-op. (Shell ke exit-flow jaisa hi.)
      await AthleteForegroundService.stopServiceKeepSession();
      await SystemNavigator.pop();
    }
    // Hamesha consume — back se screen kabhi app ke andar dismiss nahi hoti.
    return true;
  }

  @override
  Widget build(BuildContext context) {
    // HARD BLOCK: back button ko app ke apne idiom (BackButtonListener) se
    // handle karo. Ye screen baad me push hoti hai isliye iska listener pehle
    // fire hota hai aur shell ka BackButtonListener (jo GoRouter.of use karta
    // hai) chalta hi nahi — isse wo "null check operator on null" crash bhi
    // nahi aata. (PopScope yahan use nahi kar sakte — wo app ke BackButtonListener
    // se takra jaata hai.) Back pe screen andar-dismiss nahi hoti; sirf exit-app
    // dialog aata hai (grant kiye bina app me aage nahi ja sakte, sirf bahar).
    return BackButtonListener(
      onBackButtonPressed: _onBackPressed,
      child: Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.text,
        elevation: 0,
        automaticallyImplyLeading: false, // koi back arrow / Skip nahi
        title: const Text('Background access required'),
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
              // Background-restriction (App Info → Battery → "Restricted") — ye
              // battery-optimization se alag hai aur sirf manually theek hota
              // hai. Detect hone par hi dikhao; user Settings me "Unrestricted"
              // set kare to resume pe apne aap hat jaata hai.
              if (_bgRestricted) ...[
                const SizedBox(height: 12),
                _StepCard(
                  done: false,
                  title: 'Remove background restriction',
                  body: 'This app is set to "Restricted" in Battery settings. '
                      'Open Settings → Battery, and change it to "Unrestricted".',
                  buttonLabel: 'Open Settings',
                  onTap: _openAutoStart,
                ),
              ],
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
              // Step-by-step guide — jab tak dono theek na ho, user ko exact
              // steps dikhao ki settings me kaise enable kare.
              if (!_fullyAllowed) ...[
                const SizedBox(height: 16),
                _SettingsGuide(onOpenSettings: _openAutoStart),
              ],
              const SizedBox(height: 28),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  // Hard block: dono theek hone par hi aage — exemption ON aur
                  // background restriction OFF. Warna button disabled.
                  onPressed: _fullyAllowed ? _continue : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.border,
                    disabledForegroundColor: AppColors.subtext,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    _fullyAllowed ? 'Continue' : 'Allow access to continue',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
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

// ── Settings guide ─────────────────────────────────────────────────────────
// Step-by-step instructions ki OEM settings me kaise enable kare. Auto-start /
// "Restricted" ka koi grant-API nahi, isliye ye purely guidance hai — user ko
// exact taps dikhata hai. Har OEM me wording thodi alag ho sakti hai, isliye
// steps generic-but-clear rakhe hain.
class _SettingsGuide extends StatelessWidget {
  final VoidCallback onOpenSettings;
  const _SettingsGuide({required this.onOpenSettings});

  static const _steps = [
    'Tap "Open app settings" below — this opens this app\'s info page.',
    'Open "Battery" (or "Battery usage") and choose "Unrestricted" / "Allow background activity".',
    'Turn ON "Auto-start" / "Allow auto launch" if you see it.',
    'Come back here — the status updates automatically.',
  ];

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
            children: const [
              Icon(Icons.menu_book_outlined, size: 18, color: AppColors.primary),
              SizedBox(width: 8),
              Expanded(
                child: Text('How to enable it in Settings',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < _steps.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i == _steps.length - 1 ? 4 : 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                        color: AppColors.primary, shape: BoxShape.circle),
                    child: Text('${i + 1}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(_steps[i],
                        style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.subtext,
                            height: 1.4)),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onOpenSettings,
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('Open app settings'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
