import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:xelex_esp/feature/timing_gates/ble_connection/presentation/cubit/timing_gate_bluetooth_cubit.dart';
import 'package:xelex_esp/feature/timing_gates/ble_connection/presentation/cubit/timing_gate_bluetooth_state.dart';
import 'package:xelex_esp/router/timing_gate_path.dart';

class TimingGateHomeMobile extends StatelessWidget {
  const TimingGateHomeMobile({super.key});

  static const _bg = Color(0xFFF4F6F9);
  static const _surface = Color(0xFFFFFFFF);
  static const _border = Color(0xFFDDE3EC);
  static const _primary = Color(0xFF1565C0);
  static const _primaryLight = Color(0xFFE3F2FD);
  static const _text = Color(0xFF1E2A3A);
  static const _subtext = Color(0xFF6B7A8D);
  static const _success = Color(0xFF16A34A);
  static const _warning = Color(0xFFD97706);
  static const _error = Color(0xFFDC2626);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TimingGateBleCubit, TimingGateBleState>(
        builder: (context, bleState) {
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: Colors.transparent,
            ),
            child: Scaffold(
          backgroundColor: _bg,
          body: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _header(context, bleState),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _startCard(context),
                        const SizedBox(height: 16),
                        _bluetoothCard(context, bleState),
                        const SizedBox(height: 16),
                        _resetCard(context, bleState),
                        const SizedBox(height: 16),
                        _infoCard(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          ),
        );
      },
    );   // BlocBuilder
  }

  Widget _header(BuildContext context, TimingGateBleState bleState) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        color: _surface,
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(children: [
        // Icon
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _primaryLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.timer_outlined, color: _primary, size: 22),
        ),
        const SizedBox(width: 12),

        // Title
        const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Timing Gates',
              style: TextStyle(
                  color: _text, fontSize: 18, fontWeight: FontWeight.w700)),
          Text('Sports IQ',
              style: TextStyle(color: _subtext, fontSize: 11)),
        ]),

        const Spacer(),

        // Connected: status + disconnect button ek column mein
        if (bleState.isConnected)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Device name + green dot
              Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.circle, color: _success, size: 8),
                const SizedBox(width: 5),
                Text(
                  bleState.connectedDeviceName.isNotEmpty
                      ? bleState.connectedDeviceName
                      : 'Connected',
                  style: const TextStyle(
                      color: _success,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              ]),
              const SizedBox(height: 4),
              // Disconnect button
              GestureDetector(
                onTap: () => _confirmDisconnect(context),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.bluetooth_disabled, color: _error, size: 12),
                    SizedBox(width: 4),
                    Text('Disconnect',
                        style: TextStyle(
                            color: _error,
                            fontSize: 10,
                            fontWeight: FontWeight.w600)),
                  ]),
                ),
              ),
            ],
          )
        else
          // Not connected: badge + Connect button
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Status
              const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.circle, color: _subtext, size: 8),
                SizedBox(width: 5),
                Text('Not Connected',
                    style: TextStyle(
                        color: _subtext,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ]),
              const SizedBox(height: 4),
              // Connect button — BLE screen pe le jayega
              GestureDetector(
                onTap: () => context.push(TimingGatePaths.timingGateBle),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _primaryLight,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.bluetooth, color: _primary, size: 12),
                    SizedBox(width: 4),
                    Text('Connect',
                        style: TextStyle(
                            color: _primary,
                            fontSize: 10,
                            fontWeight: FontWeight.w600)),
                  ]),
                ),
              ),
            ],
          ),
      ]),
    );
  }

  // Disconnect confirm dialog
  void _confirmDisconnect(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Disconnect?'),
        content: const Text('Are you sure you want to disconnect from the timing gate?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<TimingGateBleCubit>().disconnect();
            },
            style: TextButton.styleFrom(foregroundColor: _error),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
  }

  Widget _startCard(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(TimingGatePaths.timingGateSession),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _primary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Start New Test',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(
                  'Set up athletes, align gates, and run timing tests in 6 easy steps.',
                  style: TextStyle(
                      color: Colors.white.withAlpha(200),
                      fontSize: 12,
                      height: 1.5),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Begin Session',
                      style: TextStyle(
                          color: _primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          const Icon(Icons.play_circle_fill, color: Colors.white, size: 64),
        ]),
      ),
    );
  }


  // ── Bluetooth Status Card ──────────────────────────────────────────────

  Widget _bluetoothCard(BuildContext context, TimingGateBleState bleState) {
    // Decide icon, color, title, subtitle based on state
    final IconData icon;
    final Color iconColor;
    final Color iconBgColor;
    final String title;
    final String subtitle;
    final Widget action;

    if (bleState.isReconnecting) {
      // ── Reconnecting ──
      icon = Icons.bluetooth_searching;
      iconColor = _warning;
      iconBgColor = const Color(0xFFFEF3C7);
      title = 'Reconnecting...';
      subtitle =
          'Attempt ${bleState.reconnectAttempt} of ${TimingGateBleState.maxReconnectAttempts}';
      action = GestureDetector(
        onTap: () => context.read<TimingGateBleCubit>().cancelReconnect(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFFEE2E2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text('Cancel',
              style: TextStyle(
                  color: _error, fontSize: 12, fontWeight: FontWeight.w600)),
        ),
      );
    } else if (bleState.isConnected) {
      // ── Connected ──
      icon = Icons.bluetooth_connected;
      iconColor = _success;
      iconBgColor = const Color(0xFFDCFCE7);
      title = bleState.connectedDeviceName.isNotEmpty
          ? bleState.connectedDeviceName
          : 'Connected';
      final bars = bleState.signalBars;
      final signalLabel =
          bars >= 3 ? 'Excellent' : bars == 2 ? 'Good' : bars == 1 ? 'Weak' : 'No signal';
      subtitle = 'Signal: $signalLabel  •  ${bleState.connectedRssi} dBm';
      action = GestureDetector(
        onTap: () => _confirmDisconnect(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFFEE2E2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.bluetooth_disabled, color: _error, size: 14),
            SizedBox(width: 4),
            Text('Disconnect',
                style: TextStyle(
                    color: _error, fontSize: 12, fontWeight: FontWeight.w600)),
          ]),
        ),
      );
    } else {
      // ── Not Connected ──
      icon = Icons.bluetooth;
      iconColor = _subtext;
      iconBgColor = const Color(0xFFF1F5F9);
      title = 'No Device Connected';
      subtitle = bleState.status == 'Reconnect failed'
          ? 'Auto-reconnect failed. Please connect manually.'
          : 'Tap to scan and connect your timing gate.';
      action = GestureDetector(
        onTap: () => context.push(TimingGatePaths.timingGateBle),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _primaryLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.bluetooth_searching, color: _primary, size: 14),
            SizedBox(width: 4),
            Text('Connect',
                style: TextStyle(
                    color: _primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ]),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),

          // Title + Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(title,
                          style: const TextStyle(
                              color: _text,
                              fontSize: 14,
                              fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis),
                    ),
                    // Reconnecting indicator
                    if (bleState.isReconnecting) ...[
                      const SizedBox(width: 8),
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _warning,
                        ),
                      ),
                    ],
                    // Connected green dot
                    if (bleState.isConnected) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.circle, color: _success, size: 8),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: const TextStyle(color: _subtext, fontSize: 11)),
              ],
            ),
          ),

          // Action button
          const SizedBox(width: 8),
          action,
        ],
      ),
    );
  }

  // ── Reset Confirm Dialog ────────────────────────────────────────────────

  void _confirmReset(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Gate?'),
        content: const Text(
            'This will send a RESET command to the timing gate. Gate settings will be restored to default.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<TimingGateBleCubit>().sendCommand('RESET');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Reset command sent to gate'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: _error),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  // ── Reset Card ──────────────────────────────────────────────────────────

  Widget _resetCard(BuildContext context, TimingGateBleState bleState) {
    final isConnected = bleState.isConnected;

    return GestureDetector(
      onTap: isConnected
          ? () => _confirmReset(context)
          : null,
      child: Opacity(
        opacity: isConnected ? 1.0 : 0.4,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _border),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.restart_alt, color: _error, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Reset Timing Gate',
                        style: TextStyle(
                            color: _text,
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(
                        isConnected
                            ? 'Reset gate settings to default.'
                            : 'Connect to a device first.',
                        style: const TextStyle(color: _subtext, fontSize: 11)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Reset',
                    style: TextStyle(
                        color: _error,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Quick Guide',
              style: TextStyle(
                  color: _text, fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          _infoRow(Icons.looks_one_outlined, '1. Go to Tests tab and tap New Session'),
          _infoRow(Icons.looks_two_outlined, '2. Fill in test details and add athletes'),
          _infoRow(Icons.looks_3_outlined, '3. Align gates and select layout'),
          _infoRow(Icons.looks_4_outlined, '4. Run trials and view results'),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Icon(icon, color: _primary, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text,
              style: const TextStyle(color: _subtext, fontSize: 12, height: 1.4)),
        ),
      ]),
    );
  }
}
