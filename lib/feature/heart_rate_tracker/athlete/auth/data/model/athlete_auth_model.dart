import '../../domain/entity/athlete_auth_entity.dart';

class AthleteAuthModel extends AthleteAuthEntity {
  const AthleteAuthModel({
    required super.id,
    required super.name,
    required super.email,
    required super.role,
    required super.token,
  });

  factory AthleteAuthModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;

    // Login response: data.user alag hai, token upar hai
    // Register response: sab data ke andar hai
    final user = data['user'] as Map<String, dynamic>? ?? data;

    return AthleteAuthModel(
      id:    user['id'] as int,
      name:  user['name'] as String,
      email: user['email'] as String,
      role:  user['role'] as String,
      token: data['token'] as String,
    );
  }
}
