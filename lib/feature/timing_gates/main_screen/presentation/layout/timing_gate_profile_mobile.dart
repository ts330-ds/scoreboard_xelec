import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:xelex_esp/feature/timing_gates/profile/data/model/timing_gate_profile_model.dart';
import 'package:xelex_esp/feature/timing_gates/profile/presentation/cubit/profile_cubit.dart';
import 'package:xelex_esp/feature/timing_gates/profile/presentation/cubit/profile_state.dart';
import 'package:go_router/go_router.dart';
import 'package:xelex_esp/router/app_path.dart';

class TimingGateProfileMobile extends StatelessWidget {
  const TimingGateProfileMobile({super.key});

  static const _bg = Color(0xFFF4F6F9);
  static const _surface = Color(0xFFFFFFFF);
  static const _border = Color(0xFFDDE3EC);
  static const _primary = Color(0xFF1565C0);
  static const _primaryLight = Color(0xFFE3F2FD);
  static const _text = Color(0xFF1E2A3A);
  static const _subtext = Color(0xFF6B7A8D);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: _bg,
          body: SafeArea(child: _buildBody(context, state)),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, ProfileState state) {
    if (state is ProfileLoading || state is ProfileSaving) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state is ProfileLoaded) {
      return _ProfileCard(
        profile: state.profile,
        onEdit: () => context.read<ProfileCubit>().deleteProfile(),
      );
    }
    return _SetupForm(onSave: (p) => context.read<ProfileCubit>().saveProfile(p));
  }
}

// ── Setup Form ────────────────────────────────────────────────────────────────

class _SetupForm extends StatefulWidget {
  final ValueChanged<TimingGateProfileModel> onSave;
  const _SetupForm({required this.onSave});

  @override
  State<_SetupForm> createState() => _SetupFormState();
}

class _SetupFormState extends State<_SetupForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl    = TextEditingController();
  final _orgCtrl     = TextEditingController();
  final _sportCtrl   = TextEditingController();
  final _heightCtrl  = TextEditingController(); // cm value OR feet value
  final _inchesCtrl  = TextEditingController(); // inches part (only when unit == 'in')
  final _weightCtrl  = TextEditingController();

  ProfileRole _role = ProfileRole.coach;
  DateTime? _dob;
  String _heightUnit = 'cm';
  String _weightUnit = 'kg';

  static const _surface      = TimingGateProfileMobile._surface;
  static const _border       = TimingGateProfileMobile._border;
  static const _primary      = TimingGateProfileMobile._primary;
  static const _primaryLight = TimingGateProfileMobile._primaryLight;
  static const _text         = TimingGateProfileMobile._text;
  static const _subtext      = TimingGateProfileMobile._subtext;
  static const _error        = Color(0xFFDC2626);

  @override
  void dispose() {
    _nameCtrl.dispose();
    _orgCtrl.dispose();
    _sportCtrl.dispose();
    _heightCtrl.dispose();
    _inchesCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(now.year - 20),
      firstDate: DateTime(now.year - 100),
      lastDate: now,
      helpText: 'Select Date of Birth',
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: _primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dob = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    widget.onSave(TimingGateProfileModel(
      name:         _nameCtrl.text.trim(),
      role:         _role,
      organization: _role == ProfileRole.coach  ? _orgCtrl.text.trim()   : null,
      sport:        _role == ProfileRole.athlete ? _sportCtrl.text.trim() : null,
      height:       _computeHeight(),
      heightUnit:   _heightUnit,
      weight:       _weightCtrl.text.isNotEmpty ? double.tryParse(_weightCtrl.text) : null,
      weightUnit:   _weightUnit,
      dateOfBirth:  _dob,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header card ─────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: _primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.person_add, color: _primary, size: 24),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Setup Your Profile',
                            style: TextStyle(color: _text, fontSize: 18, fontWeight: FontWeight.w700)),
                        SizedBox(height: 2),
                        Text('This will appear on session reports',
                            style: TextStyle(color: _subtext, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Full Name ────────────────────────────────────────────────────
            _label('Full Name *'),
            const SizedBox(height: 8),
            _textField(
              controller: _nameCtrl,
              hint: 'Enter your name',
              icon: Icons.person_outline,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Name is required';
                if (v.trim().length < 2) return 'Name must be at least 2 characters';
                return null;
              },
            ),
            const SizedBox(height: 20),

            // ── Role selection ───────────────────────────────────────────────
            _label('Your Role *'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _roleCard(ProfileRole.coach, Icons.sports, 'Coach')),
                const SizedBox(width: 12),
                Expanded(child: _roleCard(ProfileRole.athlete, Icons.directions_run, 'Athlete')),
              ],
            ),
            const SizedBox(height: 20),

            // ── Conditional: Org / Sport ─────────────────────────────────────
            if (_role == ProfileRole.coach) ...[
              _label('Organization'),
              const SizedBox(height: 8),
              _textField(
                controller: _orgCtrl,
                hint: 'Club, school, or team name',
                icon: Icons.business_outlined,
              ),
            ] else ...[
              _label('Sport / Discipline'),
              const SizedBox(height: 8),
              _textField(
                controller: _sportCtrl,
                hint: 'e.g. Athletics, Football',
                icon: Icons.sports_soccer_outlined,
              ),
            ],
            const SizedBox(height: 20),

            // ── Physical info ────────────────────────────────────────────────
            _label('Physical Information'),
            const SizedBox(height: 8),
            _buildHeightField(),
            const SizedBox(height: 12),
            _measureField(
              controller: _weightCtrl,
              hint: _weightUnit == 'kg' ? 'e.g. 70' : 'e.g. 154',
              icon: Icons.monitor_weight_outlined,
              unit: _weightUnit,
              units: const ['kg', 'lb'],
              onUnitChanged: (u) => setState(() {
                _weightUnit = u;
                _weightCtrl.clear();
              }),
              validator: (v) {
                if (v == null || v.isEmpty) return null;
                final val = double.tryParse(v);
                if (val == null) return 'Invalid number';
                if (_weightUnit == 'kg' && (val < 20 || val > 300)) return '20–300 kg';
                if (_weightUnit == 'lb' && (val < 44 || val > 660)) return '44–660 lb';
                return null;
              },
            ),
            const SizedBox(height: 20),

            // ── Date of Birth ────────────────────────────────────────────────
            _label('Date of Birth'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickDob,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.cake_outlined, color: _subtext, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _dob != null
                            ? DateFormat('dd MMM yyyy').format(_dob!)
                            : 'Select date of birth',
                        style: TextStyle(
                          color: _dob != null ? _text : _subtext,
                          fontSize: _dob != null ? 15 : 14,
                        ),
                      ),
                    ),
                    if (_dob != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _primaryLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_age(_dob!)} yrs',
                          style: const TextStyle(color: _primary, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ] else
                      const Icon(Icons.calendar_today_outlined, color: _subtext, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // ── Save button ──────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('Save Profile',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 12),

            // ── Switch Device ────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => context.go(AppPaths.featureSelection),
                icon: const Icon(Icons.devices, size: 18),
                label: const Text('Switch Device',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  int _age(DateTime dob) {
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) age--;
    return age;
  }

  Widget _label(String text) {
    return Text(text,
        style: const TextStyle(color: _text, fontSize: 14, fontWeight: FontWeight.w600));
  }

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      style: const TextStyle(color: _text, fontSize: 15),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _subtext, fontSize: 14),
        prefixIcon: Icon(icon, color: _subtext, size: 20),
        filled: true,
        fillColor: _surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _error, width: 2),
        ),
        errorStyle: const TextStyle(color: _error, fontSize: 11),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _roleCard(ProfileRole role, IconData icon, String label) {
    final selected = _role == role;
    return GestureDetector(
      onTap: () => setState(() => _role = role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: selected ? _primaryLight : _surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? _primary : _border, width: selected ? 2 : 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? _primary : _subtext, size: 28),
            const SizedBox(height: 8),
            Text(label,
                style: TextStyle(
                  color: selected ? _primary : _text,
                  fontSize: 15,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                )),
          ],
        ),
      ),
    );
  }

  /// Returns total inches when unit=='in', else cm value
  double? _computeHeight() {
    if (_heightCtrl.text.isEmpty) return null;
    if (_heightUnit == 'cm') return double.tryParse(_heightCtrl.text);
    // feet + inches → total inches stored
    final ft = double.tryParse(_heightCtrl.text) ?? 0;
    final inch = double.tryParse(_inchesCtrl.text) ?? 0;
    return ft * 12 + inch;
  }

  Widget _buildHeightField() {
    if (_heightUnit == 'cm') {
      return _measureField(
        controller: _heightCtrl,
        hint: 'e.g. 175',
        icon: Icons.height,
        unit: 'cm',
        units: const ['cm', 'in'],
        onUnitChanged: (u) => setState(() {
          _heightUnit = u;
          _heightCtrl.clear();
          _inchesCtrl.clear();
        }),
        validator: (v) {
          if (v == null || v.isEmpty) return null;
          final val = double.tryParse(v);
          if (val == null) return 'Invalid number';
          if (val < 50 || val > 250) return '50–250 cm';
          return null;
        },
      );
    }

    // ── Inches mode: two fields (ft + in) side by side ──────────────────────
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Feet field
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _heightCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                autovalidateMode: AutovalidateMode.onUserInteraction,
                style: const TextStyle(color: _text, fontSize: 15),
                validator: (v) {
                  if (v == null || v.isEmpty) return null;
                  final val = int.tryParse(v);
                  if (val == null) return 'Invalid';
                  if (val < 1 || val > 8) return '1–8 ft';
                  return null;
                },
                decoration: InputDecoration(
                  hintText: 'Feet',
                  hintStyle: const TextStyle(color: _subtext, fontSize: 14),
                  prefixIcon: const Icon(Icons.height, color: _subtext, size: 20),
                  suffixText: 'ft',
                  suffixStyle: const TextStyle(color: _primary, fontWeight: FontWeight.w700),
                  filled: true,
                  fillColor: _surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _primary, width: 2)),
                  errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _error)),
                  focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _error, width: 2)),
                  errorStyle: const TextStyle(color: _error, fontSize: 11),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Inches field
            Expanded(
              flex: 3,
              child: TextFormField(
                controller: _inchesCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d{0,2}\.?\d{0,1}'))],
                autovalidateMode: AutovalidateMode.onUserInteraction,
                style: const TextStyle(color: _text, fontSize: 15),
                validator: (v) {
                  if (v == null || v.isEmpty) return null;
                  final val = double.tryParse(v);
                  if (val == null) return 'Invalid';
                  if (val < 0 || val >= 12) return '0–11.9 in';
                  return null;
                },
                decoration: InputDecoration(
                  hintText: 'Inches',
                  hintStyle: const TextStyle(color: _subtext, fontSize: 14),
                  suffixIcon: _unitToggle('in', const ['cm', 'in'], (u) => setState(() {
                    _heightUnit = u;
                    _heightCtrl.clear();
                    _inchesCtrl.clear();
                  })),
                  filled: true,
                  fillColor: _surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _primary, width: 2)),
                  errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _error)),
                  focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _error, width: 2)),
                  errorStyle: const TextStyle(color: _error, fontSize: 11),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _unitToggle(String current, List<String> units, ValueChanged<String> onChanged) {
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 6, 8, 6),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: _primaryLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _primary.withValues(alpha: 0.3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: current,
          isDense: true,
          icon: const Icon(Icons.arrow_drop_down, color: _primary, size: 18),
          style: const TextStyle(color: _primary, fontSize: 13, fontWeight: FontWeight.w700),
          items: units.map((u) => DropdownMenuItem(
            value: u,
            child: Text(u, style: const TextStyle(color: _primary, fontSize: 13, fontWeight: FontWeight.w700)),
          )).toList(),
          onChanged: (v) { if (v != null) onChanged(v); },
        ),
      ),
    );
  }

  /// Text field with an inline unit dropdown on the right
  Widget _measureField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required String unit,
    required List<String> units,
    required ValueChanged<String> onUnitChanged,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d{0,4}\.?\d{0,1}'))],
      validator: validator,
      style: const TextStyle(color: _text, fontSize: 15),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _subtext, fontSize: 14),
        prefixIcon: Icon(icon, color: _subtext, size: 20),
        // Unit dropdown embedded as suffix
        suffixIcon: Container(
          margin: const EdgeInsets.fromLTRB(0, 6, 8, 6),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: _primaryLight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _primary.withValues(alpha: 0.3)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: unit,
              isDense: true,
              icon: const Icon(Icons.arrow_drop_down, color: _primary, size: 18),
              style: const TextStyle(color: _primary, fontSize: 13, fontWeight: FontWeight.w700),
              items: units.map((u) => DropdownMenuItem(
                value: u,
                child: Text(u, style: const TextStyle(color: _primary, fontSize: 13, fontWeight: FontWeight.w700)),
              )).toList(),
              onChanged: (v) { if (v != null) onUnitChanged(v); },
            ),
          ),
        ),
        filled: true,
        fillColor: _surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _primary, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _error)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _error, width: 2)),
        errorStyle: const TextStyle(color: _error, fontSize: 11),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

// ── Profile Card ──────────────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  final TimingGateProfileModel profile;
  final VoidCallback onEdit;

  const _ProfileCard({required this.profile, required this.onEdit});

  static const _surface      = TimingGateProfileMobile._surface;
  static const _border       = TimingGateProfileMobile._border;
  static const _primary      = TimingGateProfileMobile._primary;
  static const _primaryLight = TimingGateProfileMobile._primaryLight;
  static const _text         = TimingGateProfileMobile._text;
  static const _subtext      = TimingGateProfileMobile._subtext;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // ── Avatar + Name ──────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _border),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: _primaryLight,
                  child: Text(
                    profile.name.isNotEmpty ? profile.name[0].toUpperCase() : '?',
                    style: const TextStyle(color: _primary, fontSize: 32, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 14),
                Text(profile.name,
                    style: const TextStyle(color: _text, fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                _roleBadge(),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Details ────────────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _border),
            ),
            child: Column(
              children: [
                _detailRow(Icons.badge_outlined, 'Role', profile.roleLabel),
                if (profile.isCoach && (profile.organization?.isNotEmpty ?? false)) ...[
                  _divider(),
                  _detailRow(Icons.business_outlined, 'Organization', profile.organization!),
                ],
                if (profile.isAthlete && (profile.sport?.isNotEmpty ?? false)) ...[
                  _divider(),
                  _detailRow(Icons.sports_soccer_outlined, 'Sport', profile.sport!),
                ],
                if (profile.dateOfBirth != null) ...[
                  _divider(),
                  _detailRow(
                    Icons.cake_outlined,
                    'Date of Birth',
                    '${DateFormat('dd MMM yyyy').format(profile.dateOfBirth!)}  ·  ${profile.age} yrs',
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Physical stats ─────────────────────────────────────────────────
          if (profile.height != null || profile.weight != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _border),
              ),
              child: Row(
                children: [
                  if (profile.height != null)
                    Expanded(child: _statTile(Icons.height, 'Height', profile.heightDisplay)),
                  if (profile.height != null && profile.weight != null)
                    Container(width: 1, height: 50, color: _border),
                  if (profile.weight != null)
                    Expanded(child: _statTile(Icons.monitor_weight_outlined, 'Weight', profile.weightDisplay)),
                ],
              ),
            ),
          if (profile.height != null || profile.weight != null) const SizedBox(height: 16),

          // ── Info banner ────────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _primaryLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: _primary, size: 20),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Your name will appear on session PDFs as the test conductor.',
                    style: TextStyle(color: _primary, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Change profile ─────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () => _confirmChange(context),
              icon: const Icon(Icons.swap_horiz, size: 18),
              label: const Text('Change Profile', style: TextStyle(fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: _primary,
                side: const BorderSide(color: _primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Switch Device ──────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () => context.go(AppPaths.featureSelection), // Timing Gate band karo, Feature Screen par jao
              icon: const Icon(Icons.devices, size: 18),
              label: const Text('Switch Device', style: TextStyle(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmChange(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.swap_horiz, color: _primary),
          SizedBox(width: 8),
          Text('Change Profile?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ]),
        content: const Text(
          'This will reset your current profile. You can set up a new one.',
          style: TextStyle(color: _subtext),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () { Navigator.of(ctx).pop(); onEdit(); },
            child: const Text('Change', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _roleBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: profile.isCoach ? const Color(0xFFFFF7ED) : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: profile.isCoach ? const Color(0xFFFDBA74) : const Color(0xFF86EFAC),
        ),
      ),
      child: Text(
        profile.roleLabel,
        style: TextStyle(
          color: profile.isCoach ? const Color(0xFFD97706) : const Color(0xFF16A34A),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _divider() => const Divider(height: 24, color: _border);

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: _primaryLight, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: _primary, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: _subtext, fontSize: 12)),
              Text(value, style: const TextStyle(color: _text, fontSize: 15, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Icon(icon, color: _primary, size: 22),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(color: _text, fontSize: 16, fontWeight: FontWeight.w700)),
          Text(label, style: const TextStyle(color: _subtext, fontSize: 12)),
        ],
      ),
    );
  }
}
