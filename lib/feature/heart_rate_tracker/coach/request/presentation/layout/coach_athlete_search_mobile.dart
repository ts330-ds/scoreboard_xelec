import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:xelex_esp/core/theme/app_colors.dart';
import 'package:xelex_esp/router/heart_tracker_path.dart';
import '../../domain/entity/athlete_search_entity.dart';
import '../cubit/coach_request_cubit.dart';
import '../cubit/coach_request_state.dart';
import '../widget/athlete_search_tile.dart';

class CoachAthleteSearchMobile extends StatefulWidget {
  const CoachAthleteSearchMobile({super.key});

  @override
  State<CoachAthleteSearchMobile> createState() => _CoachAthleteSearchMobileState();
}

class _CoachAthleteSearchMobileState extends State<CoachAthleteSearchMobile> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Find Athlete'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          _SearchBar(
            controller: _searchController,
            onChanged: (q) => context.read<CoachRequestCubit>().searchAthletes(q),
          ),
          Expanded(
            child: BlocBuilder<CoachRequestCubit, CoachRequestState>(
              builder: (context, state) {
                if (state.status == CoachRequestStatus.loading) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }
                if (state.status == CoachRequestStatus.empty) {
                  return _NoResults(query: _searchController.text);
                }
                if (state.status == CoachRequestStatus.error) {
                  return Center(
                    child: Text(
                      state.errorMessage ?? 'Something went wrong',
                      style: const TextStyle(color: AppColors.subtext),
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                if (state.athletes.isNotEmpty) {
                  return _ResultsList(
                    athletes: state.athletes,
                    hasMore: state.hasMore,
                    isLoadingMore: state.status == CoachRequestStatus.loadingMore,
                  );
                }
                return _EmptyPrompt();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        autofocus: true,
        style: const TextStyle(color: AppColors.text),
        decoration: InputDecoration(
          hintText: 'Search by name or ID...',
          hintStyle: const TextStyle(color: AppColors.textHint),
          prefixIcon: const Icon(Icons.search, color: AppColors.subtext),
          suffixIcon: ValueListenableBuilder(
            valueListenable: controller,
            builder: (_, value, __) => value.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close, color: AppColors.subtext, size: 20),
                    onPressed: () {
                      controller.clear();
                      onChanged('');
                    },
                  )
                : const SizedBox.shrink(),
          ),
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _ResultsList extends StatefulWidget {
  final List<AthleteSearchEntity> athletes;
  final bool hasMore;
  final bool isLoadingMore;

  const _ResultsList({
    required this.athletes,
    required this.hasMore,
    required this.isLoadingMore,
  });

  @override
  State<_ResultsList> createState() => _ResultsListState();
}

class _ResultsListState extends State<_ResultsList> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<CoachRequestCubit>().loadNextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: widget.athletes.length + (widget.hasMore ? 1 : 0),
      itemBuilder: (_, i) {
        if (i == widget.athletes.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }
        return AthleteSearchTile(
          athlete: widget.athletes[i],
          onTap: () => context.push(
            HeartTrackerPaths.coachSendRequest,
            extra: widget.athletes[i],
          ),
        );
      },
    );
  }
}

class _EmptyPrompt extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_search, size: 52, color: AppColors.primary),
          ),
          const SizedBox(height: 20),
          const Text(
            'Find an Athlete',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Search by athlete name or ID\nto send a connection request',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.subtext, fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  final String query;
  const _NoResults({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off, size: 52, color: AppColors.subtext),
          const SizedBox(height: 16),
          const Text(
            'No athletes found',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No results for "$query"',
            style: const TextStyle(color: AppColors.subtext, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
