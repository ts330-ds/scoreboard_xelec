import 'package:equatable/equatable.dart';
import '../../domain/entity/coach_request_entity.dart';

enum AthleteNotificationStatus { initial, loading, loaded, error }

class AthleteNotificationState extends Equatable {
  final AthleteNotificationStatus status;
  final List<CoachRequestEntity> requests;
  final String? errorMessage;
  final bool isResponding;
  final String? responseError;
  final int? respondedRequestId;
  final String? successMessage;

  const AthleteNotificationState({
    this.status = AthleteNotificationStatus.initial,
    this.requests = const [],
    this.errorMessage,
    this.isResponding = false,
    this.responseError,
    this.respondedRequestId,
    this.successMessage,
  });

  AthleteNotificationState copyWith({
    AthleteNotificationStatus? status,
    List<CoachRequestEntity>? requests,
    String? errorMessage,
    bool? isResponding,
    String? responseError,
    int? respondedRequestId,
    String? successMessage,
  }) =>
      AthleteNotificationState(
        status: status ?? this.status,
        requests: requests ?? this.requests,
        errorMessage: errorMessage ?? this.errorMessage,
        isResponding: isResponding ?? this.isResponding,
        responseError: responseError,
        respondedRequestId: respondedRequestId ?? this.respondedRequestId,
        successMessage: successMessage,
      );

  @override
  List<Object?> get props => [
        status,
        requests,
        errorMessage,
        isResponding,
        responseError,
        respondedRequestId,
        successMessage,
      ];
}
