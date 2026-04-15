import 'package:equatable/equatable.dart';
import '../../domain/entity/sport.dart';

enum SportStatus { initial, loading, loaded, error }

class SportState extends Equatable {
  final SportStatus status;
  final List<Sport> sports;
  final String? errorMessage;

  const SportState({
    this.status = SportStatus.initial,
    this.sports = const [],
    this.errorMessage,
  });

  SportState copyWith({
    SportStatus? status,
    List<Sport>? sports,
    String? errorMessage,
  }) {
    return SportState(
      status: status ?? this.status,
      sports: sports ?? this.sports,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, sports, errorMessage];
}
