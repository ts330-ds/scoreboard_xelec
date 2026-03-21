import 'package:hive/hive.dart';
import 'package:xelex_esp/feature/timing_gates/profile/data/model/timing_gate_profile_model.dart';

/// Profile sirf ek hoti hai — Hive box mein key '0' pe store hoti hai
class ProfileRepository {
  static const _boxName = 'timing_gate_profile';
  static const _key     = 'profile';

  Box<TimingGateProfileModel> get _box =>
      Hive.box<TimingGateProfileModel>(_boxName);

  /// Saved profile return karta hai, ya null agar set nahi hai
  TimingGateProfileModel? getProfile() => _box.get(_key);

  /// Profile save/update karo
  Future<void> saveProfile(TimingGateProfileModel profile) =>
      _box.put(_key, profile);

  /// Profile delete karo (reset)
  Future<void> deleteProfile() => _box.delete(_key);

  bool get hasProfile => _box.containsKey(_key);
}
