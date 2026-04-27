class AthleteAuthEntity {
  final int id;
  final String name;
  final String email;
  final String role;
  final String token;

  const AthleteAuthEntity({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.token,
  });
}
