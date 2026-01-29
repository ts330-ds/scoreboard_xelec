
import 'package:flutter_bloc/flutter_bloc.dart';

import 'error_state.dart';

class GlobalErrorCubit extends Cubit<GlobalErrorState> {
  GlobalErrorCubit() : super(GlobalErrorState());

  void showError(String message) {
    emit(state.copyWith(message: message, type: ErrorType.error));
  }

  void showWarning(String message) {
    print("Show wrking call");
    emit(state.copyWith(message: message, type: ErrorType.warning));
  }

  void clear() {
    emit(GlobalErrorState(message: '', type: ErrorType.none));
  }
}