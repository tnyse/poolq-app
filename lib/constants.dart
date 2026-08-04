import 'package:flutter/material.dart';

// API URLs
const String mainUrl = 'https://api.poolq.app';

// Primary color for the app (brand navy — was accidental teal #26A6B5)
const Color primary = Color(0xFF063a73);

// Secondary colors
const Color secondary = Color(0xFF1D2B36);
const Color accent = Color(0xFFFFB31F);

// Additional colors from Constants/value.dart
const Color boxColor = Color(0xFFF1F4F8);
const Color secondaryBackground = Color(0xFFFFFFFF);

// Neutral colors
const Color background = Color(0xFFF5F5F5);
const Color cardBackground = Colors.white;
const Color textPrimary = Color(0xFF1D2B36);
const Color textSecondary = Color(0xFF6C7A89);

// Status colors
const Color success = Color(0xFF4CAF50);
const Color warning = Color(0xFFFFC107);
const Color error = Color(0xFFE53935);
const Color info = Color(0xFF2196F3);

// Shadow
const BoxShadow defaultShadow = BoxShadow(
  color: Color(0x1A000000),
  blurRadius: 10,
  offset: Offset(0, 2),
);

// Spacing
const double kDefaultPadding = 16.0;
const double kDefaultMargin = 16.0;
const double kDefaultRadius = 8.0;

// Text styles
const TextStyle headingStyle = TextStyle(
  fontSize: 24,
  fontWeight: FontWeight.bold,
  color: textPrimary,
);

const TextStyle subheadingStyle = TextStyle(
  fontSize: 18,
  fontWeight: FontWeight.w600,
  color: textPrimary,
);

const TextStyle bodyStyle = TextStyle(
  fontSize: 16,
  color: textPrimary,
);

const TextStyle captionStyle = TextStyle(
  fontSize: 14,
  color: textSecondary,
);

// Animation durations
const Duration kFastAnimationDuration = Duration(milliseconds: 200);
const Duration kDefaultAnimationDuration = Duration(milliseconds: 300);
const Duration kSlowAnimationDuration = Duration(milliseconds: 500); 