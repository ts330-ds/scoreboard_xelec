import 'dart:async';
import 'package:flutter/foundation.dart';

class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription _sub;

  GoRouterRefreshStream(Stream stream) {
    _sub = stream.listen((_) {
      notifyListeners(); // 👈 router ko signal
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}