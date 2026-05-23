import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xelex_esp/core/failure.dart';
import 'package:xelex_esp/core/pref_keys.dart';
import '../../domain/entity/feedback_result.dart';

abstract interface class FeedbackRemoteDataSource {
  TaskEither<Failure, FeedbackResult> submitFeedback({
    required int taskId,
    required int rpe,
    required String note,
  });
}

class FeedbackRemoteDataSourceImpl implements FeedbackRemoteDataSource {
  final Dio _dio;
  final SharedPreferences _prefs;

  const FeedbackRemoteDataSourceImpl(this._dio, this._prefs);

  String? get _token => _prefs.getString(PrefKeys.userToken);

  @override
  TaskEither<Failure, FeedbackResult> submitFeedback({
    required int taskId,
    required int rpe,
    required String note,
  }) =>
      TaskEither(() async {
        final token = _token;
        if (token == null || token.isEmpty) {
          return left(const AuthFailure('Token not found, please login again'));
        }

        try {
          final response = await _dio.post(
            '/athlete/feedback/$taskId',
            data: {
              'rpe': rpe,
              'note': note,
            },
            options: Options(headers: {'Authorization': 'Bearer $token'}),
          );

          final body = response.data;
          if (body is Map && body['success'] == false) {
            return left(ServerFailure(
              body['message'] as String? ??
                  'Feedback submit karne mein failure',
            ));
          }

          final message = (body is Map ? body['message'] as String? : null) ??
              'Feedback submitted';
          final data = body is Map ? body['data'] : null;
          final feedbackRaw = data is Map ? data['feedback'] : null;
          final feedback = feedbackRaw is Map<String, dynamic>
              ? feedbackRaw
              : const <String, dynamic>{};

          return right(FeedbackResult(
            rpe: (feedback['rpe'] as num?)?.toInt() ?? rpe,
            note: feedback['note'] as String? ?? note,
            sessionDuration:
                (feedback['session_duration'] as num?)?.toInt() ?? 0,
            trainingLoad:
                (feedback['training_load'] as num?)?.toInt() ?? 0,
            submittedAt: feedback['submitted_at'] as String?,
            message: message,
          ));
        } on DioException catch (e) {
          return left(ServerFailure(
            e.response?.data is Map
                ? (e.response?.data['message'] as String? ??
                    e.message ??
                    'Feedback submit karne mein failure')
                : e.message ?? 'Feedback submit karne mein failure',
          ));
        } catch (e) {
          return left(ServerFailure('Feedback submit karne mein failure: $e'));
        }
      });
}
