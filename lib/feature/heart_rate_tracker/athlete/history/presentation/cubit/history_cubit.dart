import 'package:flutter_bloc/flutter_bloc.dart';

import 'history_state.dart';

class HistoryCubit extends Cubit<HistoryState> {
  HistoryCubit() : super(const HistoryState());

  void selectPreset(RangePreset preset) {
    if (preset == RangePreset.custom) {
      emit(state.copyWith(preset: preset));
    } else {
      emit(state.copyWith(preset: preset, clearCustom: true));
    }
  }

  void setCustomFrom(DateTime? from) {
    emit(state.copyWith(preset: RangePreset.custom, customFrom: from));
  }

  void setCustomTo(DateTime? to) {
    emit(state.copyWith(preset: RangePreset.custom, customTo: to));
  }

  void clearCustom() {
    emit(state.copyWith(preset: RangePreset.all, clearCustom: true));
  }
}
