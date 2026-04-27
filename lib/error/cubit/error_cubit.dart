import 'package:flutter_bloc/flutter_bloc.dart';

import 'error_state.dart';

class GlobalErrorCubit extends Cubit<GlobalErrorState> {
  GlobalErrorCubit() : super(GlobalErrorState());

  void showError(String message) =>
      emit(state.copyWith(message: message, type: ErrorType.error));

  void showWarning(String message) =>
      emit(state.copyWith(message: message, type: ErrorType.warning));

  void showSuccess(String message) =>
      emit(state.copyWith(message: message, type: ErrorType.success));

  void showInfo(String message) =>
      emit(state.copyWith(message: message, type: ErrorType.info));

  void clear() => emit(GlobalErrorState(message: '', type: ErrorType.none));
}
