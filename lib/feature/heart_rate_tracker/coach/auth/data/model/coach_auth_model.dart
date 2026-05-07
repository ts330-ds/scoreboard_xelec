import '../../domain/entity/coach_auth_entity.dart';

class CoachAuthModel extends CoachAuthEntity {
  const CoachAuthModel({
    required super.id,
    required super.name,
    required super.email,
    required super.role,
    required super.token,
  });

  factory CoachAuthModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    // Login:        data.token  +  data.user.{id, name, email, role}
    // Registration: data.{id, name, email, role, token}
    final user = data['user'] as Map<String, dynamic>? ?? data;
    return CoachAuthModel(
      id:    user['id'] as int,
      name:  user['name'] as String,
      email: user['email'] as String,
      role:  user['role'] as String,
      token: data['token'] as String,
    );
  }
}
