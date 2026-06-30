import '../../domain/entity/coach_request_entity.dart';

class CoachRequestModel extends CoachRequestEntity {
  const CoachRequestModel({
    required super.requestId,
    required super.coachId,
    required super.coachName,
    required super.coachEmail,
    required super.requestStatus,
    required super.requestDate,
    required super.coachSport,
    required super.coachOrganization,
  });

  factory CoachRequestModel.fromJson(Map<String, dynamic> json) {
    return CoachRequestModel(
      requestId: (json['request_id'] as num?)?.toInt() ?? 0,
      coachId: (json['coach_id'] as num?)?.toInt() ?? 0,
      coachName: json['coach_name']?.toString() ?? 'Unknown coach',
      coachEmail: json['coach_email']?.toString() ?? '',
      requestStatus: json['request_status']?.toString() ?? 'pending',
      requestDate: json['request_date']?.toString() ?? '',
      coachSport: json['coach_sport']?.toString() ?? '—',
      coachOrganization: json['coach_organization']?.toString() ?? '—',
    );
  }
}
