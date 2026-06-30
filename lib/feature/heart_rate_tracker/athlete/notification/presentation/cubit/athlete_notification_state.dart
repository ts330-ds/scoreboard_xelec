import 'package:equatable/equatable.dart';
import '../../domain/entity/coach_request_entity.dart';

enum AthleteNotificationStatus { initial, loading, loaded, error }

class AthleteNotificationState extends Equatable {
  final AthleteNotificationStatus status;
  final List<CoachRequestEntity> requests;
  final String? errorMessage;
  final bool isResponding;

  /// One-shot signals — set on a single emit, then cleared on the next.
  final String? responseError;
  final String? successMessage;

  const AthleteNotificationState({
    this.status = AthleteNotificationStatus.initial,
    this.requests = const [],
    this.errorMessage,
    this.isResponding = false,
    this.responseError,
    this.successMessage,
  });

  AthleteNotificationState copyWith({
    AthleteNotificationStatus? status,
    List<CoachRequestEntity>? requests,
    String? errorMessage,
    bool? isResponding,
    String? responseError,
    String? successMessage,
  }) =>
      AthleteNotificationState(
        status: status ?? this.status,
        requests: requests ?? this.requests,
        errorMessage: errorMessage ?? this.errorMessage,
        isResponding: isResponding ?? this.isResponding,
        // One-shot: not carried over unless explicitly passed.
        responseError: responseError,
        successMessage: successMessage,
      );

  @override
  List<Object?> get props => [
        status,
        requests,
        errorMessage,
        isResponding,
        responseError,
        successMessage,
      ];
}
