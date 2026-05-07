import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:xelex_esp/core/theme/app_colors.dart';
import '../../domain/entity/athlete_search_entity.dart';
import '../cubit/coach_request_cubit.dart';
import '../cubit/coach_request_state.dart';

class CoachSendRequestMobile extends StatelessWidget {
  final AthleteSearchEntity athlete;

  const CoachSendRequestMobile({super.key, required this.athlete});

  @override
  Widget build(BuildContext context) {
    return BlocListener<CoachRequestCubit, CoachRequestState>(
      listener: (context, state) {
        if (state.status == CoachRequestStatus.sent) {
          _showSuccessSheet(context);
        } else if (state.status == CoachRequestStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.errorMessage ?? 'Something went wrong'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ));
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          title: const Text('Send Request'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    _AthleteCard(athlete: athlete),
                    const SizedBox(height: 24),
                    _InfoBox(),
                  ],
                ),
              ),
            ),
            _SendButton(athlete: athlete),
          ],
        ),
      ),
    );
  }

  void _showSuccessSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (_) => _SuccessSheet(onDone: () {
        context.pop(); // close sheet
        context.pop(); // back to search
        context.pop(); // back to wherever (optional)
      }),
    );
  }
}

class _AthleteCard extends StatelessWidget {
  final AthleteSearchEntity athlete;
  const _AthleteCard({required this.athlete});

  @override
  Widget build(BuildContext context) {
    final initials = athlete.name.trim().split(' ').map((w) => w[0]).take(2).join().toUpperCase();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            athlete.name,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            athlete.email,
            style: const TextStyle(color: AppColors.subtext, fontSize: 14),
          ),
          // const SizedBox(height: 14),
          // Container(
          //   padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          //   decoration: BoxDecoration(
          //     color: AppColors.primaryLight,
          //     borderRadius: BorderRadius.circular(20),
          //   ),
          //   child: Row(
          //     mainAxisSize: MainAxisSize.min,
          //     children: [
          //       const Icon(Icons.sports, color: AppColors.primary, size: 16),
          //       const SizedBox(width: 6),
          //       Text(
          //         athlete.sport,
          //         style: const TextStyle(
          //           color: AppColors.primary,
          //           fontWeight: FontWeight.w600,
          //           fontSize: 13,
          //         ),
          //       ),
          //     ],
          //   ),
          // ),
        ],
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warningBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: AppColors.warning, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'A request will be sent to this athlete. Once they accept, you will be able to monitor their health data.',
              style: TextStyle(color: AppColors.warning, fontSize: 13, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  final AthleteSearchEntity athlete;
  const _SendButton({required this.athlete});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CoachRequestCubit, CoachRequestState>(
      builder: (context, state) {
        final isSending = state.status == CoachRequestStatus.sending;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: isSending
                    ? null
                    : () => context.read<CoachRequestCubit>().sendRequest(athlete.id),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                ),
                child: isSending
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send_rounded, size: 20),
                          SizedBox(width: 10),
                          Text(
                            'Send Request',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SuccessSheet extends StatelessWidget {
  final VoidCallback onDone;
  const _SuccessSheet({required this.onDone});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppColors.successBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_outline, color: AppColors.success, size: 48),
          ),
          const SizedBox(height: 20),
          const Text(
            'Request Sent!',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'The athlete will be notified.\nYou can monitor their data once they accept.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.subtext, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: onDone,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Done', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
