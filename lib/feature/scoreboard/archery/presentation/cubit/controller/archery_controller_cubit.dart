import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:xelex_esp/feature/bluetooth/mapper/archery_ble_mapper.dart';
import 'package:xelex_esp/feature/bluetooth/service/ble_service.dart';

part 'archery_controller_state.dart';

class ArcheryControllerCubit extends Cubit<ArcheryControllerState> {
  final BleService bleService;
  final ArcheryBleMapper archeryBleMapper;

  ArcheryControllerCubit({
    required this.bleService,
    required this.archeryBleMapper,
  }) : super(const ArcheryControllerState());

  // ============ IDLE SCREEN ============

  void showIdleScreen() {
    emit(state.copyWith(isIdleScreen: true));
   // bleService.send(archeryBleMapper.showIdleScreen());
  }

  void showGameScreen() {
    emit(state.copyWith(isIdleScreen: false));
    bleService.send("AR");
  }

  // ============ SETUP ============

  void setMode(ArcheryMode mode) {
    emit(state.copyWith(mode: mode));
    String modeString;
    if (mode == ArcheryMode.abcd) {
      modeString = 'ABCD';
      bleService.send(
        archeryBleMapper.setMode4Targets()
      );
    }
    else if (mode == ArcheryMode.abc) {
      modeString = 'ABC';
      bleService.send(
          archeryBleMapper.setMode3Targets()
      );
    }
    else {
      modeString = 'AB-CD';
      bleService.send(
          archeryBleMapper.setFirstGroupAB()
      );
    }

  }

  void setPracticeEnds(int ends) {
    emit(state.copyWith(practiceEnds: ends));
    bleService.send(archeryBleMapper.setInfoText(ends.toString()));
  }

  void setScoringEnds(int ends) {
    emit(state.copyWith(scoringEnds: ends));
    bleService.send(archeryBleMapper.setInfoText(ends.toString()));

  }

  void setGreenTime(int seconds) {
    emit(state.copyWith(greenTime: seconds));

  }

  // ============ MATCH CONTROL ============

  void initializeMatch() {
    final initialPhase =
        state.practiceEnds > 0 ? MatchPhase.sighter : MatchPhase.scoring;

    emit(state.copyWith(
      matchPhase: initialPhase,
      currentEndNumber: 1,
      currentTeam: 'AB',
      isMatchComplete: false,
      isPracticeSkipped: false,
      isIdleScreen: false,
    ));

  }

  void onEndComplete() {
    if (state.matchPhase == MatchPhase.sighter) {
      _handlePracticeEndComplete();
    } else if (state.matchPhase == MatchPhase.scoring) {
      _handleScoringEndComplete();
    }
  }

  void _handlePracticeEndComplete() {
    if (state.currentEndNumber >= state.practiceEnds) {
      // Practice complete, move to scoring
      _transitionToScoring();
    } else {
      // Next practice end
      _advanceToNextEnd();
    }
  }

  void _handleScoringEndComplete() {
    if (state.currentEndNumber >= state.scoringEnds) {
      // Match complete
      _completeMatch();
    } else {
      // Next scoring end
      _advanceToNextEnd();
    }
  }

  void _advanceToNextEnd() {
    final nextEnd = state.currentEndNumber + 1;
    String nextTeam = state.currentTeam;

    // AB-CD rotation: AB, CD, CD, AB, AB, CD, CD, AB...
    if (state.mode == ArcheryMode.abCd) {
      nextTeam = _getTeamForEnd(nextEnd);
    }

    emit(state.copyWith(
      currentEndNumber: nextEnd,
      currentTeam: nextTeam,
    ));

  }

  String _getTeamForEnd(int endNumber) {
    // Pattern: AB, CD, CD, AB, AB, CD, CD, AB ...
    final pattern = ['AB', 'CD', 'CD', 'AB'];
    final index = (endNumber - 1) % pattern.length;
    return pattern[index];
  }

  void _transitionToScoring() {
    emit(state.copyWith(
      matchPhase: MatchPhase.scoring,
      currentEndNumber: 1,
      currentTeam: 'AB',
    ));
  }

  void skipPractice() {
    emit(state.copyWith(isPracticeSkipped: true));
    _transitionToScoring();
  }

  void _completeMatch() {
    emit(state.copyWith(
      matchPhase: MatchPhase.completed,
      isMatchComplete: true,
    ));

  }

  // ============ SETTINGS ============

  void setBrightness(int value) {
    final clampedValue = value.clamp(0, 220);
    emit(state.copyWith(brightness: clampedValue));
    bleService.send("BRIG$clampedValue");
  }

  void setTempBrightness(int value) {
    emit(state.copyWith(setTempBrightness: value.clamp(0, 220)));
  }


  void toggleBuzzer() {
    emit(state.copyWith(buzzerOn: !state.buzzerOn));
  }

  void triggerBuzzer() {
    if (state.buzzerOn) {

    }
  }

  void resetScreen() {
    //bleService.send(archeryBleMapper.resetScreen());
  }

  void resetMatch() {
    emit(const ArcheryControllerState());
   // bleService.send(archeryBleMapper.resetScreen());
  }
}

/*import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:xelex_esp/feature/bluetooth/mapper/archery_ble_mapper.dart';
import 'package:xelex_esp/feature/bluetooth/service/ble_service.dart';

part 'archery_controller_state.dart';

class ArcheryControllerCubit extends Cubit<ArcheryControllerState> {
  final BleService bleService;
  final ArcheryBleMapper archeryBleMapper;

  ArcheryControllerCubit({
    required this.bleService,
    required this.archeryBleMapper,
  }) : super(const ArcheryControllerState());

  // ============ IDLE SCREEN ============

  void showIdleScreen() {
    emit(state.copyWith(isIdleScreen: true));
    // bleService.send(archeryBleMapper.showIdleScreen());
  }

  void showGameScreen() {
    emit(state.copyWith(isIdleScreen: false));
    bleService.send("AR");
  }

  // ============ SETUP ============

  void setMode(ArcheryMode mode) {
    emit(state.copyWith(mode: mode));
    String modeString;
    if (mode == ArcheryMode.abcd) {
      modeString = 'ABCD';
      bleService.send(
          archeryBleMapper.setFirstGroupAB()
      );
      bleService.send(
          archeryBleMapper.setSecondGroupCD()
      );
    }
    else if (mode == ArcheryMode.abc) {
      modeString = 'ABC';
      bleService.send(
          archeryBleMapper.setFirstGroupAB()
      );
      bleService.send(
          archeryBleMapper.setSecondGroupCD()
      );
    }
    else {
      modeString = 'AB-CD';
      bleService.send(
        archeryBleMapper.setGameMode(modeString),
      );
    }

  }

  void setPracticeEnds(int ends) {
    emit(state.copyWith(practiceEnds: ends));
  }

  void setScoringEnds(int ends) {
    emit(state.copyWith(scoringEnds: ends));
    bleService.send(archeryBleMapper.setTotalEnds(ends));
  }

  void setGreenTime(int seconds) {
    emit(state.copyWith(greenTime: seconds));
    bleService.send(archeryBleMapper.setGreenTime(seconds));
  }

  // ============ MATCH CONTROL ============

  void initializeMatch() {
    final initialPhase =
    state.practiceEnds > 0 ? MatchPhase.sighter : MatchPhase.scoring;

    emit(state.copyWith(
      matchPhase: initialPhase,
      currentEndNumber: 1,
      currentTeam: 'AB',
      isMatchComplete: false,
      isPracticeSkipped: false,
      isIdleScreen: false,
    ));

    bleService.send(archeryBleMapper
        .setMatchPhase(initialPhase == MatchPhase.sighter ? 'SIGHTER' : 'SCORING'));
    bleService.send(archeryBleMapper.setEndNumber(1));
    bleService.send(archeryBleMapper.showGameScreen());

    if (state.mode == ArcheryMode.abCd) {
      bleService.send(archeryBleMapper.setCurrentTeam('AB'));
      bleService.send(archeryBleMapper.setActivePlayers('AB'));
    } else {
      bleService.send(archeryBleMapper.setActivePlayers(state.activePlayers.join('')));
    }
  }

  void onEndComplete() {
    if (state.matchPhase == MatchPhase.sighter) {
      _handlePracticeEndComplete();
    } else if (state.matchPhase == MatchPhase.scoring) {
      _handleScoringEndComplete();
    }
  }

  void _handlePracticeEndComplete() {
    if (state.currentEndNumber >= state.practiceEnds) {
      // Practice complete, move to scoring
      _transitionToScoring();
    } else {
      // Next practice end
      _advanceToNextEnd();
    }
  }

  void _handleScoringEndComplete() {
    if (state.currentEndNumber >= state.scoringEnds) {
      // Match complete
      _completeMatch();
    } else {
      // Next scoring end
      _advanceToNextEnd();
    }
  }

  void _advanceToNextEnd() {
    final nextEnd = state.currentEndNumber + 1;
    String nextTeam = state.currentTeam;

    // AB-CD rotation: AB, CD, CD, AB, AB, CD, CD, AB...
    if (state.mode == ArcheryMode.abCd) {
      nextTeam = _getTeamForEnd(nextEnd);
    }

    emit(state.copyWith(
      currentEndNumber: nextEnd,
      currentTeam: nextTeam,
    ));

    bleService.send(archeryBleMapper.setEndNumber(nextEnd));
    if (state.mode == ArcheryMode.abCd) {
      bleService.send(archeryBleMapper.setCurrentTeam(nextTeam));
      bleService.send(archeryBleMapper.setActivePlayers(nextTeam));
    }
  }

  String _getTeamForEnd(int endNumber) {
    // Pattern: AB, CD, CD, AB, AB, CD, CD, AB ...
    final pattern = ['AB', 'CD', 'CD', 'AB'];
    final index = (endNumber - 1) % pattern.length;
    return pattern[index];
  }

  void _transitionToScoring() {
    emit(state.copyWith(
      matchPhase: MatchPhase.scoring,
      currentEndNumber: 1,
      currentTeam: 'AB',
    ));

    bleService.send(archeryBleMapper.setMatchPhase('SCORING'));
    bleService.send(archeryBleMapper.setEndNumber(1));
    if (state.mode == ArcheryMode.abCd) {
      bleService.send(archeryBleMapper.setCurrentTeam('AB'));
      bleService.send(archeryBleMapper.setActivePlayers('AB'));
    }
  }

  void skipPractice() {
    emit(state.copyWith(isPracticeSkipped: true));
    _transitionToScoring();
  }

  void _completeMatch() {
    emit(state.copyWith(
      matchPhase: MatchPhase.completed,
      isMatchComplete: true,
    ));
    bleService.send(archeryBleMapper.setMatchPhase('COMPLETED'));
  }

  // ============ SETTINGS ============

  void setBrightness(int value) {
    final clampedValue = value.clamp(0, 255);
    emit(state.copyWith(brightness: clampedValue));
    bleService.send(archeryBleMapper.setBrightness(clampedValue));
  }

  void toggleBuzzer() {
    emit(state.copyWith(buzzerOn: !state.buzzerOn));
  }

  void triggerBuzzer() {
    if (state.buzzerOn) {
      bleService.send(archeryBleMapper.triggerBuzzer());
    }
  }

  void resetScreen() {
    bleService.send(archeryBleMapper.resetScreen());
  }

  void resetMatch() {
    emit(const ArcheryControllerState());
    bleService.send(archeryBleMapper.resetScreen());
  }
}*/
