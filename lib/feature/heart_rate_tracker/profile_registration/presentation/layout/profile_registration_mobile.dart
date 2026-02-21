import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/profile_registration/presentation/cubit/indivi_profile_registration_cubit/profile_registration_cubit.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/profile_registration/presentation/cubit/indivi_profile_registration_cubit/profile_registration_state.dart';
import 'package:xelex_esp/router/heart_tracker_path.dart';

class IndiviRegistrationMobile extends StatelessWidget {
  IndiviRegistrationMobile({super.key});

  final _formKey = GlobalKey<FormState>();

  // ─── Controllers ─────────────────────────────────────────────────────────────
  final _fullNameController = TextEditingController();
  final _athleteIdController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _aadharController = TextEditingController();
  final _heightController = TextEditingController();
  final _heightFeetController = TextEditingController();
  final _heightInchesController = TextEditingController();
  final _weightController = TextEditingController();
  final _deviceModelController = TextEditingController();
  final _deviceSerialController = TextEditingController();

  // ─── Focus Nodes ─────────────────────────────────────────────────────────────
  final _fullNameFocus = FocusNode();
  final _athleteIdFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _mobileFocus = FocusNode();
  final _aadharFocus = FocusNode();
  final _dobFocus = FocusNode();
  final _heightFocus = FocusNode();
  final _heightFeetFocus = FocusNode();
  final _heightInchesFocus = FocusNode();
  final _weightFocus = FocusNode();
  final _deviceModelFocus = FocusNode();
  final _deviceSerialFocus = FocusNode();

  final List<String> _dominantHandOptions = ['Left', 'Right', 'Ambidextrous'];
  final List<String> _sportTypes = [
    'Cricket',
    'Football',
    'Basketball',
    'Tennis',
    'Badminton',
    'Swimming',
    'Athletics',
    'Boxing',
    'Wrestling',
    'Cycling',
    'Other',
  ];

  void _disposeFocusNodes() {
    _fullNameFocus.dispose();
    _athleteIdFocus.dispose();
    _emailFocus.dispose();
    _mobileFocus.dispose();
    _aadharFocus.dispose();
    _dobFocus.dispose();
    _heightFocus.dispose();
    _heightFeetFocus.dispose();
    _heightInchesFocus.dispose();
    _weightFocus.dispose();
    _deviceModelFocus.dispose();
    _deviceSerialFocus.dispose();
  }

  Future<void> _pickDOB(BuildContext context) async {
    _dobFocus.requestFocus();
    final cubit = context.read<IndiviProfileRegistrationCubit>();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      cubit.updateDob(picked);
    }
    _dobFocus.unfocus();
  }

  void _updateImperialHeight(BuildContext context) {
    final feet = _heightFeetController.text;
    final inches = _heightInchesController.text;
    final formatted =
        "${feet.isNotEmpty ? feet : '0'}'${inches.isNotEmpty ? inches : '0'}\"";
    context.read<IndiviProfileRegistrationCubit>().updateHeight(formatted);
  }

  void _submitForm(BuildContext context) {
    FocusScope.of(context).unfocus();
    final state = context.read<IndiviProfileRegistrationCubit>().state;

    if (state.sex.isEmpty) {
      _showSnack(context, 'Please select your sex.');
      return;
    }
    if (_formKey.currentState!.validate()) {
      context.read<IndiviProfileRegistrationCubit>().submit();
      _showSnack(context, 'Registration Successful!', success: true);
    }
  }

  void _showSnack(
    BuildContext context,
    String message, {
    bool success = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => IndiviProfileRegistrationCubit(),
      child: Builder(
        builder: (context) => Scaffold(
          backgroundColor: const Color(0xFFF5F7FA),
          appBar: AppBar(
            title: const Text(
              'Individual Registration',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: const Color(0xFF1A73E8),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: BlocBuilder<IndiviProfileRegistrationCubit, IndiviProfileRegistrationState>(
            builder: (context, state) {
              return Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // ── Section 1: Personal Information ──────────────────────
                    _buildSection(
                      title: '1. Personal Information',
                      icon: Icons.person_outline,
                      children: [
                        _buildTextField(
                          controller: _fullNameController,
                          focusNode: _fullNameFocus,
                          nextFocusNode: _athleteIdFocus,
                          label: 'Full Name',
                          hint: 'Enter your full name',
                          icon: Icons.badge_outlined,
                          onChanged: context
                              .read<IndiviProfileRegistrationCubit>()
                              .updateFullName,
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Full name is required'
                              : null,
                        ),
                        _buildTextField(
                          controller: _athleteIdController,
                          focusNode: _athleteIdFocus,
                          nextFocusNode: _emailFocus,
                          label: 'Athlete ID (Optional)',
                          hint: 'Enter athlete ID',
                          icon: Icons.numbers,
                          onChanged: context
                              .read<IndiviProfileRegistrationCubit>()
                              .updateAthleteId,
                        ),
                        _buildTextField(
                          controller: _emailController,
                          focusNode: _emailFocus,
                          nextFocusNode: _mobileFocus,
                          label: 'Email',
                          hint: 'Enter your email',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          onChanged: context
                              .read<IndiviProfileRegistrationCubit>()
                              .updateEmail,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty)
                              return 'Email is required';
                            final regex = RegExp(
                              r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                            );
                            if (!regex.hasMatch(v))
                              return 'Enter a valid email';
                            return null;
                          },
                        ),
                        _buildTextField(
                          controller: _mobileController,
                          focusNode: _mobileFocus,
                          nextFocusNode: _aadharFocus,
                          label: 'Mobile Number',
                          hint: 'Enter 10-digit mobile number',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                          onChanged: context
                              .read<IndiviProfileRegistrationCubit>()
                              .updateMobile,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty)
                              return 'Mobile number is required';
                            if (v.length != 10)
                              return 'Enter a valid 10-digit number';
                            return null;
                          },
                        ),
                        _buildTextField(
                          controller: _aadharController,
                          focusNode: _aadharFocus,
                          nextFocusNode: _dobFocus,
                          label: 'Aadhaar Number',
                          hint: 'Enter 12-digit Aadhaar number',
                          icon: Icons.credit_card_outlined,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(12),
                          ],
                          onChanged: context
                              .read<IndiviProfileRegistrationCubit>()
                              .updateAadhar,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty)
                              return 'Aadhaar number is required';
                            if (v.length != 12)
                              return 'Aadhaar must be 12 digits';
                            return null;
                          },
                        ),
                        // Date of Birth
                        GestureDetector(
                          onTap: () => _pickDOB(context),
                          child: AbsorbPointer(
                            child: TextFormField(
                              focusNode: _dobFocus,
                              decoration: _inputDecoration(
                                label: 'Date of Birth',
                                hint: 'Select your date of birth',
                                icon: Icons.calendar_today_outlined,
                              ),
                              controller: TextEditingController(
                                text: state.dob != null
                                    ? '${state.dob!.day}/${state.dob!.month}/${state.dob!.year}'
                                    : '',
                              ),
                              validator: (_) => state.dob == null
                                  ? 'Date of birth is required'
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ── Section 2: Physical Information ──────────────────────
                    _buildSection(
                      title: '2. Physical Information',
                      icon: Icons.fitness_center_outlined,
                      children: [
                        // Sex
                        const Text(
                          'Sex *',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF333333),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: state.sex.isEmpty
                                  ? Colors.grey.shade300
                                  : const Color(0xFF1A73E8),
                            ),
                          ),
                          child: Row(
                            children: ['Male', 'Female', 'Other'].map((sex) {
                              return Expanded(
                                child: RadioListTile<String>(
                                  title: Text(
                                    sex,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  value: sex,
                                  groupValue: state.sex,
                                  activeColor: const Color(0xFF1A73E8),
                                  contentPadding: EdgeInsets.zero,
                                  onChanged: (val) => context
                                      .read<IndiviProfileRegistrationCubit>()
                                      .updateSex(val!),
                                ),
                              );
                            }).toList(),
                          ),
                        ),

                        const SizedBox(height: 4),

                        // Dominant Hand
                        DropdownButtonFormField<String>(
                          value: state.dominantHand,
                          decoration: _inputDecoration(
                            label: 'Dominant Hand',
                            hint: 'Select dominant hand',
                            icon: Icons.back_hand_outlined,
                          ),
                          items: _dominantHandOptions
                              .map(
                                (e) =>
                                    DropdownMenuItem(value: e, child: Text(e)),
                              )
                              .toList(),
                          onChanged: context
                              .read<IndiviProfileRegistrationCubit>()
                              .updateDominantHand,
                          validator: (v) =>
                              v == null ? 'Please select dominant hand' : null,
                        ),

                        // Unit
                        const Text(
                          'Unit *',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF333333),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: ['Metric', 'Imperial'].map((unit) {
                              return Expanded(
                                child: RadioListTile<String>(
                                  title: Text(
                                    unit,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  value: unit,
                                  groupValue: state.unit,
                                  activeColor: const Color(0xFF1A73E8),
                                  contentPadding: EdgeInsets.zero,
                                  onChanged: (val) {
                                    _heightController.clear();
                                    _heightFeetController.clear();
                                    _heightInchesController.clear();
                                    _weightController.clear();
                                    context
                                        .read<IndiviProfileRegistrationCubit>()
                                        .updateUnit(val!);
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),

                        // Height & Weight
                        if (state.unit == 'Metric') ...[
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: _heightController,
                                  focusNode: _heightFocus,
                                  nextFocusNode: _weightFocus,
                                  label: 'Height (cm)',
                                  hint: 'e.g. 175',
                                  icon: Icons.height,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  onChanged: context
                                      .read<IndiviProfileRegistrationCubit>()
                                      .updateHeight,
                                  validator: (v) =>
                                      v == null || v.trim().isEmpty
                                      ? 'Required'
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildTextField(
                                  controller: _weightController,
                                  focusNode: _weightFocus,
                                  nextFocusNode: _deviceModelFocus,
                                  label: 'Weight (kg)',
                                  hint: 'e.g. 70',
                                  icon: Icons.monitor_weight_outlined,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  onChanged: context
                                      .read<IndiviProfileRegistrationCubit>()
                                      .updateWeight,
                                  validator: (v) =>
                                      v == null || v.trim().isEmpty
                                      ? 'Required'
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          // Imperial Height
                          const Text(
                            'Height *',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF333333),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Feet
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
                                  decoration:
                                      _inputDecoration(
                                        label: 'Feet',
                                        hint: 'e.g. 5',
                                        icon: Icons.height,
                                      ).copyWith(
                                        suffixText: 'ft',
                                        suffixStyle: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1A73E8),
                                        ),
                                      ),
                                  onChanged: (val) {
                                    context
                                        .read<IndiviProfileRegistrationCubit>()
                                        .updateHeightFeet(val);
                                    _updateImperialHeight(context);
                                    if (val.length == 1) {
                                      _heightFeetFocus.unfocus();
                                      FocusScope.of(
                                        context,
                                      ).requestFocus(_heightInchesFocus);
                                    }
                                  },
                                  validator: (v) =>
                                      v == null || v.trim().isEmpty
                                      ? 'Required'
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Inches
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
                                  decoration:
                                      _inputDecoration(
                                        label: 'Inches',
                                        hint: 'e.g. 9',
                                        icon: Icons.height,
                                      ).copyWith(
                                        suffixText: 'in',
                                        suffixStyle: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1A73E8),
                                        ),
                                      ),
                                  onChanged: (val) {
                                    context
                                        .read<IndiviProfileRegistrationCubit>()
                                        .updateHeightInches(val);
                                    _updateImperialHeight(context);
                                    if (val.length == 2) {
                                      _heightInchesFocus.unfocus();
                                      FocusScope.of(
                                        context,
                                      ).requestFocus(_weightFocus);
                                    }
                                  },
                                  validator: (v) =>
                                      v == null || v.trim().isEmpty
                                      ? 'Required'
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Weight lbs
                              Expanded(
                                child: _buildTextField(
                                  controller: _weightController,
                                  focusNode: _weightFocus,
                                  nextFocusNode: _deviceModelFocus,
                                  label: 'Weight (lbs)',
                                  hint: 'e.g. 154',
                                  icon: Icons.monitor_weight_outlined,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  onChanged: context
                                      .read<IndiviProfileRegistrationCubit>()
                                      .updateWeight,
                                  validator: (v) =>
                                      v == null || v.trim().isEmpty
                                      ? 'Required'
                                      : null,
                                ),
                              ),
                            ],
                          ),
                          // Live preview
                          if (state.heightFeet.isNotEmpty ||
                              state.heightInches.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    "Height: ${state.heightFeet.isNotEmpty ? state.heightFeet : '0'}' ${state.heightInches.isNotEmpty ? state.heightInches : '0'}\"",
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ── Section 3: Sports & Activity ─────────────────────────
                    _buildSection(
                      title: '3. Sports & Activity',
                      icon: Icons.sports_outlined,
                      children: [
                        DropdownButtonFormField<String>(
                          value: state.sportType,
                          decoration: _inputDecoration(
                            label: 'Sport Type',
                            hint: 'Select your sport',
                            icon: Icons.sports,
                          ),
                          items: _sportTypes
                              .map(
                                (e) =>
                                    DropdownMenuItem(value: e, child: Text(e)),
                              )
                              .toList(),
                          onChanged: context
                              .read<IndiviProfileRegistrationCubit>()
                              .updateSportType,
                          validator: (v) =>
                              v == null ? 'Please select a sport type' : null,
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ── Section 4: Device Information ────────────────────────
                    _buildSection(
                      title: '4. Device Information',
                      icon: Icons.devices_outlined,
                      children: [
                        _buildTextField(
                          controller: _deviceModelController,
                          focusNode: _deviceModelFocus,
                          nextFocusNode: _deviceSerialFocus,
                          label: 'Device Model',
                          hint: 'Enter device model',
                          icon: Icons.phone_android_outlined,
                          onChanged: context
                              .read<IndiviProfileRegistrationCubit>()
                              .updateDeviceModel,
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Device model is required'
                              : null,
                        ),
                        _buildTextField(
                          controller: _deviceSerialController,
                          focusNode: _deviceSerialFocus,
                          nextFocusNode: null,
                          label: 'Device Serial Number',
                          hint: 'Enter serial number',
                          icon: Icons.qr_code_outlined,
                          textInputAction: TextInputAction.done,
                          onChanged: context
                              .read<IndiviProfileRegistrationCubit>()
                              .updateDeviceSerial,
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Serial number is required'
                              : null,
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // ── Submit Button ─────────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        // onPressed: () => _submitForm(context),
                        onPressed: () {
                          context.go(HeartTrackerPaths.indiviHomeMobile);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A73E8),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 3,
                        ),
                        child: const Text(
                          'Complete Registration',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ─── Section Card ─────────────────────────────────────────────────────────────
  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              color: Color(0xFF1A73E8),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:
                  children
                      .expand((w) => [w, const SizedBox(height: 14)])
                      .toList()
                    ..removeLast(),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Reusable TextField ───────────────────────────────────────────────────────
  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required FocusNode? nextFocusNode,
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
      textInputAction: nextFocusNode == null
          ? TextInputAction.done
          : textInputAction,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      onFieldSubmitted: (_) {
        focusNode.unfocus();
        if (nextFocusNode != null) {
          FocusScope.of(focusNode.context!).requestFocus(nextFocusNode);
        }
      },
      validator: validator,
      decoration: _inputDecoration(label: label, hint: hint, icon: icon),
    );
  }

  // ─── Input Decoration ─────────────────────────────────────────────────────────
  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: const Color(0xFF1A73E8)),
      filled: true,
      fillColor: const Color(0xFFF5F7FA),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF1A73E8), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}

// ─── Inches Range Formatter (0–11 only) ──────────────────────────────────────
class _InchesRangeFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    final val = int.tryParse(newValue.text);
    if (val == null || val < 0 || val > 11) return oldValue;
    return newValue;
  }
}
