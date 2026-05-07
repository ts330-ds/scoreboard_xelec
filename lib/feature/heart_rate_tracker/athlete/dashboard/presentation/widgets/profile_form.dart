import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/core/theme/app_colors.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/profile/domain/entity/athlete_profile_entity.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/profile/presentation/cubit/athlete_profile_cubit.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/common/sport/presentation/cubit/sport_cubit.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/heart_rate_bluetooth/cubit/heart_ble_cubit.dart';
import 'profile_avatar_header.dart';
import 'profile_date_field.dart';
import 'profile_device_info_section.dart';
import 'profile_dropdown_field.dart';
import 'profile_field.dart';
import 'profile_logout_button.dart';
import 'profile_save_bar.dart';
import 'profile_section_card.dart';
import 'profile_sport_section.dart';

class ProfileForm extends StatefulWidget {
  final AthleteProfileEntity? profile;

  const ProfileForm({super.key, required this.profile});

  @override
  State<ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<ProfileForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _aadharCtrl;
  late final TextEditingController _dobCtrl;
  late final TextEditingController _heightFeetCtrl;
  late final TextEditingController _heightInchesCtrl;
  late final TextEditingController _weightKgCtrl;
  late final TextEditingController _weightLbsCtrl;

  String? _selectedGender;
  String? _selectedHand;
  int? _selectedSportId;

  static const _genders = ['Male', 'Female', 'Other'];
  static const _hands = ['Right', 'Left'];

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _phoneCtrl = TextEditingController(text: p?.phone ?? '');
    _aadharCtrl = TextEditingController(text: p?.aadhar ?? '');
    _dobCtrl = TextEditingController(text: p?.dob ?? '');
    _heightFeetCtrl = TextEditingController(text: _fmt(p?.heightInFeet));
    _heightInchesCtrl = TextEditingController(text: _fmt(p?.heightInInches));
    _weightKgCtrl = TextEditingController(text: _fmt(p?.weightInKg));
    _weightLbsCtrl = TextEditingController(text: _fmt(p?.weightInLbs));
    _selectedGender = p?.gender;
    _selectedHand = p?.dominantHand;
    _selectedSportId = p?.sportId;

    // sport_id nahi aata API se — sport_name se match karo
    if (_selectedSportId == null && p?.sportName != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final sports = context.read<SportCubit>().state.sports;
        final match = sports.where(
          (s) => s.name.toLowerCase() == p!.sportName!.toLowerCase(),
        );
        if (match.isNotEmpty) {
          setState(() => _selectedSportId = match.first.id);
        }
      });
    }

    _weightKgCtrl.addListener(_onKgChanged);
    _weightLbsCtrl.addListener(_onLbsChanged);
  }

  // 5.0 → "5",  78.5 → "78.5",  null → ""
  String _fmt(double? v) {
    if (v == null) return '';
    return v == v.truncateToDouble() ? v.toInt().toString() : v.toString();
  }

  bool _convertingWeight = false;

  void _onKgChanged() {
    if (_convertingWeight) return;
    final kg = double.tryParse(_weightKgCtrl.text);
    _convertingWeight = true;
    _weightLbsCtrl.text = kg != null ? _fmt(kg * 2.20462) : '';
    _convertingWeight = false;
  }

  void _onLbsChanged() {
    if (_convertingWeight) return;
    final lbs = double.tryParse(_weightLbsCtrl.text);
    _convertingWeight = true;
    _weightKgCtrl.text = lbs != null ? _fmt(lbs / 2.20462) : '';
    _convertingWeight = false;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _aadharCtrl.dispose();
    _dobCtrl.dispose();
    _heightFeetCtrl.dispose();
    _heightInchesCtrl.dispose();
    _weightKgCtrl.dispose();
    _weightLbsCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1950),
      lastDate: now,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      _dobCtrl.text =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  void _onSave() {
    if (!_formKey.currentState!.validate()) return;

    final ble = context.read<HeartBleCubit>().state;

    context.read<AthleteProfileCubit>().updateProfile(
          name: _nameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim().isEmpty
              ? null
              : _phoneCtrl.text.trim(),
          aadhar: _aadharCtrl.text.trim().isEmpty
              ? null
              : _aadharCtrl.text.trim(),
          dob: _dobCtrl.text.trim().isEmpty ? null : _dobCtrl.text.trim(),
          sex: _selectedGender,
          dominantHand: _selectedHand,
          heightInFeet: double.tryParse(_heightFeetCtrl.text),
          heightInInches: double.tryParse(_heightInchesCtrl.text),
          weightInKg: double.tryParse(_weightKgCtrl.text),
          weightInLbs: double.tryParse(_weightLbsCtrl.text),
          sportId: _selectedSportId,
          deviceModel: ble.modelName.isNotEmpty ? ble.modelName : null,
          deviceSerial:
              ble.serialNumber.isNotEmpty ? ble.serialNumber : null,
        );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;

    return Column(
      children: [
        Expanded(
          child: Form(
            key: _formKey,
            child: ListView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              children: [
                ProfileAvatarHeader(
                  name: p?.name ?? '—',
                  email: p?.email ?? '—',
                ),
                const SizedBox(height: 24),

                ProfileSectionCard(
                  title: 'Personal Info',
                  children: [
                    ProfileField(
                      label: 'Full Name',
                      icon: Icons.person_outline,
                      controller: _nameCtrl,
                      hint: 'Enter your name',
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Name is required'
                          : null,
                    ),
                    ProfileField(
                      label: 'Email',
                      icon: Icons.email_outlined,
                      initialValue: p?.email ?? '',
                      readOnly: true,
                    ),
                    ProfileField(
                      label: 'Phone Number',
                      icon: Icons.phone_outlined,
                      controller: _phoneCtrl,
                      hint: 'Enter phone number',
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly
                      ],
                    ),
                    ProfileField(
                      label: 'Aadhar Number',
                      icon: Icons.credit_card_outlined,
                      controller: _aadharCtrl,
                      hint: 'Enter 12-digit aadhar',
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly
                      ],
                      maxLength: 12,
                    ),
                    ProfileDateField(
                      label: 'Date of Birth',
                      icon: Icons.calendar_today_outlined,
                      controller: _dobCtrl,
                      onTap: _pickDate,
                    ),
                    ProfileDropdownField(
                      label: 'Gender',
                      icon: Icons.wc_outlined,
                      value: _selectedGender,
                      items: _genders,
                      hint: 'Select gender',
                      onChanged: (v) => setState(() => _selectedGender = v),
                    ),
                    ProfileDropdownField(
                      label: 'Dominant Hand',
                      icon: Icons.front_hand_outlined,
                      value: _selectedHand,
                      items: _hands,
                      hint: 'Select hand',
                      onChanged: (v) => setState(() => _selectedHand = v),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                ProfileSportSection(
                  selectedSportId: _selectedSportId,
                  onChanged: (v) => setState(() => _selectedSportId = v),
                ),
                const SizedBox(height: 12),

                ProfileSectionCard(
                  title: 'Body Measurements',
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ProfileField(
                            label: 'Height (ft)',
                            icon: Icons.height_outlined,
                            controller: _heightFeetCtrl,
                            hint: 'e.g. 5',
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ProfileField(
                            label: 'Height (in)',
                            icon: Icons.straighten_outlined,
                            controller: _heightInchesCtrl,
                            hint: 'e.g. 9',
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: ProfileField(
                            label: 'Weight (kg)',
                            icon: Icons.monitor_weight_outlined,
                            controller: _weightKgCtrl,
                            hint: 'e.g. 70',
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ProfileField(
                            label: 'Weight (lbs)',
                            icon: Icons.monitor_weight_outlined,
                            controller: _weightLbsCtrl,
                            hint: 'e.g. 154',
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                const ProfileDeviceInfoSection(),
                const SizedBox(height: 12),

                const ProfileLogoutButton(),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
        ProfileSaveBar(onSave: _onSave),
      ],
    );
  }
}
