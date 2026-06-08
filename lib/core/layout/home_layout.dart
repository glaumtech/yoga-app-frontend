import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Shared breakpoints for home + competition cards (Material-ish: compact, medium, expanded).
class HomeLayout {
  HomeLayout._();

  static const double mobile = 600;
  static const double tablet = 1024;

  static double sectionHorizontalPadding(double width) {
    if (width < mobile) return 10;
    if (width < tablet) return 16;
    return 20;
  }

  static double sectionVerticalPadding(double width) {
    if (width < mobile) return 24;
    return 32;
  }

  /// Height for horizontal competition carousels (desktop breakpoint).
  static double competitionCarouselHeight(double sectionWidth) {
    if (sectionWidth < mobile) return 400;
    if (sectionWidth < tablet) return 540;
    return 560;
  }

  /// Fixed width for each card in horizontal list (fraction of section, clamped).
  static double competitionCarouselItemExtent(double sectionWidth) {
    return (sectionWidth * 0.38).clamp(280.0, 460.0);
  }

  /// Tablet / large-phone grid columns.
  static int competitionGridCrossAxisCount(double width) {
    if (width >= 900) return 3;
    return 2;
  }

  static double competitionGridChildAspectRatio(int crossAxisCount) {
    // Slightly taller cells so larger brochure banners fit.
    return crossAxisCount >= 3 ? 0.60 : 0.54;
  }

  /// Hero banner min height by available width.
  static double heroBannerMinHeight(double width) {
    if (width < mobile) return 420;
    if (width < tablet) return 480;
    return 520;
  }
}

/// Banner height inside [CompetitionCard] from parent max width.
double competitionCardBannerHeight(double maxWidth) {
  final w = maxWidth.isFinite ? maxWidth : 400;
  if (w < 320) return 128;
  if (w < 400) return 152;
  if (w < 520) return 210;
  return math.min(220, 120 + w * 0.15);
}

EdgeInsets competitionCardContentPadding(double maxWidth) {
  final h = maxWidth < 360 ? 10.0 : (maxWidth < 520 ? 12.0 : 14.0);
  return EdgeInsets.fromLTRB(h, h, h, h);
}

double competitionCardRegistrationButtonHeight(double maxWidth) {
  return maxWidth < 360 ? 48.0 : 52.0;
}
