/// Spacing, radii and durations. A minimal design lives or dies by using the
/// same handful of numbers everywhere, so these are the only ones.
class Insets {
  const Insets._();

  static const double s4 = 4;
  static const double s8 = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s24 = 24;
  static const double s32 = 32;

  /// The page gutter. Every screen uses it, so nothing looks glued to the edge.
  static const double gutter = s16;
}

class Radii {
  const Radii._();

  static const double row = 8;
  static const double sheet = 16;
  static const double pill = 999;
}

/// Named `AppDurations`, not `Durations`: Flutter's material library exports a
/// class of that name, and an unprefixed clash makes every import of both
/// ambiguous.
class AppDurations {
  const AppDurations._();

  static const Duration fast = Duration(milliseconds: 120);
  static const Duration normal = Duration(milliseconds: 220);

  /// A barcode scanner fires the same code many times a second; this is how
  /// long a read is ignored afterwards.
  static const Duration scanDebounce = Duration(milliseconds: 800);
}

/// Minimum tap target, per both platforms' accessibility guidance. A cashier
/// uses this app one-handed and in a hurry.
const double kMinTapTarget = 48;
