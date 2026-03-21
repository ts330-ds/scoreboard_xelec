import 'package:flutter/material.dart';
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
          return Scaffold(
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
                        _gateStatusRow(),
                        const SizedBox(height: 16),
                        _infoCard(),
                      ],
                    ),
                  ),
                ],
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

  Widget _gateStatusRow() {
    return Row(children: [
      Expanded(
          child: _gateCard(
        icon: Icons.sensors,
        label: 'Master Gate',
        sublabel: 'Start Line',
        iconColor: _primary,
        iconBg: _primaryLight,
        statusLabel: 'Live',
        statusColor: _success,
        statusBg: const Color(0xFFDCFCE7),
        signal: 0.95,
        signalColor: _success,
      )),
      const SizedBox(width: 12),
      Expanded(
          child: _gateCard(
        icon: Icons.sensors_outlined,
        label: 'Slave Gate',
        sublabel: 'Finish Line',
        iconColor: _warning,
        iconBg: const Color(0xFFFEF3C7),
        statusLabel: 'OK',
        statusColor: _warning,
        statusBg: const Color(0xFFFEF3C7),
        signal: 0.72,
        signalColor: _warning,
      )),
    ]);
  }

  Widget _gateCard({
    required IconData icon,
    required String label,
    required String sublabel,
    required Color iconColor,
    required Color iconBg,
    required String statusLabel,
    required Color statusColor,
    required Color statusBg,
    required double signal,
    required Color signalColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: statusBg,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(statusLabel,
                  style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w700)),
            ),
          ]),
          const SizedBox(height: 10),
          Text(label,
              style: const TextStyle(
                  color: _text, fontSize: 13, fontWeight: FontWeight.w600)),
          Text(sublabel,
              style: const TextStyle(color: _subtext, fontSize: 11)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: signal,
              backgroundColor: const Color(0xFFF0F4F8),
              valueColor: AlwaysStoppedAnimation<Color>(signalColor),
              minHeight: 5,
            ),
          ),
        ],
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
