import 'package:equatable/equatable.dart';
import '../../domain/entity/athlete_search_entity.dart';

enum CoachRequestStatus { initial, loading, loaded, loadingMore, empty, sending, sent, error }

class CoachRequestState extends Equatable {
  final CoachRequestStatus status;
  final List<AthleteSearchEntity> athletes;
  final List<int> remainingPages;
  final String? errorMessage;

  const CoachRequestState({
    this.status = CoachRequestStatus.initial,
    this.athletes = const [],
    this.remainingPages = const [],
    this.errorMessage,
  });

  bool get hasMore => remainingPages.isNotEmpty;

  CoachRequestState copyWith({
    CoachRequestStatus? status,
    List<AthleteSearchEntity>? athletes,
    List<int>? remainingPages,
    String? errorMessage,
  }) =>
      CoachRequestState(
        status: status ?? this.status,
        athletes: athletes ?? this.athletes,
        remainingPages: remainingPages ?? this.remainingPages,
        errorMessage: errorMessage ?? this.errorMessage,
      );

  @override
  List<Object?> get props => [status, athletes, remainingPages, errorMessage];
}
