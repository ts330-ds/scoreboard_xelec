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
      requestId: json['request_id'] as int,
      coachId: json['coach_id'] as int,
      coachName: json['coach_name'] as String,
      coachEmail: json['coach_email'] as String,
      requestStatus: json['request_status'] as String,
      requestDate: json['request_date'] as String,
      coachSport: json['coach_sport'] as String,
      coachOrganization: json['coach_organization'] as String,
    );
  }
}
