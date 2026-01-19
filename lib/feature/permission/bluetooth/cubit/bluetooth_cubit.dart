
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../service/permission/bluetooth_permission_service.dart';
import '../../../../service/permission/permission_status.dart';

class PermissionCubit extends Cubit<AppPermissionStatus> {
  final BluetoothPermissionService service;

  PermissionCubit(this.service)
      : super(AppPermissionStatus.denied);

  Future<void> ask() async {
    emit(await service.request());
  }
  /// 🔍 Called on app start
  Future<void> checkPermission() async {
    emit(await service.check());
  }

}
