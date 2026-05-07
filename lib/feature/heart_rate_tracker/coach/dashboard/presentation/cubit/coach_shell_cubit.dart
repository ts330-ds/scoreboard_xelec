import 'package:flutter_bloc/flutter_bloc.dart';

class CoachShellCubit extends Cubit<int> {
  CoachShellCubit() : super(0);
  void changeTab(int index) => emit(index);
}
