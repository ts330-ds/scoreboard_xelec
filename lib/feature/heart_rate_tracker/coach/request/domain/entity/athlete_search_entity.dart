class AthleteSearchEntity {
  final int id;
  final String name;
  final String email;
  final String? sport;
  final String? avatarUrl;

  const AthleteSearchEntity({
    required this.id,
    required this.name,
    required this.email,
    this.sport,
    this.avatarUrl,
  });
}
