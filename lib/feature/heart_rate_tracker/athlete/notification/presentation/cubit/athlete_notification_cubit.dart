import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecase/accept_coach_request_usecase.dart';
import '../../domain/usecase/get_coach_requests_usecase.dart';
import '../../domain/usecase/reject_coach_request_usecase.dart';
import 'athlete_notification_state.dart';

class AthleteNotificationCubit extends Cubit<AthleteNotificationState> {
  final GetCoachRequestsUseCase _getCoachRequests;
  final AcceptCoachRequestUseCase _acceptRequest;
  final RejectCoachRequestUseCase _rejectRequest;

  AthleteNotificationCubit({
    required GetCoachRequestsUseCase getCoachRequests,
    required AcceptCoachRequestUseCase acceptRequest,
    required RejectCoachRequestUseCase rejectRequest,
  })  : _getCoachRequests = getCoachRequests,
        _acceptRequest = acceptRequest,
        _rejectRequest = rejectRequest,
        super(const AthleteNotificationState());

  void _safeEmit(AthleteNotificationState s) {
    if (!isClosed) emit(s);
  }

  Future<void> fetchRequests() async {
    _safeEmit(state.copyWith(status: AthleteNotificationStatus.loading));
    final result = await _getCoachRequests().run();
    result.fold(
      (failure) => _safeEmit(state.copyWith(
        status: AthleteNotificationStatus.error,
        errorMessage: failure.message,
      )),
      (requests) => _safeEmit(state.copyWith(
        status: AthleteNotificationStatus.loaded,
        requests: requests,
      )),
    );
  }

  Future<void> acceptRequest(int requestId) async {
    _safeEmit(state.copyWith(isResponding: true, responseError: null));
    final result = await _acceptRequest(requestId).run();
    result.fold(
      (failure) => _safeEmit(state.copyWith(
        isResponding: false,
        responseError: failure.message,
      )),
      (message) {
        _safeEmit(state.copyWith(
          isResponding: false,
          successMessage: message,
        ));
        fetchRequests();
      },
    );
  }

  Future<void> rejectRequest(int requestId) async {
    _safeEmit(state.copyWith(isResponding: true, responseError: null));
    final result = await _rejectRequest(requestId).run();
    result.fold(
      (failure) => _safeEmit(state.copyWith(
        isResponding: false,
        responseError: failure.message,
      )),
      (message) {
        _safeEmit(state.copyWith(
          isResponding: false,
          successMessage: message,
        ));
        fetchRequests();
      },
    );
  }
}
