import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Smooth notch that visually matches a rounded-rect "guest".
///
/// This implementation is an adaptation of Flutter's CircularNotchedRectangle
/// approach, but uses an effective radius computed from the guest RRect,
/// and keeps host/guest corner radii into account. It produces a smooth
/// bezier+arc notch that looks natural for FAB-like guests and for
/// moderately rounded rectangles.
///
/// Note: this is an approximation — for extreme aspect ratios or very large
/// guest corner radii, the notch will still be smooth but will not strictly
/// follow the exact RRect contour on every corner.
class SmoothRoundedNotchedRectangle extends NotchedShape {
  const SmoothRoundedNotchedRectangle({
    this.inverted = false,
    this.hostRadius = Radius.zero,
    this.guestCorner = Radius.zero,
    this.notchMargin = 0.0,
    // Fine-tune the "tightness" of the bezier transitions:
    this.s1 = 15.0,
    this.s2 = 1.0,
  });

  final bool inverted;
  final Radius hostRadius;
  final Radius guestCorner;
  final double notchMargin;
  final double s1;
  final double s2;

  @override
  Path getOuterPath(Rect host, Rect? guest) {
    final RRect hostRRect = RRect.fromRectAndRadius(host, hostRadius);
    final Path hostPath = Path()..addRRect(hostRRect);

    if (guest == null || !host.overlaps(guest)) {
      return hostPath;
    }

    final Rect inflatedGuest = guest.inflate(notchMargin);
    final double r = math.min(inflatedGuest.width, inflatedGuest.height) / 2.0;
    final Radius notchRadius = Radius.circular(r);

    final double invertMultiplier = inverted ? -1.0 : 1.0;
    final double a = -r - s2;
    final double b =
        (inverted ? host.bottom : host.top) - inflatedGuest.center.dy;

    if (b == 0.0) {
      final Path guestPath = Path()
        ..addRRect(RRect.fromRectAndRadius(inflatedGuest, guestCorner));
      return Path.combine(PathOperation.difference, hostPath, guestPath);
    }

    final double underSqrt = b * b * r * r * (a * a + b * b - r * r);
    final double n2 = underSqrt <= 0.0 ? 0.0 : math.sqrt(underSqrt);
    final double denom = (a * a + b * b);
    if (denom == 0.0) {
      final Path guestPath = Path()
        ..addRRect(RRect.fromRectAndRadius(inflatedGuest, guestCorner));
      return Path.combine(PathOperation.difference, hostPath, guestPath);
    }

    final double p2xA = ((a * r * r) - n2) / denom;
    final double p2xB = ((a * r * r) + n2) / denom;
    final double p2yA =
        math.sqrt(math.max(0.0, r * r - p2xA * p2xA)) * invertMultiplier;
    final double p2yB =
        math.sqrt(math.max(0.0, r * r - p2xB * p2xB)) * invertMultiplier;

    final List<Offset> p = List<Offset>.filled(6, Offset.zero);
    p[0] = Offset(a - s1, b);
    p[1] = Offset(a, b);
    final double cmp = b < 0 ? -1.0 : 1.0;
    p[2] = (cmp * p2yA > cmp * p2yB) ? Offset(p2xA, p2yA) : Offset(p2xB, p2yB);
    p[3] = Offset(-p[2].dx, p[2].dy);
    p[4] = Offset(-p[1].dx, p[1].dy);
    p[5] = Offset(-p[0].dx, p[0].dy);

    for (int i = 0; i < p.length; i++) {
      p[i] += inflatedGuest.center;
    }

    // --- FIX: start/end top edge at the tangency points of top corner arcs ---
    // Получаем горизонтальные радиусы верхних углов у hostRRect:
    final double leftTopRadiusX = hostRRect.tlRadiusX;
    final double rightTopRadiusX = hostRRect.trRadiusX;

    // Точки, откуда действительно начинают и заканчивают прямую часть верхнего ребра:
    final double startX = host.left + leftTopRadiusX;
    final double endX = host.right - rightTopRadiusX;

    final Path path = Path()..moveTo(startX, host.top);

    if (!inverted) {
      path
        ..lineTo(p[0].dx, p[0].dy)
        ..quadraticBezierTo(p[1].dx, p[1].dy, p[2].dx, p[2].dy)
        ..arcToPoint(p[3], radius: notchRadius, clockwise: false)
        ..quadraticBezierTo(p[4].dx, p[4].dy, p[5].dx, p[5].dy)
        // go back to the straight top edge but stop before the top-right corner arc
        ..lineTo(endX, host.top)
        // now go down along the rounded corner area — intersection with hostPath will clip precise arc
        ..lineTo(host.right, host.top + hostRRect.trRadiusY)
        ..lineTo(host.right, host.bottom)
        ..lineTo(host.left, host.bottom);
    } else {
      // inverted: notch on bottom — keep original logic but also avoid drawing into top-left arc:
      path
        ..lineTo(host.right, host.top)
        ..lineTo(host.right, host.bottom)
        ..lineTo(p[5].dx, p[5].dy)
        ..quadraticBezierTo(p[4].dx, p[4].dy, p[3].dx, p[3].dy)
        ..arcToPoint(p[2], radius: notchRadius, clockwise: false)
        ..quadraticBezierTo(p[1].dx, p[1].dy, p[0].dx, p[0].dy)
        ..lineTo(host.left, host.bottom);
    }

    // Intersect with hostRRect so only the host's rounded corners remain and
    // any tiny overlaps are clipped away.
    final Path combined = Path.combine(
      PathOperation.intersect,
      path..close(),
      hostPath,
    );

    return combined;
  }
}
