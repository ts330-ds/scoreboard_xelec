import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:xelex_esp/core/theme/app_colors.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/coach/auth/presentation/cubit/coach_auth_cubit.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/coach/auth/presentation/cubit/coach_auth_state.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/coach/profile/domain/entity/coach_profile_entity.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/coach/profile/presentation/cubit/coach_profile_cubit.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/coach/profile/presentation/cubit/coach_profile_state.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/common/sport/domain/entity/sport.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/common/sport/presentation/cubit/sport_cubit.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/common/sport/presentation/cubit/sport_state.dart';
import 'package:xelex_esp/router/app_path.dart';
import 'package:xelex_esp/service/dependency_injection/di_service.dart';

const _kProfileGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
);

class CoachProfileMobile extends StatelessWidget {
  const CoachProfileMobile({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<CoachProfileCubit>()..fetchProfile()),
        BlocProvider(create: (_) => sl<SportCubit>()..getSports()),
      ],
      child: const _CoachProfileView(),
    );
  }
}

class _CoachProfileView extends StatelessWidget {
  const _CoachProfileView();

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<CoachAuthCubit, CoachAuthState>(
          listenWhen: (_, curr) => curr.status == CoachAuthStatus.loggedOut,
          listener: (_, __) => context.go(AppPaths.splash),
        ),
        BlocListener<CoachProfileCubit, CoachProfileState>(
          listenWhen: (_, curr) =>
              curr.status == CoachProfileStatus.tokenExpired,
          listener: (context, _) =>
              context.read<CoachAuthCubit>().logout(),
        ),
        BlocListener<CoachProfileCubit, CoachProfileState>(
          listenWhen: (prev, curr) =>
              curr.status == CoachProfileStatus.updated ||
              (curr.status == CoachProfileStatus.error &&
                  prev.status == CoachProfileStatus.updating),
          listener: (context, state) {
            final isSuccess = state.status == CoachProfileStatus.updated;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isSuccess
                      ? 'Profile updated successfully'
                      : (state.errorMessage ?? 'Update failed'),
                ),
                backgroundColor:
                    isSuccess ? AppColors.success : AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
      ],
      child: BlocBuilder<CoachProfileCubit, CoachProfileState>(
        builder: (context, state) {
          if (!Platform.isIOS) {
            SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.light,
            ));
          }
          return Scaffold(
            backgroundColor: AppColors.bg,
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              elevation: 0,
              scrolledUnderElevation: 0,
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              flexibleSpace: Container(
                decoration: const BoxDecoration(gradient: _kProfileGradient),
              ),
              title: const Text(
                'Profile',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            body: switch (state.status) {
              CoachProfileStatus.loading => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              CoachProfileStatus.error => _ErrorView(
                  message: state.errorMessage ?? 'Something went wrong',
                  onRetry: () =>
                      context.read<CoachProfileCubit>().fetchProfile(),
                ),
              CoachProfileStatus.loaded ||
              CoachProfileStatus.updated =>
                _ProfileBody(
                  profile: state.profile!,
                  onEdit: () => _openEditSheet(context, state.profile!),
                ),
              _ => const SizedBox.shrink(),
            },
          );
        },
      ),
    );
  }

  void _openEditSheet(BuildContext context, CoachProfileEntity profile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: context.read<CoachProfileCubit>()),
          BlocProvider.value(value: context.read<SportCubit>()),
        ],
        child: _EditProfileSheet(profile: profile),
      ),
    );
  }
}

// ── Edit Bottom Sheet ─────────────────────────────────────────────────────────

class _EditProfileSheet extends StatefulWidget {
  final CoachProfileEntity profile;
  const _EditProfileSheet({required this.profile});

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _orgCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _aadharCtrl;
  late final TextEditingController _dobCtrl;
  late final TextEditingController _heightFeetCtrl;
  late final TextEditingController _heightInchesCtrl;
  late final TextEditingController _weightKgCtrl;
  late final TextEditingController _weightLbsCtrl;
  Sport? _selectedSport;
  String? _selectedGender;
  String? _selectedDominantHand;

  bool _updatingWeight = false; // prevents listener loop

  static const _genders = ['Male', 'Female', 'Other'];
  static const _hands = ['Right', 'Left'];

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _nameCtrl = TextEditingController(text: p.name);
    _orgCtrl = TextEditingController(text: p.organization ?? '');
    _phoneCtrl = TextEditingController(text: p.phone ?? '');
    _aadharCtrl = TextEditingController(text: p.aadhar ?? '');
    _dobCtrl = TextEditingController(text: p.dob ?? '');
    _heightFeetCtrl = TextEditingController(
        text: p.heightInFeet != null ? p.heightInFeet!.toStringAsFixed(0) : '');
    _heightInchesCtrl = TextEditingController(
        text: p.heightInInches != null ? p.heightInInches!.toStringAsFixed(0) : '');
    _weightKgCtrl = TextEditingController(
        text: p.weightInKg != null ? p.weightInKg!.toStringAsFixed(1) : '');
    _weightLbsCtrl = TextEditingController(
        text: p.weightInLbs != null ? p.weightInLbs!.toStringAsFixed(1) : '');
    _selectedGender = p.gender;
    _selectedDominantHand = p.dominantHand;

    _weightKgCtrl.addListener(_onKgChanged);
    _weightLbsCtrl.addListener(_onLbsChanged);
  }

  void _onKgChanged() {
    if (_updatingWeight) return;
    final kg = double.tryParse(_weightKgCtrl.text.trim());
    if (kg == null) return;
    _updatingWeight = true;
    _weightLbsCtrl.text = (kg * 2.20462).toStringAsFixed(1);
    _updatingWeight = false;
  }

  void _onLbsChanged() {
    if (_updatingWeight) return;
    final lbs = double.tryParse(_weightLbsCtrl.text.trim());
    if (lbs == null) return;
    _updatingWeight = true;
    _weightKgCtrl.text = (lbs / 2.20462).toStringAsFixed(1);
    _updatingWeight = false;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _orgCtrl.dispose();
    _phoneCtrl.dispose();
    _aadharCtrl.dispose();
    _dobCtrl.dispose();
    _heightFeetCtrl.dispose();
    _heightInchesCtrl.dispose();
    _weightKgCtrl.dispose();
    _weightLbsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return BlocListener<CoachProfileCubit, CoachProfileState>(
      listenWhen: (prev, curr) =>
          curr.status == CoachProfileStatus.updated ||
          (curr.status == CoachProfileStatus.error &&
              prev.status == CoachProfileStatus.updating),
      listener: (context, state) {
        if (state.status == CoachProfileStatus.updated) {
          Navigator.of(context).pop();
        }
      },
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.92,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollCtrl) => Column(
          children: [
            // handle + header (fixed)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Edit Profile',
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Update your personal & physical information',
                    style: TextStyle(color: AppColors.subtext, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: AppColors.border),
                ],
              ),
            ),

            // scrollable fields
            Expanded(
              child: SingleChildScrollView(
                controller: scrollCtrl,
                padding: EdgeInsets.fromLTRB(24, 20, 24, bottom + 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Basic Info
                      _sectionLabel('Basic Information'),
                      const SizedBox(height: 12),
                      _buildField(
                        controller: _nameCtrl,
                        label: 'Name',
                        icon: Icons.person_outline,
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Name is required'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      _buildField(
                        controller: _orgCtrl,
                        label: 'Organization',
                        icon: Icons.business_outlined,
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Organization is required'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      _SportDropdown(
                        currentSportName: widget.profile.sportName,
                        onChanged: (s) => setState(() => _selectedSport = s),
                        selected: _selectedSport,
                      ),
                      const SizedBox(height: 12),
                      _buildField(
                        controller: _phoneCtrl,
                        label: 'Phone Number',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return null;
                          if (v.trim().length > 10) return 'Max 10 digits allowed';
                          return null;
                        },
                      ),

                      const SizedBox(height: 24),
                      // ── Personal Details
                      _sectionLabel('Personal Details'),
                      const SizedBox(height: 12),
                      _buildField(
                        controller: _dobCtrl,
                        label: 'Date of Birth',
                        icon: Icons.cake_outlined,
                        keyboardType: TextInputType.datetime,
                        onTap: () => _pickDate(context),
                        readOnly: true,
                      ),
                      const SizedBox(height: 12),
                      _buildDropdown(
                        label: 'Gender',
                        icon: Icons.wc_outlined,
                        value: _selectedGender,
                        items: _genders,
                        onChanged: (v) => setState(() => _selectedGender = v),
                      ),
                      const SizedBox(height: 12),
                      _buildDropdown(
                        label: 'Dominant Hand',
                        icon: Icons.back_hand_outlined,
                        value: _selectedDominantHand,
                        items: _hands,
                        onChanged: (v) =>
                            setState(() => _selectedDominantHand = v),
                      ),
                      const SizedBox(height: 12),
                      _buildField(
                        controller: _aadharCtrl,
                        label: 'Aadhar Number',
                        icon: Icons.badge_outlined,
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return null;
                          if (v.trim().length > 14) return 'Max 14 digits allowed';
                          return null;
                        },
                      ),

                      const SizedBox(height: 24),
                      // ── Physical Info
                      _sectionLabel('Physical Information'),
                      const SizedBox(height: 12),
                      _buildField(
                        controller: _heightFeetCtrl,
                        label: 'Height (ft)',
                        icon: Icons.height_outlined,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      _buildField(
                        controller: _heightInchesCtrl,
                        label: 'Height (in)',
                        icon: Icons.height_outlined,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      _buildField(
                        controller: _weightKgCtrl,
                        label: 'Weight (kg)',
                        icon: Icons.monitor_weight_outlined,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                      const SizedBox(height: 12),
                      _buildField(
                        controller: _weightLbsCtrl,
                        label: 'Weight (lbs)',
                        icon: Icons.monitor_weight_outlined,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),

                      const SizedBox(height: 28),
                      BlocBuilder<CoachProfileCubit, CoachProfileState>(
                        builder: (context, state) {
                          final isLoading =
                              state.status == CoachProfileStatus.updating;
                          return SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed:
                                  isLoading ? null : () => _submit(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5),
                                    )
                                  : const Text(
                                      'Save Changes',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold),
                                    ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      ), // GestureDetector
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: const TextStyle(
          color: AppColors.text,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      );

  void _submit(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSport == null && widget.profile.sportName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a sport'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    String? orNull(String v) => v.trim().isEmpty ? null : v.trim();
    double? toDouble(String v) =>
        v.trim().isEmpty ? null : double.tryParse(v.trim());

    context.read<CoachProfileCubit>().updateProfile(
          name: _nameCtrl.text.trim(),
          organization: _orgCtrl.text.trim(),
          sport: _selectedSport?.id ?? _resolveCurrentSportId(context),
          phone: orNull(_phoneCtrl.text),
          aadhar: orNull(_aadharCtrl.text),
          dob: orNull(_dobCtrl.text),
          sex: _selectedGender?.toLowerCase(),
          dominantHand: _selectedDominantHand?.toLowerCase(),
          heightInFeet: toDouble(_heightFeetCtrl.text),
          heightInInches: toDouble(_heightInchesCtrl.text),
          weightInKg: toDouble(_weightKgCtrl.text),
          weightInLbs: toDouble(_weightLbsCtrl.text),
        );
  }

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    DateTime initial = now.subtract(const Duration(days: 365 * 25));
    if (_dobCtrl.text.isNotEmpty) {
      initial = DateTime.tryParse(_dobCtrl.text) ?? initial;
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1940),
      lastDate: now,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            surface: AppColors.surface,
            onSurface: AppColors.text,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _dobCtrl.text =
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  int _resolveCurrentSportId(BuildContext context) {
    final sports = context.read<SportCubit>().state.sports;
    final match = sports.where((s) =>
        s.name.toLowerCase() ==
        (widget.profile.sportName?.toLowerCase() ?? ''));
    return match.isNotEmpty ? match.first.id : 1;
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool readOnly = false,
    VoidCallback? onTap,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
      style: const TextStyle(color: AppColors.text, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            const TextStyle(color: AppColors.subtext, fontSize: 13),
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        filled: true,
        fillColor: AppColors.surfaceAlt,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AppColors.primary, width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AppColors.error, width: 1.5)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AppColors.error, width: 1.5)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required IconData icon,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            const TextStyle(color: AppColors.subtext, fontSize: 13),
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        filled: true,
        fillColor: AppColors.surfaceAlt,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AppColors.primary, width: 1.5)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      dropdownColor: AppColors.surface,
      style: const TextStyle(color: AppColors.text, fontSize: 14),
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: onChanged,
    );
  }
}

// ── Sport Dropdown ────────────────────────────────────────────────────────────

class _SportDropdown extends StatelessWidget {
  final String? currentSportName;
  final Sport? selected;
  final ValueChanged<Sport?> onChanged;

  const _SportDropdown({
    required this.currentSportName,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SportCubit, SportState>(
      builder: (context, state) {
        if (state.status == SportStatus.loading) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.primary),
              ),
              SizedBox(width: 12),
              Text('Loading sports...',
                  style: TextStyle(color: AppColors.subtext)),
            ]),
          );
        }
        if (state.status == SportStatus.error) {
          return Row(children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                state.errorMessage ?? 'Failed to load sports',
                style:
                    const TextStyle(color: AppColors.error, fontSize: 13),
              ),
            ),
            TextButton(
              onPressed: () => context.read<SportCubit>().getSports(),
              child: const Text('Retry'),
            ),
          ]);
        }

        // Pre-select the sport matching current profile sport name
        Sport? initialValue = selected;
        if (initialValue == null && currentSportName != null) {
          final match = state.sports.where((s) =>
              s.name.toLowerCase() == currentSportName!.toLowerCase());
          if (match.isNotEmpty) initialValue = match.first;
        }

        return DropdownButtonFormField<Sport>(
          initialValue: initialValue,
          decoration: InputDecoration(
            labelText: 'Sport',
            prefixIcon:
                const Icon(Icons.sports_outlined, color: AppColors.primary),
            filled: true,
            fillColor: AppColors.surfaceAlt,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 1.5)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          items: state.sports
              .map((s) => DropdownMenuItem(value: s, child: Text(s.name)))
              .toList(),
          onChanged: onChanged,
        );
      },
    );
  }
}

// ── Profile Body ──────────────────────────────────────────────────────────────

class _ProfileBody extends StatelessWidget {
  final CoachProfileEntity profile;
  final VoidCallback onEdit;
  const _ProfileBody({required this.profile, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          // ── Gradient hero header
          _ProfileHero(profile: profile, onEdit: onEdit),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            child: Column(
              children: [
                // ── Basic Info
                _InfoCard(rows: [
                  _InfoTile(Icons.person_outline, 'Name', profile.name),
                  _InfoTile(Icons.email_outlined, 'Email', profile.email),
                  if (profile.phone != null)
                    _InfoTile(Icons.phone_outlined, 'Phone', profile.phone!),
                  if (profile.dob != null)
                    _InfoTile(Icons.cake_outlined, 'Date of Birth', profile.dob!),
                  if (profile.gender != null)
                    _InfoTile(Icons.wc_outlined, 'Gender', profile.gender!),
                ]),
                const SizedBox(height: 14),

                // ── Professional Info
                if (profile.organization != null || profile.sportName != null)
                  _InfoCard(rows: [
                    if (profile.organization != null)
                      _InfoTile(Icons.business_outlined, 'Organization',
                          profile.organization!),
                    if (profile.sportName != null)
                      _InfoTile(Icons.sports_outlined, 'Sport',
                          profile.sportName!),
                  ]),
                if (profile.organization != null || profile.sportName != null)
                  const SizedBox(height: 14),

                // ── Physical Info (only when data exists)
                if (_hasPhysicalData)
                  _InfoCard(rows: [
                    if (profile.heightInFeet != null ||
                        profile.heightInInches != null)
                      _InfoTile(Icons.height_outlined, 'Height',
                          _formatHeight(profile.heightInFeet, profile.heightInInches)),
                    if (profile.weightInKg != null)
                      _InfoTile(Icons.monitor_weight_outlined, 'Weight',
                          '${profile.weightInKg!.toStringAsFixed(1)} kg'
                          '${profile.weightInLbs != null ? ' / ${profile.weightInLbs!.toStringAsFixed(1)} lbs' : ''}'),
                    if (profile.dominantHand != null)
                      _InfoTile(Icons.back_hand_outlined, 'Dominant Hand',
                          profile.dominantHand!),
                    if (profile.aadhar != null)
                      _InfoTile(Icons.badge_outlined, 'Aadhar', profile.aadhar!),
                  ]),
                if (_hasPhysicalData) const SizedBox(height: 14),

                const SizedBox(height: 8),
                const _LogoutButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool get _hasPhysicalData =>
      profile.heightInFeet != null ||
      profile.heightInInches != null ||
      profile.weightInKg != null ||
      profile.dominantHand != null ||
      profile.aadhar != null;

  String _formatHeight(double? feet, double? inches) {
    if (feet != null && inches != null) {
      return '${feet.toStringAsFixed(0)} ft ${inches.toStringAsFixed(0)} in';
    }
    if (feet != null) return '${feet.toStringAsFixed(0)} ft';
    if (inches != null) return '${inches.toStringAsFixed(0)} in';
    return '—';
  }
}

// ── Profile Hero ──────────────────────────────────────────────────────────────

class _ProfileHero extends StatelessWidget {
  final CoachProfileEntity profile;
  final VoidCallback onEdit;
  const _ProfileHero({required this.profile, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final initials = profile.name.trim().isNotEmpty
        ? profile.name.trim().split(' ').where((w) => w.isNotEmpty)
            .map((w) => w[0]).take(2).join().toUpperCase()
        : 'C';

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: _kProfileGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Stack(
        children: [
          // decorative circles
          Positioned(
            right: -24,
            top: -24,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: -20,
            bottom: -20,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),

          SafeArea(
            bottom: false,
            child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: Column(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 44,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  child: Text(initials,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 14),

                // Name
                Text(profile.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),

                // Email
                Text(profile.email,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 13)),
                const SizedBox(height: 14),

                // Chips row
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    _HeroChip(
                        icon: Icons.verified_outlined,
                        label: 'COACH',
                        alpha: 0.25),
                    if (profile.sportName != null)
                      _HeroChip(
                          icon: Icons.sports_outlined,
                          label: profile.sportName!,
                          alpha: 0.18),
                    if (profile.organization != null)
                      _HeroChip(
                          icon: Icons.business_outlined,
                          label: profile.organization!,
                          alpha: 0.18),
                  ],
                ),
                const SizedBox(height: 20),

                // Edit button
                GestureDetector(
                  onTap: onEdit,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit_outlined,
                            color: Colors.white, size: 16),
                        SizedBox(width: 7),
                        Text('Edit Profile',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          ), // SafeArea
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final double alpha;
  const _HeroChip(
      {required this.icon, required this.label, required this.alpha});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: alpha),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: Colors.white.withValues(alpha: alpha + 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 12),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3)),
        ],
      ),
    );
  }
}

// ── Info Card ─────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final List<_InfoTile> rows;
  const _InfoCard({required this.rows});

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: List.generate(rows.length, (i) {
          return Column(
            children: [
              rows[i],
              if (i < rows.length - 1)
                const Divider(height: 1, color: AppColors.borderLight,
                    indent: 56),
            ],
          );
        }),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoTile(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: AppColors.subtext,
                        fontSize: 11,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value.isNotEmpty ? value : '—',
                    style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Error View ────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                color: AppColors.error, size: 48),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.text, fontSize: 14)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Retry',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Logout Button ─────────────────────────────────────────────────────────────

class _LogoutButton extends StatelessWidget {
  const _LogoutButton();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CoachAuthCubit, CoachAuthState>(
      builder: (context, state) {
        final isLoading = state.status == CoachAuthStatus.loggingOut;
        return SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            onPressed: isLoading
                ? null
                : () => context.read<CoachAuthCubit>().logout(),
            icon: isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.error),
                  )
                : const Icon(Icons.logout,
                    color: AppColors.error, size: 20),
            label: Text(
              isLoading ? 'Logging out...' : 'Logout',
              style: const TextStyle(
                color: AppColors.error,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.error),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        );
      },
    );
  }
}
