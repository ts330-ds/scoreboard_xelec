import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:xelex_esp/feature/timing_gates/session/presentation/cubit/session/timing_session_cubit.dart';
import 'package:xelex_esp/feature/timing_gates/session/presentation/cubit/session/timing_session_state.dart';

// Step 1 — Test Info: session name, location, notes
// Mode selection is Step 0 (StepModeSelection)
class StepTestSetup extends StatefulWidget {
  const StepTestSetup({super.key});

  @override
  State<StepTestSetup> createState() => _StepTestSetupState();
}

class _StepTestSetupState extends State<StepTestSetup> {
  static const _surface = Color(0xFFFFFFFF);
  static const _primary = Color(0xFF1565C0);
  static const _text = Color(0xFF1E2A3A);
  static const _subtext = Color(0xFF6B7A8D);
  static const _border = Color(0xFFDDE3EC);

  late final TextEditingController _nameCtrl;
  late final TextEditingController _locationCtrl;
  late final TextEditingController _notesCtrl;

  bool _isFetchingLocation = false;

  @override
  void initState() {
    super.initState();
    final s = context.read<TimingSessionCubit>().state;
    _nameCtrl = TextEditingController(text: s.testName);
    _locationCtrl = TextEditingController(text: s.location);
    _notesCtrl = TextEditingController(text: s.notes);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _locationCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  // ── Location fetch ─────────────────────────────────────────────────────────

  Future<void> _fetchLocation() async {
    setState(() => _isFetchingLocation = true);

    try {
      // 1. Check if device location service is ON
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnackbar('Location services are turned off. Please enable GPS.');
        return;
      }

      // 2. Check runtime permission
      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        // Ask for permission
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnackbar('Location permission denied.');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        // Can't ask again — guide user to Settings
        _showPermissionDeniedDialog();
        return;
      }

      // 3. Get GPS coordinates (medium accuracy is fast enough)
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      // 4. Reverse geocode → human readable address
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isEmpty) {
        _showSnackbar('Could not determine location. Please type manually.');
        return;
      }

      final p = placemarks.first;

      // Build: "Sector 62, Noida, Uttar Pradesh"
      final parts = <String>[
        if (p.subLocality != null && p.subLocality!.isNotEmpty) p.subLocality!,
        if (p.locality != null && p.locality!.isNotEmpty) p.locality!,
        if (p.administrativeArea != null && p.administrativeArea!.isNotEmpty)
          p.administrativeArea!,
      ];

      final locationStr = parts.isNotEmpty ? parts.join(', ') : p.country ?? '';

      if (locationStr.isEmpty) {
        _showSnackbar('Could not determine location. Please type manually.');
        return;
      }

      _locationCtrl.text = locationStr;
      if (mounted) {
        context.read<TimingSessionCubit>().updateLocation(locationStr);
      }
    } on LocationServiceDisabledException {
      _showSnackbar('Location services are turned off. Please enable GPS.');
    } on PermissionDeniedException {
      _showSnackbar('Location permission denied.');
    } catch (_) {
      _showSnackbar('Could not fetch location. Please type manually.');
    } finally {
      if (mounted) setState(() => _isFetchingLocation = false);
    }
  }

  void _showSnackbar(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showPermissionDeniedDialog() {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Location Permission Required',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Location permission has been permanently denied.\n\n'
          'To auto-fill venue location, please enable it in your device Settings.',
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              Geolocator.openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TimingSessionCubit, TimingSessionState>(
      builder: (context, state) {
        final cubit = context.read<TimingSessionCubit>();
        return Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  // Mode summary chip (read-only — already selected in Step 0)
                  if (state.modeLabel.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        state.modeLabel,
                        style: const TextStyle(
                            color: _primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13),
                      ),
                    ),
                  const SizedBox(height: 20),
                  _field(
                    label: 'Session Name',
                    hint: 'e.g. Sprint 20m — Morning Session',
                    controller: _nameCtrl,
                    onChanged: cubit.updateTestName,
                  ),
                  const SizedBox(height: 16),
                  _locationField(cubit),
                  const SizedBox(height: 16),
                  _field(
                    label: 'Notes (optional)',
                    hint: 'Any additional notes...',
                    controller: _notesCtrl,
                    onChanged: cubit.updateNotes,
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            _buildFooter(context),
          ],
        );
      },
    );
  }

  // ── Location field (with auto-fetch button) ────────────────────────────────

  Widget _locationField(TimingSessionCubit cubit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Location',
              style: TextStyle(
                  color: _text, fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 6),
            const Text(
              '(optional)',
              style: TextStyle(color: _subtext, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _border),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _locationCtrl,
                  onChanged: cubit.updateLocation,
                  style: const TextStyle(color: _text, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'e.g. Jawaharlal Nehru Stadium',
                    hintStyle: TextStyle(color: _subtext),
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ),
              // Auto-fetch button
              _isFetchingLocation
                  ? const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(_primary),
                        ),
                      ),
                    )
                  : Tooltip(
                      message: 'Auto-detect location',
                      child: InkWell(
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(10),
                          bottomRight: Radius.circular(10),
                        ),
                        onTap: _fetchLocation,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          child: const Icon(Icons.my_location,
                              color: _primary, size: 20),
                        ),
                      ),
                    ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Tap 📍 to auto-fill from GPS — you can edit it after',
          style: TextStyle(color: _subtext, fontSize: 11),
        ),
      ],
    );
  }

  // ── Generic field ──────────────────────────────────────────────────────────

  Widget _field({
    required String label,
    required String hint,
    required TextEditingController controller,
    required void Function(String) onChanged,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: _text, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _border),
          ),
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            maxLines: maxLines,
            style: const TextStyle(color: _text, fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: _subtext),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  // ── Footer ─────────────────────────────────────────────────────────────────

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      decoration: const BoxDecoration(
        color: _surface,
        border: Border(top: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => context.read<TimingSessionCubit>().prevStep(),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: _border),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Back', style: TextStyle(color: _text)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: () => context.read<TimingSessionCubit>().nextStep(),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Next →'),
            ),
          ),
        ],
      ),
    );
  }
}
