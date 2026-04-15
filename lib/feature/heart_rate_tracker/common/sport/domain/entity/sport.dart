import 'package:equatable/equatable.dart';

class Sport extends Equatable {
  final int id;
  final String name;

  const Sport({
    required this.id,
    required this.name,
  });

  @override
  List<Object?> get props => [id, name];
}
