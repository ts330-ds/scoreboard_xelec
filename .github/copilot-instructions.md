# Copilot & AI Agent Instructions for xelex_esp

## Project Overview
- **xelex_esp** is a modular Flutter app for sports scoreboards, supporting multiple games and Bluetooth device integration.
- Major features are organized by sport (e.g., basketball, football, kabaddi) under `lib/feature/scoreboard/`, each with its own presentation, cubit, and config logic.
- Bluetooth communication is handled via `flutter_blue_plus` and custom BLE mappers in `lib/feature/bluetooth/mapper/`.
- Dependency injection is managed with `get_it` in `lib/service/dependency_injection/di_service.dart` (see `setupDI`).
- Navigation uses `go_router` with routes defined in `lib/router/app_router.dart` and paths in `lib/router/app_path.dart`.
- Error handling is centralized via `GlobalErrorCubit` and `global_error_screen.dart`.

## Key Patterns & Conventions
- **State Management:** Uses `flutter_bloc` for all business logic. Each feature has its own Cubit and State classes.
- **BLE Device Handling:**
  - BLE logic is in `lib/feature/bluetooth/service/ble_service.dart` and `ble_cubit.dart`.
  - Device reconnection and persistence use `SharedPreferences`.
  - BLE mappers provide game-specific protocol codes (see `game_select_mapper.dart`).
- **Dependency Injection:** Register all services and mappers in `setupDI()`; access via `sl<T>()`.
- **Routing:** All navigation should use `GoRouter` and named paths from `app_path.dart`.
- **Error Handling:** Use `GlobalErrorCubit` for reporting and displaying errors.
- **UI Structure:**
  - Screens are under `presentation/screen/`.
  - Cubits and states are under `presentation/cubit/`.
  - Mappers and service logic are under `mapper/` and `service/`.

## Developer Workflows
- **Build:** Use `flutter build <platform>` (e.g., `flutter build apk`).
- **Run:** Use `flutter run` for local development.
- **Test:** Place tests in `test/`. Run with `flutter test`.
- **Analyze:** Run `flutter analyze` to check for lint and type errors. Lint rules are in `analysis_options.yaml`.
- **Dependencies:** Managed in `pubspec.yaml`. Run `flutter pub get` after changes.

## Integration Points
- **Bluetooth:** All BLE logic is abstracted in `BleService` and related cubits. Use mappers for protocol-specific codes.
- **WebSocket:** Socket communication logic is in `lib/service/webSocketService/socketService.dart`.
- **Permissions:** Bluetooth permissions are handled in `BluetoothPermissionService` and related cubits.

## Examples
- To add a new sport, create a new folder under `lib/feature/scoreboard/`, implement screens, cubits, and mappers, and register in DI and router.
- To add a new BLE protocol, extend a mapper in `lib/feature/bluetooth/mapper/` and register in DI.

## References
- Main entry: `lib/main.dart`
- DI setup: `lib/service/dependency_injection/di_service.dart`
- Routing: `lib/router/app_router.dart`, `lib/router/app_path.dart`
- BLE: `lib/feature/bluetooth/service/ble_service.dart`, `lib/feature/bluetooth/presentation/cubit/ble/ble_cubit.dart`
- Error handling: `lib/error/cubit/error_cubit.dart`, `lib/error/screen/global_error_screen.dart`

---
For questions or unclear patterns, review the referenced files or ask for clarification.
