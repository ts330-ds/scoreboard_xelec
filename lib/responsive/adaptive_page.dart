import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

Page adaptivePage({
  required Widget child,
  required GoRouterState state,
}) {
  if (kIsWeb) {
    return MaterialPage(
      key: state.pageKey,
      child: child,
    );
  }
  if (Platform.isIOS) {
    return CupertinoPage(
      key: state.pageKey,
      child: child,
    );
  }

  return MaterialPage(
    key: state.pageKey,
    child: child,
  );
}
