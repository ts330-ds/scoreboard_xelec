import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/feature/timing_gates/session/presentation/cubit/athletes/athletes_cubit.dart';
import 'package:xelex_esp/feature/timing_gates/session/presentation/cubit/athletes/athletes_state.dart';
import 'package:xelex_esp/feature/timing_gates/session/data/model/athlete_model.dart';

class TimingGateAthletesMobile extends StatefulWidget {
  const TimingGateAthletesMobile({super.key});

  @override
  State<TimingGateAthletesMobile> createState() =>
      _TimingGateAthletesMobileState();
}

class _TimingGateAthletesMobileState extends State<TimingGateAthletesMobile> {
  // ── Design tokens ─────────────────────────────────────────────────────────
  static const _bg = Color(0xFFF4F6F9);
  static const _surface = Color(0xFFFFFFFF);
  static const _border = Color(0xFFDDE3EC);
  static const _primary = Color(0xFF1565C0);
  static const _primaryLight = Color(0xFFE3F2FD);
  static const _text = Color(0xFF1E2A3A);
  static const _subtext = Color(0xFF6B7A8D);
  static const _error = Color(0xFFDC2626);
  static const _success = Color(0xFF16A34A);

  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      context.read<AthletesCubit>().loadNextPage();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AthletesCubit, AthletesState>(
      listenWhen: (prev, curr) =>
          !prev.hasImportPreview && curr.hasImportPreview,
      listener: (context, state) {
        if (state.hasImportPreview) {
          _showImportPreviewDialog(context, state.importPreview);
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: _bg,
          appBar: _buildAppBar(context, state),
          floatingActionButton: _buildFab(context),
          body: Column(
            children: [
              _importZone(context, state),
              _searchAndFilter(context, state),
              Expanded(child: _buildBody(context, state)),
            ],
          ),
        );
      },
    );  // BlocConsumer
  }

  // ── AppBar ─────────────────────────────────────────────────────────────────

  AppBar _buildAppBar(BuildContext context, AthletesState state) {
    return AppBar(
      backgroundColor: _surface,
      elevation: 0,
      centerTitle: false,
      title: Row(
        children: [
          const Text(
            'Athletes',
            style: TextStyle(
              color: _text,
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
          ),
          if (state.totalCount > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${state.totalCount}',
                style: const TextStyle(
                  color: _primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: _border),
      ),
    );
  }

  // ── FAB ───────────────────────────────────────────────────────────────────

  Widget _buildFab(BuildContext context) {
    return FloatingActionButton(
      backgroundColor: _primary,
      onPressed: () => _showAddEditModal(context, null),
      child: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
    );
  }

  // ── Import Zone ───────────────────────────────────────────────────────────

  Widget _importZone(BuildContext context, AthletesState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: GestureDetector(
        onTap: state.isImporting
            ? null
            : () => context.read<AthletesCubit>().importFromFile(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: state.isImporting ? _primaryLight : _surface,
            border: Border.all(
              color: state.isImporting ? _primary : _border,
              width: state.isImporting ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (state.isImporting)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _primary,
                  ),
                )
              else
                const Icon(Icons.upload_file_rounded, color: _primary, size: 22),
              const SizedBox(width: 10),
              Text(
                state.isImporting
                    ? 'Reading file...'
                    : 'Import CSV / Excel (.csv, .xlsx)',
                style: TextStyle(
                  color: state.isImporting ? _primary : _subtext,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Search & Filter ───────────────────────────────────────────────────────

  Widget _searchAndFilter(BuildContext context, AthletesState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: _surface,
                border: Border.all(color: _border),
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (q) =>
                    context.read<AthletesCubit>().updateSearch(q),
                style: const TextStyle(fontSize: 14, color: _text),
                decoration: const InputDecoration(
                  hintText: 'Search athletes...',
                  hintStyle: TextStyle(color: _subtext, fontSize: 14),
                  prefixIcon: Icon(Icons.search, color: _subtext, size: 18),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          if (state.allTeams.isNotEmpty) ...[
            const SizedBox(width: 8),
            Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: state.teamFilter.isNotEmpty ? _primaryLight : _surface,
                border: Border.all(
                  color: state.teamFilter.isNotEmpty ? _primary : _border,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: state.teamFilter.isEmpty ? null : state.teamFilter,
                  hint: const Text(
                    'Team',
                    style: TextStyle(fontSize: 13, color: _subtext),
                  ),
                  icon: const Icon(Icons.keyboard_arrow_down_rounded,
                      color: _subtext, size: 18),
                  items: [
                    const DropdownMenuItem(
                      value: '',
                      child: Text('All Teams',
                          style: TextStyle(fontSize: 13, color: _text)),
                    ),
                    ...state.allTeams.map(
                      (t) => DropdownMenuItem(
                        value: t,
                        child: Text(t,
                            style: const TextStyle(
                                fontSize: 13, color: _text)),
                      ),
                    ),
                  ],
                  onChanged: (t) =>
                      context.read<AthletesCubit>().updateTeamFilter(t ?? ''),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Body ──────────────────────────────────────────────────────────────────

  Widget _buildBody(BuildContext context, AthletesState state) {
    if (state.isLoading && state.athletes.isEmpty) {
      return const Center(
          child: CircularProgressIndicator(color: _primary));
    }

    if (state.athletes.isEmpty) return _emptyState(context);

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: state.athletes.length + (state.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == state.athletes.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
                child: CircularProgressIndicator(
                    color: _primary, strokeWidth: 2)),
          );
        }
        return _athleteCard(context, state.athletes[index]);
      },
    );
  }

  // ── Empty State ───────────────────────────────────────────────────────────

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
                color: _primaryLight, shape: BoxShape.circle),
            child: const Icon(Icons.group_outlined, size: 40, color: _primary),
          ),
          const SizedBox(height: 16),
          const Text('No athletes yet',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _text)),
          const SizedBox(height: 6),
          const Text(
            'Add athletes manually or import\na CSV / Excel file.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: _subtext, height: 1.5),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => context.read<AthletesCubit>().importFromFile(),
            icon: const Icon(Icons.upload_file_rounded, size: 18),
            label: const Text('Import File'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _primary,
              side: const BorderSide(color: _primary),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Athlete Card ──────────────────────────────────────────────────────────

  Widget _athleteCard(BuildContext context, AthleteModel athlete) {
    final metaLine1 = [
      if (athlete.athleteId.isNotEmpty) athlete.athleteId,
      if (athlete.bib.isNotEmpty) 'BIB ${athlete.bib}',
      if (athlete.team.isNotEmpty) athlete.team,
    ].join('  ·  ');

    final metaLine2 = [
      if (athlete.sex.isNotEmpty) athlete.sex,
      if (athlete.discipline.isNotEmpty) athlete.discipline,
      if (athlete.dob.isNotEmpty) athlete.dob,
      if (athlete.age != null) '${athlete.age} yrs',
    ].join('  ·  ');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _surface,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                  color: _primaryLight, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text(
                athlete.initials,
                style: const TextStyle(
                    color: _primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(athlete.fullName,
                            style: const TextStyle(
                                color: _text,
                                fontWeight: FontWeight.w600,
                                fontSize: 15),
                            overflow: TextOverflow.ellipsis),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('${athlete.trials} trials',
                            style: const TextStyle(
                                color: _success,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  if (metaLine1.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(metaLine1,
                        style: const TextStyle(color: _subtext, fontSize: 12),
                        overflow: TextOverflow.ellipsis),
                  ],
                  if (metaLine2.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(metaLine2,
                        style: const TextStyle(color: _subtext, fontSize: 11),
                        overflow: TextOverflow.ellipsis),
                  ],
                ],
              ),
            ),
            // Action buttons
            Column(
              children: [
                _iconBtn(Icons.edit_outlined, _primary,
                    () => _showAddEditModal(context, athlete)),
                const SizedBox(height: 4),
                _iconBtn(Icons.delete_outline_rounded, _error,
                    () => _confirmDelete(context, athlete)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  // ── Delete Confirm ────────────────────────────────────────────────────────

  void _confirmDelete(BuildContext context, AthleteModel athlete) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Athlete'),
        content: Text(
            'Remove "${athlete.fullName}" from the roster? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AthletesCubit>().deleteAthlete(athlete.id);
            },
            child: const Text('Delete',
                style: TextStyle(
                    color: _error, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ── Add / Edit Modal ──────────────────────────────────────────────────────

  void _showAddEditModal(BuildContext context, AthleteModel? existing) {
    final cubit = context.read<AthletesCubit>();
    final isEdit = existing != null;

    final nameCtrl = TextEditingController(text: existing?.fullName ?? '');
    final athleteIdCtrl = TextEditingController(text: existing?.athleteId ?? '');
    final bibCtrl = TextEditingController(text: existing?.bib ?? '');
    final dobCtrl = TextEditingController(text: existing?.dob ?? '');
    final ageCtrl = TextEditingController(
        text: existing?.age != null ? '${existing!.age}' : '');
    final disciplineCtrl = TextEditingController(text: existing?.discipline ?? '');
    final teamCtrl = TextEditingController(text: existing?.team ?? '');
    int trials = existing?.trials ?? 3;
    String selectedSex = existing?.sex ?? '';
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: Container(
                decoration: const BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: _border,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        Text(
                          isEdit ? 'Edit Athlete' : 'Add Athlete',
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: _text),
                        ),
                        const SizedBox(height: 16),
                        // Full Name
                        _formField(
                          controller: nameCtrl,
                          label: 'Full Name *',
                          hint: 'e.g. John Smith',
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Name is required'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        // Athlete ID + BIB
                        Row(
                          children: [
                            Expanded(
                              child: _formField(
                                controller: athleteIdCtrl,
                                label: 'Athlete ID',
                                hint: 'ATH-001',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _formField(
                                controller: bibCtrl,
                                label: 'BIB',
                                hint: '42',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // DOB + Age
                        Row(
                          children: [
                            Expanded(
                              child: _formField(
                                controller: dobCtrl,
                                label: 'Date of Birth',
                                hint: 'DD/MM/YYYY',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _formField(
                                controller: ageCtrl,
                                label: 'Age',
                                hint: '22',
                                isNumber: true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Sex + Discipline
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Sex',
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: _subtext,
                                          fontWeight: FontWeight.w500)),
                                  const SizedBox(height: 4),
                                  Container(
                                    height: 44,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: _bg,
                                      border: Border.all(color: _border),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: selectedSex.isEmpty
                                            ? null
                                            : selectedSex,
                                        hint: const Text('Select',
                                            style: TextStyle(
                                                color: _subtext, fontSize: 13)),
                                        isExpanded: true,
                                        dropdownColor: _surface,
                                        style: const TextStyle(
                                            fontSize: 14, color: _text),
                                        items: ['Male', 'Female', 'Other']
                                            .map((s) => DropdownMenuItem(
                                                  value: s,
                                                  child: Text(s),
                                                ))
                                            .toList(),
                                        onChanged: (v) => setModalState(
                                            () => selectedSex = v ?? ''),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _formField(
                                controller: disciplineCtrl,
                                label: 'Discipline',
                                hint: 'Sprint',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Team
                        _formField(
                          controller: teamCtrl,
                          label: 'Team / Group',
                          hint: 'e.g. Sprint Group A',
                        ),
                        const SizedBox(height: 12),
                        // Trials stepper
                        Row(
                          children: [
                            const Text('Trials',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: _subtext,
                                    fontWeight: FontWeight.w500)),
                            const Spacer(),
                            _stepperBtn(
                              icon: Icons.remove,
                              onTap: trials > 1
                                  ? () => setModalState(() => trials--)
                                  : null,
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Text('$trials',
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: _text)),
                            ),
                            _stepperBtn(
                              icon: Icons.add,
                              onTap: trials < 10
                                  ? () => setModalState(() => trials++)
                                  : null,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primary,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () {
                              if (!formKey.currentState!.validate()) return;
                              final athlete = AthleteModel(
                                id: existing?.id ?? cubit.generateId(),
                                fullName: nameCtrl.text.trim(),
                                athleteId: athleteIdCtrl.text.trim(),
                                bib: bibCtrl.text.trim(),
                                dob: dobCtrl.text.trim(),
                                age: int.tryParse(ageCtrl.text.trim()),
                                sex: selectedSex,
                                discipline: disciplineCtrl.text.trim(),
                                team: teamCtrl.text.trim(),
                                trials: trials,
                                completedTrials: existing?.completedTrials ?? 0,
                              );
                              Navigator.pop(ctx);
                              if (isEdit) {
                                cubit.updateAthlete(athlete);
                              } else {
                                cubit.addAthlete(athlete);
                              }
                            },
                            child: Text(
                              isEdit ? 'Save Changes' : 'Add Athlete',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _formField({
    required TextEditingController controller,
    required String label,
    String? hint,
    bool readOnly = false,
    bool isNumber = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                color: _subtext,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          validator: validator,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          style: TextStyle(
              fontSize: 14, color: readOnly ? _subtext : _text),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: _subtext, fontSize: 13),
            filled: true,
            fillColor: readOnly ? _bg : _surface,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _border),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _error),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _primary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _stepperBtn({required IconData icon, VoidCallback? onTap}) {
    final active = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: active ? _primaryLight : _bg,
          border: Border.all(color: active ? _primary : _border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: active ? _primary : _subtext),
      ),
    );
  }

  // ── Import Preview Dialog ─────────────────────────────────────────────────

  void _showImportPreviewDialog(
      BuildContext context, List<AthleteModel> athletes) {
    final cubit = context.read<AthletesCubit>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.preview_outlined, color: _primary, size: 22),
            SizedBox(width: 8),
            Text('Import Preview',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _text)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('${athletes.length} athletes found',
                    style: const TextStyle(
                        color: _primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 240),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount:
                      athletes.length > 6 ? 6 : athletes.length,
                  separatorBuilder: (_, __) =>
                      const Divider(color: _border, height: 1),
                  itemBuilder: (_, i) {
                    final a = athletes[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                                color: _primaryLight,
                                shape: BoxShape.circle),
                            alignment: Alignment.center,
                            child: Text(a.initials,
                                style: const TextStyle(
                                    color: _primary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(a.fullName,
                                    style: const TextStyle(
                                        color: _text,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13),
                                    overflow: TextOverflow.ellipsis),
                                Text(
                                  [
                                    if (a.athleteId.isNotEmpty) a.athleteId,
                                    a.team.isEmpty ? 'No team' : a.team,
                                    '${a.trials} trials',
                                  ].join('  ·  '),
                                  style: const TextStyle(
                                      color: _subtext, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              if (athletes.length > 6)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('+ ${athletes.length - 6} more...',
                      style: const TextStyle(
                          color: _subtext, fontSize: 12)),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              cubit.cancelImport();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              cubit.confirmImport();
            },
            child: const Text('Import All',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
