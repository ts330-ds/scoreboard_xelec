import 'package:flutter_bloc/flutter_bloc.dart';

class AthleteShellCubit extends Cubit<int> {
  AthleteShellCubit() : super(0);
  void changeTab(int index) => emit(index);
}
