import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/core/theme/app_colors.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/activity/presentation/cubit/athlete_activity_cubit.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/activity/presentation/cubit/athlete_activity_state.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/common/sport/presentation/cubit/sport_cubit.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/common/sport/presentation/cubit/sport_state.dart';

class _ActivityDropdown extends StatelessWidget {
  final String selectedActivity;
  final ValueChanged<String> onChanged;

  const _ActivityDropdown({
    required this.selectedActivity,
    required this.onChanged,
  });

  static const _sportColor = AppColors.primary;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SportCubit, SportState>(
      builder: (context, sportState) {
        if (sportState.status == SportStatus.loading ||
            sportState.status == SportStatus.initial) {
          return Container(
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        if (sportState.status == SportStatus.error ||
            sportState.sports.isEmpty) {
          return Container(
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                const Icon(Icons.error_outline,
                    size: 16, color: AppColors.error),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Failed to load sports',
                      style:
                          TextStyle(color: AppColors.subtext, fontSize: 13)),
                ),
                GestureDetector(
                  onTap: () => context.read<SportCubit>().getSports(),
                  child: const Icon(Icons.refresh,
                      size: 18, color: AppColors.primary),
                ),
              ],
            ),
          );
        }

        final sports = sportState.sports;
        final isValid = sports.any((s) => s.name == selectedActivity);
        if (!isValid && sports.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            onChanged(sports.first.name);
          });
        }

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: isValid ? selectedActivity : null,
              isExpanded: true,
              hint: const Text('Select sport',
                  style: TextStyle(color: AppColors.textHint, fontSize: 14)),
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: AppColors.subtext),
              selectedItemBuilder: (_) => sports
                  .map(
                    (s) => Row(
                      children: [
                        Icon(Icons.sports, color: _sportColor, size: 20),
                        const SizedBox(width: 10),
                        Text(s.name,
                            style: const TextStyle(
                                color: AppColors.text,
                                fontSize: 14,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  )
                  .toList(),
              items: sports
                  .map(
                    (s) => DropdownMenuItem<String>(
                      value: s.name,
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: _sportColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.sports,
                                color: _sportColor, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Text(s.name,
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
      },
    );
  }
}

class NewActivitySheet extends StatefulWidget {
  const NewActivitySheet({super.key});

  @override
  State<NewActivitySheet> createState() => _NewActivitySheetState();
}

class _NewActivitySheetState extends State<NewActivitySheet> {
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<AthleteActivityCubit>().resetTaskForm();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AthleteActivityCubit, AthleteActivityState>(
      listenWhen: (prev, curr) =>
          prev.taskError != curr.taskError && curr.taskError != null,
      listener: (context, state) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.taskError!),
            backgroundColor: Colors.red.shade700,
          ),
        );
      },
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

                // ── Task Name
                const Text('Task Name',
                    style: TextStyle(
                        color: AppColors.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TextField(
                    controller: _nameController,
                    onChanged: (v) =>
                        context.read<AthleteActivityCubit>().setTaskName(v),
                    style: const TextStyle(color: AppColors.text, fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'e.g. 1600 m running',
                      hintStyle:
                          TextStyle(color: AppColors.textHint, fontSize: 14),
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 14, vertical: 13),
                      border: InputBorder.none,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

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

                // ── Create Task Button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: state.isCreatingTask
                        ? null
                        : () async {
                            final created = await context
                                .read<AthleteActivityCubit>()
                                .createTask();
                            if (created && context.mounted) {
                              Navigator.of(context).pop(true);
                            }
                          },
                    icon: state.isCreatingTask
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.add_task_rounded),
                    label: Text(
                      state.isCreatingTask ? 'Creating task...' : 'Create Task',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.primary.withOpacity(0.6),
                      disabledForegroundColor: Colors.white,
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

