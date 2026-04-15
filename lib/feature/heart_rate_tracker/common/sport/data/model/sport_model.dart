import '../../domain/entity/sport.dart';

class SportModel extends Sport {
  final String status;
  final DateTime createdAt;

  const SportModel({
    required super.id,
    required super.name,
    required this.status,
    required this.createdAt,
  });

  factory SportModel.fromJson(Map<String, dynamic> json) {
    return SportModel(
      id: json['id'] as int,
      name: json['name'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
