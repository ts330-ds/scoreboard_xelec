import 'package:flutter/material.dart';

double fontScaleFactor(BuildContext context) {
  final width = MediaQuery.of(context).size.width;

  if (width >= 1024) {
    return 1.5; // Desktop / Web
  } else if (width >= 600) {
    return 1.30; // Tablet
  } else {
    return 1.0; // Mobile
  }
}
