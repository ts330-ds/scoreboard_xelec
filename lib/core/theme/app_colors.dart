import 'package:flutter/material.dart';

/// Universal color palette — single source of truth.
/// Derived from the timing-gate feature's light-theme design language.
class AppColors {
  AppColors._();

  // ── Backgrounds ──────────────────────────────────────────────────────────
  static const Color bg          = Color(0xFFF4F6F9);   // page background
  static const Color surface     = Color(0xFFFFFFFF);    // cards / containers
  static const Color surfaceAlt  = Color(0xFFF5F7FA);    // input fills, alt bg

  // ── Borders ──────────────────────────────────────────────────────────────
  static const Color border      = Color(0xFFDDE3EC);
  static const Color borderLight = Color(0xFFE8ECF2);

  // ── Primary ──────────────────────────────────────────────────────────────
  static const Color primary      = Color(0xFF1565C0);   // deep blue
  static const Color primaryLight = Color(0xFFE3F2FD);   // very light blue bg

  // ── Text ─────────────────────────────────────────────────────────────────
  static const Color text        = Color(0xFF1E2A3A);    // primary text
  static const Color subtext     = Color(0xFF6B7A8D);    // muted / secondary
  static const Color textHint    = Color(0xFF9CA3AF);    // hints / placeholders

  // ── Semantic ─────────────────────────────────────────────────────────────
  static const Color success     = Color(0xFF16A34A);
  static const Color successBg   = Color(0xFFDCFCE7);
  static const Color error       = Color(0xFFDC2626);
  static const Color errorBg     = Color(0xFFFEE2E2);
  static const Color warning     = Color(0xFFD97706);
  static const Color warningBg   = Color(0xFFFEF3C7);

  // ── Heart-rate accent ────────────────────────────────────────────────────
  static const Color heartRed    = Color(0xFFEF5350);

  // ── Vital accent colors (used for dashboard icons) ──────────────────────
  static const Color vitalOxygen = Color(0xFFEF5350);    // SpO2
  static const Color vitalBP     = Color(0xFF5C6BC0);    // blood pressure
  static const Color vitalTemp   = Color(0xFFD97706);    // temperature
  static const Color vitalStress = Color(0xFF26A69A);    // stress

  // ── Activity accent colors ──────────────────────────────────────────────
  static const Color actSteps    = Color(0xFF1565C0);
  static const Color actCalorie  = Color(0xFFE65100);
  static const Color actDistance = Color(0xFF7B1FA2);
}
