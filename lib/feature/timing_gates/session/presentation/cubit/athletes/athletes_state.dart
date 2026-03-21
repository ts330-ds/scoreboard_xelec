import 'package:equatable/equatable.dart';
import 'package:xelex_esp/feature/timing_gates/session/data/model/athlete_model.dart';

class AthletesState extends Equatable {
  final List<AthleteModel> athletes;
  final bool isLoading;
  final bool isImporting;
  final bool hasMore;
  final int currentPage;
  final String searchQuery;
  final String teamFilter;
  final List<String> allTeams;
  final List<AthleteModel> importPreview;
  final int totalCount;

  const AthletesState({
    this.athletes = const [],
    this.isLoading = false,
    this.isImporting = false,
    this.hasMore = false,
    this.currentPage = 0,
    this.searchQuery = '',
    this.teamFilter = '',
    this.allTeams = const [],
    this.importPreview = const [],
    this.totalCount = 0,
  });

  bool get hasImportPreview => importPreview.isNotEmpty;

  AthletesState copyWith({
    List<AthleteModel>? athletes,
    bool? isLoading,
    bool? isImporting,
    bool? hasMore,
    int? currentPage,
    String? searchQuery,
    String? teamFilter,
    List<String>? allTeams,
    List<AthleteModel>? importPreview,
    int? totalCount,
    bool clearImportPreview = false,
  }) {
    return AthletesState(
      athletes: athletes ?? this.athletes,
      isLoading: isLoading ?? this.isLoading,
      isImporting: isImporting ?? this.isImporting,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      searchQuery: searchQuery ?? this.searchQuery,
      teamFilter: teamFilter ?? this.teamFilter,
      allTeams: allTeams ?? this.allTeams,
      importPreview: clearImportPreview ? [] : (importPreview ?? this.importPreview),
      totalCount: totalCount ?? this.totalCount,
    );
  }

  @override
  List<Object?> get props => [
        athletes,
        isLoading,
        isImporting,
        hasMore,
        currentPage,
        searchQuery,
        teamFilter,
        allTeams,
        importPreview,
        totalCount,
      ];
}
