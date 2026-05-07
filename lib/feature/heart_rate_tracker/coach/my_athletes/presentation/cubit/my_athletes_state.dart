import 'package:equatable/equatable.dart';
import '../../domain/entity/my_athlete_entity.dart';

enum MyAthletesStatus { initial, loading, loadingMore, loaded, empty, error }

class MyAthletesState extends Equatable {
  final MyAthletesStatus status;
  final List<MyAthleteEntity> athletes;
  final String? errorMessage;
  final int currentPage;
  final int totalRecords;
  final bool hasMore;

  const MyAthletesState({
    this.status = MyAthletesStatus.initial,
    this.athletes = const [],
    this.errorMessage,
    this.currentPage = 1,
    this.totalRecords = 0,
    this.hasMore = false,
  });

  MyAthletesState copyWith({
    MyAthletesStatus? status,
    List<MyAthleteEntity>? athletes,
    String? errorMessage,
    int? currentPage,
    int? totalRecords,
    bool? hasMore,
  }) =>
      MyAthletesState(
        status: status ?? this.status,
        athletes: athletes ?? this.athletes,
        errorMessage: errorMessage ?? this.errorMessage,
        currentPage: currentPage ?? this.currentPage,
        totalRecords: totalRecords ?? this.totalRecords,
        hasMore: hasMore ?? this.hasMore,
      );

  @override
  List<Object?> get props =>
      [status, athletes, errorMessage, currentPage, totalRecords, hasMore];
}
