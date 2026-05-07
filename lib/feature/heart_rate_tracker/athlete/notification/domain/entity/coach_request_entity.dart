class CoachRequestEntity {
  final int requestId;
  final int coachId;
  final String coachName;
  final String coachEmail;
  final String requestStatus;
  final String requestDate;
  final String coachSport;
  final String coachOrganization;

  const CoachRequestEntity({
    required this.requestId,
    required this.coachId,
    required this.coachName,
    required this.coachEmail,
    required this.requestStatus,
    required this.requestDate,
    required this.coachSport,
    required this.coachOrganization,
  });
}
