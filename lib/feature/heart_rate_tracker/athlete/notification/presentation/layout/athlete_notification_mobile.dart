import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/core/theme/app_colors.dart';
import 'package:xelex_esp/responsive/adaptive_scaffold.dart';
import '../cubit/athlete_notification_cubit.dart';
import '../cubit/athlete_notification_state.dart';
import '../../domain/entity/coach_request_entity.dart';

class AthleteNotificationMobile extends StatelessWidget {
  const AthleteNotificationMobile({super.key});

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      title: 'Coach Requests',
      appBarBackground: AppColors.primary,
      bodyBackground: AppColors.bg,
      body: BlocListener<AthleteNotificationCubit, AthleteNotificationState>(
        listenWhen: (prev, curr) =>
            curr.successMessage != null &&
            curr.successMessage != prev.successMessage,
        listener: (context, state) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.successMessage!),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        },
        child: BlocBuilder<AthleteNotificationCubit, AthleteNotificationState>(
          builder: (context, state) {
          if (state.status == AthleteNotificationStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == AthleteNotificationStatus.error) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppColors.error, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      state.errorMessage ?? 'Something went wrong',
                      textAlign: TextAlign.center,
                      style:
                          const TextStyle(color: AppColors.subtext, fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () =>
                          context.read<AthleteNotificationCubit>().fetchRequests(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state.requests.isEmpty) {
            return RefreshIndicator(
              onRefresh: () =>
                  context.read<AthleteNotificationCubit>().fetchRequests(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
                  Center(
                    child: Text(
                      'No coach requests yet',
                      style:
                          TextStyle(color: AppColors.subtext, fontSize: 14),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () =>
                context.read<AthleteNotificationCubit>().fetchRequests(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.requests.length,
              itemBuilder: (context, index) {
                final request = state.requests[index];
                final isPending = request.requestStatus == 'pending';
                return GestureDetector(
                  onTap: isPending
                      ? () => _showRequestActionSheet(context, request)
                      : null,
                  child: _CoachRequestCard(request: request),
                );
              },
            ),
          );
        },
        ),
      ),
    );
  }

  void _showRequestActionSheet(
      BuildContext context, CoachRequestEntity request) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<AthleteNotificationCubit>(),
        child: _RequestActionSheet(request: request),
      ),
    );
  }
}

// ── Request Action Bottom Sheet ──────────────────────────────────────────────
class _RequestActionSheet extends StatelessWidget {
  final CoachRequestEntity request;

  const _RequestActionSheet({required this.request});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: BlocConsumer<AthleteNotificationCubit, AthleteNotificationState>(
          // One-shot: pop only when a success signal newly arrives, so a
          // follow-up refresh emit can never trigger a second pop (which would
          // otherwise pop the underlying screen → blank screen).
          listenWhen: (prev, curr) =>
              curr.successMessage != null &&
              curr.successMessage != prev.successMessage,
          listener: (context, state) {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
          builder: (context, state) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),

                // Coach avatar + name
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person,
                      color: AppColors.primary, size: 28),
                ),
                const SizedBox(height: 12),
                Text(
                  request.coachName,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  request.coachEmail,
                  style: const TextStyle(
                      color: AppColors.subtext, fontSize: 13),
                ),
                const SizedBox(height: 20),

                // Info chips
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _InfoChip(
                        icon: Icons.directions_run,
                        label: request.coachSport),
                    const SizedBox(width: 8),
                    _InfoChip(
                        icon: Icons.business,
                        label: request.coachOrganization),
                  ],
                ),
                const SizedBox(height: 8),

                // Error message
                if (state.responseError != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    state.responseError!,
                    style: const TextStyle(
                        color: AppColors.error, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 24),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: state.isResponding
                            ? null
                            : () => context
                                .read<AthleteNotificationCubit>()
                                .rejectRequest(request.requestId),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: state.isResponding
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.error),
                              )
                            : const Text('Reject',
                                style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: state.isResponding
                            ? null
                            : () => context
                                .read<AthleteNotificationCubit>()
                                .acceptRequest(request.requestId),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: state.isResponding
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Accept',
                                style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── Info Chip ────────────────────────────────────────────────────────────────
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

// ── Coach Request Card ───────────────────────────────────────────────────────
class _CoachRequestCard extends StatelessWidget {
  final CoachRequestEntity request;

  const _CoachRequestCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final isPending = request.requestStatus == 'pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isPending
            ? AppColors.primary.withOpacity(0.05)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPending
              ? AppColors.primary.withOpacity(0.25)
              : AppColors.border,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.sports,
                      color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.coachName,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        request.coachEmail,
                        style: const TextStyle(
                            color: AppColors.subtext, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                _StatusBadge(status: request.requestStatus),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 12),
            _InfoRow(
                icon: Icons.directions_run,
                label: 'Sport',
                value: request.coachSport),
            const SizedBox(height: 6),
            _InfoRow(
                icon: Icons.business,
                label: 'Organization',
                value: request.coachOrganization),
            const SizedBox(height: 6),
            _InfoRow(
                icon: Icons.calendar_today,
                label: 'Date',
                value: _formatDate(request.requestDate)),
          ],
        ),
      ),
    );
  }

  String _formatDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return isoDate;
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.subtext),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: const TextStyle(color: AppColors.subtext, fontSize: 12),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
                color: AppColors.text,
                fontSize: 12,
                fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final isPending = status == 'pending';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isPending
            ? AppColors.warning.withOpacity(0.15)
            : AppColors.success.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: isPending ? AppColors.warning : AppColors.success,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
