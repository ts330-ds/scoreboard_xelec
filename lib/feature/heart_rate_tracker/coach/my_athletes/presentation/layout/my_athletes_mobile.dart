import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:xelex_esp/core/theme/app_colors.dart';
import 'package:xelex_esp/router/heart_tracker_path.dart';
import '../../domain/entity/my_athlete_entity.dart';
import '../cubit/my_athletes_cubit.dart';
import '../cubit/my_athletes_state.dart';
import '../widget/athlete_list_tile.dart';

class MyAthletesMobile extends StatefulWidget {
  const MyAthletesMobile({super.key});

  @override
  State<MyAthletesMobile> createState() => _MyAthletesMobileState();
}

class _MyAthletesMobileState extends State<MyAthletesMobile> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<MyAthletesCubit>().loadAthletes();

    // When user scrolls near the bottom → trigger loadMore
    _scrollController.addListener(() {
      final pos = _scrollController.position;
      if (pos.pixels >= pos.maxScrollExtent - 200) {
        context.read<MyAthletesCubit>().loadMore();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('My Athletes'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          _SearchBar(
            controller: _searchController,
            onChanged: (q) => context.read<MyAthletesCubit>().search(q),
          ),
          Expanded(
            child: BlocBuilder<MyAthletesCubit, MyAthletesState>(
              builder: (context, state) {
                return switch (state.status) {
                  MyAthletesStatus.initial ||
                  MyAthletesStatus.loading =>
                    const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  MyAthletesStatus.error => _ErrorView(
                      message: state.errorMessage ?? 'Something went wrong',
                      onRetry: () =>
                          context.read<MyAthletesCubit>().loadAthletes(),
                    ),
                  MyAthletesStatus.empty => _searchController.text.isNotEmpty
                      ? _NoSearchResults(query: _searchController.text)
                      : _EmptyView(),
                  MyAthletesStatus.loaded ||
                  MyAthletesStatus.loadingMore =>
                    _AthleteList(
                      athletes: state.athletes,
                      scrollController: _scrollController,
                      isLoadingMore:
                          state.status == MyAthletesStatus.loadingMore,
                      hasMore: state.hasMore,
                      totalRecords: state.totalRecords,
                    ),
                };
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Search Bar ────────────────────────────────────────────────────────────────

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
        style: const TextStyle(color: AppColors.text),
        decoration: InputDecoration(
          hintText: 'Search by name or ID...',
          hintStyle: const TextStyle(color: AppColors.textHint),
          prefixIcon: const Icon(Icons.search, color: AppColors.subtext),
          suffixIcon: ValueListenableBuilder(
            valueListenable: controller,
            builder: (_, value, __) => value.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close,
                        color: AppColors.subtext, size: 20),
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

// ── Athlete List ──────────────────────────────────────────────────────────────

class _AthleteList extends StatelessWidget {
  final List<MyAthleteEntity> athletes;
  final ScrollController scrollController;
  final bool isLoadingMore;
  final bool hasMore;
  final int totalRecords;

  const _AthleteList({
    required this.athletes,
    required this.scrollController,
    required this.isLoadingMore,
    required this.hasMore,
    required this.totalRecords,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Record count header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Text(
                '$totalRecords athlete${totalRecords == 1 ? '' : 's'}',
                style: const TextStyle(
                  color: AppColors.subtext,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            // +1 for the loading indicator at the bottom
            itemCount: athletes.length + (isLoadingMore ? 1 : 0),
            itemBuilder: (_, i) {
              if (i == athletes.length) {
                // Last item — show spinner while fetching next page
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                );
              }
              return AthleteListTile(
                athlete: athletes[i],
                onTap: () => context.push(
                  HeartTrackerPaths.coachAthleteDetail,
                  extra: {
                    'preview': athletes[i],
                    'listCubit': context.read<MyAthletesCubit>(),
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Empty / Error / No-results ────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
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
            child: const Icon(Icons.people_outline,
                size: 52, color: AppColors.primary),
          ),
          const SizedBox(height: 20),
          const Text(
            'No Athletes Yet',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Send requests to athletes to\nadd them to your roster',
            textAlign: TextAlign.center,
            style:
                TextStyle(color: AppColors.subtext, fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _NoSearchResults extends StatelessWidget {
  final String query;
  const _NoSearchResults({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off, size: 52, color: AppColors.subtext),
          const SizedBox(height: 16),
          const Text(
            'No results found',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No athlete matches "$query"',
            style: const TextStyle(color: AppColors.subtext, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(color: AppColors.subtext, fontSize: 14),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
