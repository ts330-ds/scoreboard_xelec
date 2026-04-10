import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/core/theme/app_colors.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/activity/presentation/cubit/athlete_activity_cubit.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/activity/presentation/cubit/athlete_activity_state.dart';
import 'activity_constants.dart';

class _ActivityDropdown extends StatelessWidget {
  final String selectedActivity;
  final ValueChanged<String> onChanged;

  const _ActivityDropdown({
    required this.selectedActivity,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedActivity,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: AppColors.subtext),
          selectedItemBuilder: (_) => activityTypes
              .map(
                (a) => Row(
                  children: [
                    Icon(a.icon, color: a.color, size: 20),
                    const SizedBox(width: 10),
                    Text(a.name,
                        style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              )
              .toList(),
          items: activityTypes
              .map(
                (a) => DropdownMenuItem<String>(
                  value: a.name,
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: a.color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(a.icon, color: a.color, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Text(a.name,
                          style: const TextStyle(
                              color: AppColors.text, fontSize: 14)),
                    ],
                  ),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
        ),
      ),
    );
  }
}

class NewActivitySheet extends StatelessWidget {
  const NewActivitySheet({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AthleteActivityCubit, AthleteActivityState>(
      builder: (context, state) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Handle
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
    
                const SizedBox(height: 20),
    
                Row(
                  children: [
                    BackButton(
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text('New Training Session',
                        style: TextStyle(
                            color: AppColors.text,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                            ],
                ),
    
                const SizedBox(height: 20),
    
                // ── Activity Type Dropdown
                const Text('Select Activity',
                    style: TextStyle(
                        color: AppColors.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                _ActivityDropdown(
                  selectedActivity: state.selectedActivity,
                  onChanged: (name) => context
                      .read<AthleteActivityCubit>()
                      .selectActivity(name),
                ),
    
                const SizedBox(height: 24),
    
                // ── Duration Chips
                const Text('Duration',
                    style: TextStyle(
                        color: AppColors.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: durationOptions.map((min) {
                    final selected = state.selectedDuration == min;
                    return GestureDetector(
                      onTap: () => context
                          .read<AthleteActivityCubit>()
                          .selectDuration(min),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primary
                              : AppColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selected
                                ? AppColors.primary
                                : AppColors.border,
                          ),
                        ),
                        child: Text('$min min',
                            style: TextStyle(
                                color: selected
                                    ? Colors.white
                                    : AppColors.subtext,
                                fontSize: 13,
                                fontWeight: selected
                                    ? FontWeight.bold
                                    : FontWeight.normal)),
                      ),
                    );
                  }).toList(),
                ),
    
                const SizedBox(height: 24),
    
                // ── Location
                const Text('Location',
                    style: TextStyle(
                        color: AppColors.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 13),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on_outlined,
                                size: 16, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                state.locationText.isEmpty
                                    ? 'Tap button to fetch location'
                                    : state.locationText,
                                style: TextStyle(
                                    color: state.locationText.isEmpty
                                        ? AppColors.textHint
                                        : AppColors.text,
                                    fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => context
                          .read<AthleteActivityCubit>()
                          .fetchLocation(),
                      child: Container(
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: state.isLoadingLocation
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.my_location,
                                color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
    
                const SizedBox(height: 28),
    
                // ── Start Button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      context.read<AthleteActivityCubit>().startSession();
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(
                      'Start ${state.selectedActivity} · ${state.selectedDuration} min',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
