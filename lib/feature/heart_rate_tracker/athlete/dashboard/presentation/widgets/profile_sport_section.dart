import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/core/theme/app_colors.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/common/sport/presentation/cubit/sport_cubit.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/common/sport/presentation/cubit/sport_state.dart';
import 'profile_section_card.dart';

class ProfileSportSection extends StatelessWidget {
  final int? selectedSportId;
  final ValueChanged<int?> onChanged;

  const ProfileSportSection({
    super.key,
    required this.selectedSportId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SportCubit, SportState>(
      builder: (context, sportState) {
        final sports = sportState.sports;
        final isLoading = sportState.status == SportStatus.loading;

        if (sports.isNotEmpty &&
            selectedSportId != null &&
            !sports.any((s) => s.id == selectedSportId)) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => onChanged(null),
          );
        }

        return ProfileSectionCard(
          title: 'Sport',
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.sports_outlined, size: 14, color: AppColors.subtext),
                    SizedBox(width: 6),
                    Text(
                      'Sport',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.subtext,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<int>(
                  value: selectedSportId,
                  hint: Text(
                    isLoading ? 'Loading...' : 'Select sport',
                    style: const TextStyle(fontSize: 14, color: AppColors.textHint),
                  ),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.text,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                          color: AppColors.primary, width: 1.5),
                    ),
                  ),
                  items: sports
                      .map((s) => DropdownMenuItem(
                            value: s.id,
                            child: Text(s.name),
                          ))
                      .toList(),
                  onChanged: isLoading ? null : onChanged,
                  // Client-side validation: sport server pe required hai
                  // (null bhejne pe "Sport must be a positive integer" 400 aata
                  // tha). Form validate() ise ab catch karta hai — save se pehle
                  // inline error dikhta hai, raw server error nahi.
                  validator: (value) =>
                      value == null ? 'Please select your sport' : null,
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
