import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:xelex_esp/core/theme/app_colors.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/registration/presentation/cubit/athlete_registration_cubit.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/registration/presentation/cubit/athlete_registration_state.dart';
import 'package:xelex_esp/router/heart_tracker_path.dart';

class AthleteRegistrationMobile extends StatelessWidget {
  AthleteRegistrationMobile({super.key});

  final _formKey = GlobalKey<FormState>();

  final _fullNameController    = TextEditingController();
  final _athleteIdController   = TextEditingController();
  final _emailController       = TextEditingController();
  final _mobileController      = TextEditingController();
  final _aadharController      = TextEditingController();
  final _heightController      = TextEditingController();
  final _heightFeetController  = TextEditingController();
  final _heightInchesController = TextEditingController();
  final _weightController      = TextEditingController();
  final _deviceModelController = TextEditingController();
  final _deviceSerialController = TextEditingController();

  final _fullNameFocus     = FocusNode();
  final _athleteIdFocus    = FocusNode();
  final _emailFocus        = FocusNode();
  final _mobileFocus       = FocusNode();
  final _aadharFocus       = FocusNode();
  final _dobFocus          = FocusNode();
  final _heightFocus       = FocusNode();
  final _heightFeetFocus   = FocusNode();
  final _heightInchesFocus = FocusNode();
  final _weightFocus       = FocusNode();
  final _deviceModelFocus  = FocusNode();
  final _deviceSerialFocus = FocusNode();

  final List<String> _dominantHandOptions = ['Left', 'Right', 'Ambidextrous'];
  final List<String> _sportTypes = [
    'Cricket', 'Football', 'Basketball', 'Tennis', 'Badminton',
    'Swimming', 'Athletics', 'Boxing', 'Wrestling', 'Cycling', 'Other',
  ];

  Future<void> _pickDOB(BuildContext context) async {
    _dobFocus.requestFocus();
    final cubit = context.read<AthleteRegistrationCubit>();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) cubit.updateDob(picked);
    _dobFocus.unfocus();
  }

  void _updateImperialHeight(BuildContext context) {
    final feet   = _heightFeetController.text;
    final inches = _heightInchesController.text;
    context.read<AthleteRegistrationCubit>().updateHeight(
        "${feet.isNotEmpty ? feet : '0'}'${inches.isNotEmpty ? inches : '0'}\"");
  }

  void _showSnack(BuildContext context, String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: success ? AppColors.success : AppColors.error,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AthleteRegistrationCubit(),
      child: Builder(
        builder: (context) => Scaffold(
          backgroundColor: AppColors.bg,
          appBar: AppBar(
            title: const Text("Athlete Registration"),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: BlocBuilder<AthleteRegistrationCubit, AthleteRegistrationState>(
            builder: (context, state) => Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ── 1. Personal Information ────────────────────────────
                  _buildSection(
                    title: '1. Personal Information',
                    icon: Icons.person_outline,
                    children: [
                      _buildTextField(context,
                        controller: _fullNameController,
                        focusNode: _fullNameFocus,
                        nextFocus: _athleteIdFocus,
                        label: 'Full Name', hint: 'Enter your full name',
                        icon: Icons.badge_outlined,
                        onChanged: context.read<AthleteRegistrationCubit>().updateFullName,
                        validator: (v) => v == null || v.trim().isEmpty ? 'Full name is required' : null,
                      ),
                      _buildTextField(context,
                        controller: _athleteIdController,
                        focusNode: _athleteIdFocus,
                        nextFocus: _emailFocus,
                        label: 'Athlete ID (Optional)', hint: 'Enter athlete ID',
                        icon: Icons.numbers,
                        onChanged: context.read<AthleteRegistrationCubit>().updateAthleteId,
                      ),
                      _buildTextField(context,
                        controller: _emailController,
                        focusNode: _emailFocus,
                        nextFocus: _mobileFocus,
                        label: 'Email', hint: 'Enter your email',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        onChanged: context.read<AthleteRegistrationCubit>().updateEmail,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Email is required';
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) {
                            return 'Enter a valid email';
                          }
                          return null;
                        },
                      ),
                      _buildTextField(context,
                        controller: _mobileController,
                        focusNode: _mobileFocus,
                        nextFocus: _aadharFocus,
                        label: 'Mobile Number', hint: 'Enter 10-digit mobile',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        onChanged: context.read<AthleteRegistrationCubit>().updateMobile,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Mobile is required';
                          if (v.length != 10) return 'Enter a valid 10-digit number';
                          return null;
                        },
                      ),
                      _buildTextField(context,
                        controller: _aadharController,
                        focusNode: _aadharFocus,
                        nextFocus: _dobFocus,
                        label: 'Aadhaar Number', hint: 'Enter 12-digit Aadhaar',
                        icon: Icons.credit_card_outlined,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(12),
                        ],
                        onChanged: context.read<AthleteRegistrationCubit>().updateAadhar,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Aadhaar is required';
                          if (v.length != 12) return 'Aadhaar must be 12 digits';
                          return null;
                        },
                      ),
                      // Date of Birth
                      GestureDetector(
                        onTap: () => _pickDOB(context),
                        child: AbsorbPointer(
                          child: TextFormField(
                            focusNode: _dobFocus,
                            decoration: _inputDecoration(label: 'Date of Birth',
                                hint: 'Select date of birth', icon: Icons.calendar_today_outlined),
                            controller: TextEditingController(
                              text: state.dob != null
                                  ? '${state.dob!.day}/${state.dob!.month}/${state.dob!.year}'
                                  : '',
                            ),
                            validator: (_) => state.dob == null ? 'Date of birth is required' : null,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ── 2. Physical Information ────────────────────────────
                  _buildSection(
                    title: '2. Physical Information',
                    icon: Icons.fitness_center_outlined,
                    children: [
                      const Text('Sex *',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text)),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: state.sex.isEmpty ? AppColors.border : AppColors.primary,
                          ),
                        ),
                        child: Row(
                          children: ['Male', 'Female', 'Other'].map((sex) => Expanded(
                            child: RadioListTile<String>(
                              title: Text(sex, style: const TextStyle(fontSize: 12)),
                              value: sex,
                              groupValue: state.sex,
                              activeColor: AppColors.primary,
                              contentPadding: EdgeInsets.zero,
                              onChanged: (v) => context.read<AthleteRegistrationCubit>().updateSex(v!),
                            ),
                          )).toList(),
                        ),
                      ),
                      const SizedBox(height: 4),
                      DropdownButtonFormField<String>(
                        initialValue: state.dominantHand,
                        decoration: _inputDecoration(label: 'Dominant Hand',
                            hint: 'Select dominant hand', icon: Icons.back_hand_outlined),
                        items: _dominantHandOptions
                            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                        onChanged: context.read<AthleteRegistrationCubit>().updateDominantHand,
                        validator: (v) => v == null ? 'Please select dominant hand' : null,
                      ),
                      const Text('Unit *',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text)),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: ['Metric', 'Imperial'].map((unit) => Expanded(
                            child: RadioListTile<String>(
                              title: Text(unit, style: const TextStyle(fontSize: 13)),
                              value: unit,
                              groupValue: state.unit,
                              activeColor: AppColors.primary,
                              contentPadding: EdgeInsets.zero,
                              onChanged: (v) {
                                _heightController.clear();
                                _heightFeetController.clear();
                                _heightInchesController.clear();
                                _weightController.clear();
                                context.read<AthleteRegistrationCubit>().updateUnit(v!);
                              },
                            ),
                          )).toList(),
                        ),
                      ),
                      if (state.unit == 'Metric') ...[
                        Row(children: [
                          Expanded(
                            child: _buildTextField(context,
                              controller: _heightController,
                              focusNode: _heightFocus,
                              nextFocus: _weightFocus,
                              label: 'Height (cm)', hint: 'e.g. 175',
                              icon: Icons.height,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              onChanged: context.read<AthleteRegistrationCubit>().updateHeight,
                              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTextField(context,
                              controller: _weightController,
                              focusNode: _weightFocus,
                              nextFocus: _deviceModelFocus,
                              label: 'Weight (kg)', hint: 'e.g. 70',
                              icon: Icons.monitor_weight_outlined,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              onChanged: context.read<AthleteRegistrationCubit>().updateWeight,
                              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                            ),
                          ),
                        ]),
                      ] else ...[
                        const Text('Height *',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text)),
                        const SizedBox(height: 8),
                        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Expanded(
                            child: TextFormField(
                              controller: _heightFeetController,
                              focusNode: _heightFeetFocus,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.next,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(1),
                              ],
                              decoration: _inputDecoration(label: 'Feet', hint: 'e.g. 5', icon: Icons.height)
                                  .copyWith(suffixText: 'ft',
                                      suffixStyle: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                              onChanged: (v) {
                                context.read<AthleteRegistrationCubit>().updateHeightFeet(v);
                                _updateImperialHeight(context);
                                if (v.length == 1) {
                                  _heightFeetFocus.unfocus();
                                  FocusScope.of(context).requestFocus(_heightInchesFocus);
                                }
                              },
                              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _heightInchesController,
                              focusNode: _heightInchesFocus,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.next,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(2),
                                _InchesRangeFormatter(),
                              ],
                              decoration: _inputDecoration(label: 'Inches', hint: 'e.g. 9', icon: Icons.height)
                                  .copyWith(suffixText: 'in',
                                      suffixStyle: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                              onChanged: (v) {
                                context.read<AthleteRegistrationCubit>().updateHeightInches(v);
                                _updateImperialHeight(context);
                                if (v.length == 2) {
                                  _heightInchesFocus.unfocus();
                                  FocusScope.of(context).requestFocus(_weightFocus);
                                }
                              },
                              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTextField(context,
                              controller: _weightController,
                              focusNode: _weightFocus,
                              nextFocus: _deviceModelFocus,
                              label: 'Weight (lbs)', hint: 'e.g. 154',
                              icon: Icons.monitor_weight_outlined,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              onChanged: context.read<AthleteRegistrationCubit>().updateWeight,
                              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                            ),
                          ),
                        ]),
                        if (state.heightFeet.isNotEmpty || state.heightInches.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(children: [
                              const Icon(Icons.check_circle, color: AppColors.success, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                "Height: ${state.heightFeet.isNotEmpty ? state.heightFeet : '0'}' ${state.heightInches.isNotEmpty ? state.heightInches : '0'}\"",
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.success),
                              ),
                            ]),
                          ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ── 3. Sports & Activity ───────────────────────────────
                  _buildSection(
                    title: '3. Sports & Activity',
                    icon: Icons.sports_outlined,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: state.sportType,
                        decoration: _inputDecoration(label: 'Sport Type',
                            hint: 'Select your sport', icon: Icons.sports),
                        items: _sportTypes
                            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                        onChanged: context.read<AthleteRegistrationCubit>().updateSportType,
                        validator: (v) => v == null ? 'Please select a sport type' : null,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ── 4. Device Information ──────────────────────────────
                  _buildSection(
                    title: '4. Device Information',
                    icon: Icons.devices_outlined,
                    children: [
                      _buildTextField(context,
                        controller: _deviceModelController,
                        focusNode: _deviceModelFocus,
                        nextFocus: _deviceSerialFocus,
                        label: 'Device Model', hint: 'Enter device model',
                        icon: Icons.phone_android_outlined,
                        onChanged: context.read<AthleteRegistrationCubit>().updateDeviceModel,
                        validator: (v) => v == null || v.trim().isEmpty ? 'Device model is required' : null,
                      ),
                      _buildTextField(context,
                        controller: _deviceSerialController,
                        focusNode: _deviceSerialFocus,
                        nextFocus: null,
                        label: 'Device Serial Number', hint: 'Enter serial number',
                        icon: Icons.qr_code_outlined,
                        textInputAction: TextInputAction.done,
                        onChanged: context.read<AthleteRegistrationCubit>().updateDeviceSerial,
                        validator: (v) => v == null || v.trim().isEmpty ? 'Serial number is required' : null,
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // ── Submit Button ──────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () {
                        context.go(HeartTrackerPaths.athleteHome);
                        /*
                        final st = context.read<AthleteRegistrationCubit>().state;
                        if (st.sex.isEmpty) {
                          _showSnack(context, 'Please select your sex.');
                          return;
                        }
                        if (_formKey.currentState!.validate()) {
                          context.read<AthleteRegistrationCubit>().submit();
                          context.go(HeartTrackerPaths.athleteHome);
                        }
                        */
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 3,
                      ),
                      child: const Text('Complete Registration',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Section Card ───────────────────────────────────────────────────────────
  Widget _buildSection({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children
                  .expand((w) => [w, const SizedBox(height: 14)])
                  .toList()
                ..removeLast(),
            ),
          ),
        ],
      ),
    );
  }

  // ── Text Field ─────────────────────────────────────────────────────────────
  Widget _buildTextField(
    BuildContext context, {
    required TextEditingController controller,
    required FocusNode focusNode,
    required FocusNode? nextFocus,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
    List<TextInputFormatter>? inputFormatters,
    void Function(String)? onChanged,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      textInputAction: nextFocus == null ? TextInputAction.done : textInputAction,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      onFieldSubmitted: (_) {
        focusNode.unfocus();
        if (nextFocus != null) FocusScope.of(focusNode.context!).requestFocus(nextFocus);
      },
      validator: validator,
      decoration: _inputDecoration(label: label, hint: hint, icon: icon),
    );
  }

  // ── Input Decoration ───────────────────────────────────────────────────────
  InputDecoration _inputDecoration({required String label, required String hint, required IconData icon}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.primary),
      filled: true,
      fillColor: AppColors.surfaceAlt,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5)),
      focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}

class _InchesRangeFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue o, TextEditingValue n) {
    if (n.text.isEmpty) return n;
    final v = int.tryParse(n.text);
    if (v == null || v < 0 || v > 11) return o;
    return n;
  }
}
