import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xelex_esp/core/pref_keys.dart';
import 'package:xelex_esp/core/theme/app_colors.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/coach/auth/presentation/cubit/coach_auth_cubit.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/coach/auth/presentation/cubit/coach_auth_state.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/common/sport/domain/entity/sport.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/common/sport/presentation/cubit/sport_cubit.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/common/sport/presentation/cubit/sport_state.dart';
import 'package:xelex_esp/router/heart_tracker_path.dart';
import 'package:xelex_esp/service/dependency_injection/di_service.dart';

class CoachRegistrationMobile extends StatefulWidget {
  const CoachRegistrationMobile({super.key});

  @override
  State<CoachRegistrationMobile> createState() => _CoachRegistrationMobileState();
}

class _CoachRegistrationMobileState extends State<CoachRegistrationMobile> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _organizationController = TextEditingController();

  String _email = '';
  Sport? _selectedSport;

  @override
  void initState() {
    super.initState();
    _email = sl<SharedPreferences>().getString(PrefKeys.userEmail) ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _organizationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<CoachAuthCubit>()),
        BlocProvider(create: (_) => sl<SportCubit>()..getSports()),
      ],
      child: Builder(builder: _buildScaffold),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    return BlocListener<CoachAuthCubit, CoachAuthState>(
      listener: (context, state) {
        if (state.status == CoachAuthStatus.authenticated) {
          context.go(HeartTrackerPaths.coachHome);
        } else if (state.status == CoachAuthStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.errorMessage ?? 'Registration failed'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ));
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          title: const Text('Coach Registration'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                _buildHeader(),
                const SizedBox(height: 36),
                _buildNameField(),
                const SizedBox(height: 16),
                _buildEmailDisplay(),
                const SizedBox(height: 16),
                _buildOrganizationField(),
                const SizedBox(height: 16),
                _buildSportDropdown(context),
                const SizedBox(height: 32),
                _buildSubmitButton(context),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: AppColors.primaryLight,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.sports_outlined, size: 48, color: AppColors.primary),
        ),
        const SizedBox(height: 16),
        const Text(
          'Create Coach Account',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.text),
        ),
        const SizedBox(height: 6),
        const Text(
          'Fill in your details to get started',
          style: TextStyle(fontSize: 14, color: AppColors.subtext),
        ),
      ],
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      textInputAction: TextInputAction.next,
      decoration: _inputDecoration(label: 'Full Name', hint: 'Enter your full name', icon: Icons.person_outline),
      validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null,
    );
  }

  Widget _buildEmailDisplay() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.email_outlined, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Email',
                  style: TextStyle(fontSize: 12, color: AppColors.subtext),
                ),
                const SizedBox(height: 2),
                Text(
                  _email,
                  style: const TextStyle(fontSize: 15, color: AppColors.text),
                ),
              ],
            ),
          ),
          const Icon(Icons.lock_outline, size: 16, color: AppColors.subtext),
        ],
      ),
    );
  }

  Widget _buildOrganizationField() {
    return TextFormField(
      controller: _organizationController,
      textInputAction: TextInputAction.next,
      decoration: _inputDecoration(
        label: 'Organization',
        hint: 'e.g. AMS Fitness, SAI Academy',
        icon: Icons.business_outlined,
      ),
      validator: (v) => v == null || v.trim().isEmpty ? 'Organization is required' : null,
    );
  }

  Widget _buildSportDropdown(BuildContext context) {
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
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
              ),
              SizedBox(width: 12),
              Text('Loading sports...', style: TextStyle(color: AppColors.subtext)),
            ]),
          );
        }
        if (state.status == SportStatus.error) {
          return Row(children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 18),
            const SizedBox(width: 8),
            Text(state.errorMessage ?? 'Failed to load sports',
                style: const TextStyle(color: AppColors.error, fontSize: 13)),
            const Spacer(),
            TextButton(
              onPressed: () => context.read<SportCubit>().getSports(),
              child: const Text('Retry'),
            ),
          ]);
        }
        return DropdownButtonFormField<Sport>(
          initialValue: _selectedSport,
          decoration: _inputDecoration(label: 'Sport', hint: 'Select your sport', icon: Icons.sports),
          items: state.sports.map((s) => DropdownMenuItem(value: s, child: Text(s.name))).toList(),
          onChanged: (s) => setState(() => _selectedSport = s),
          validator: (v) => v == null ? 'Please select a sport' : null,
        );
      },
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    return BlocBuilder<CoachAuthCubit, CoachAuthState>(
      builder: (context, state) {
        final isLoading = state.status == CoachAuthStatus.loading;
        return SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: isLoading ? null : () => _submit(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 2,
            ),
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : const Text('Register', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        );
      },
    );
  }

  void _submit(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;
    context.read<CoachAuthCubit>().register(
          name: _nameController.text.trim(),
          email: _email,
          password: '123456',
          sport: _selectedSport!.id,
          organization: _organizationController.text.trim(),
        );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
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
