import 'dart:math';

import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';
import '../utils/format.dart';

/// Circular progress ring with a coral gradient and a soft glow.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.progress,
    this.size = 120,
    this.strokeWidth = 12,
    this.colors = const [coral, coralLight],
    this.child,
  });

  final double progress;
  final double size;
  final double strokeWidth;
  final List<Color> colors;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: progress.clamp(0, 1).toDouble()),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => CustomPaint(
        painter: _RingPainter(value, colors, strokeWidth),
        child: SizedBox.square(
          dimension: size,
          child: Center(child: child),
        ),
      ),
      child: child,
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.value, this.colors, this.strokeWidth);

  final double value;
  final List<Color> colors;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(strokeWidth / 2);
    canvas.drawArc(
      rect,
      0,
      2 * pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = colors.first.withValues(alpha: 0.14),
    );
    if (value <= 0) return;

    final sweep = 2 * pi * value;
    final shader = SweepGradient(
      colors: colors,
      endAngle: max(sweep, 0.01),
      transform: const GradientRotation(-pi / 2),
    ).createShader(rect);
    Paint arc() => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = shader;
    // Glow first, then the crisp arc on top.
    canvas.drawArc(
      rect,
      -pi / 2,
      sweep,
      false,
      arc()
        ..color = const Color(0x8C000000)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, strokeWidth * 0.8),
    );
    canvas.drawArc(rect, -pi / 2, sweep, false, arc());
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value ||
      old.colors != colors ||
      old.strokeWidth != strokeWidth;
}

/// Smooth glowing line chart. [xs] are positions from 0 to 1 (even if null).
class NeonLineChart extends StatelessWidget {
  const NeonLineChart({
    super.key,
    required this.values,
    required this.labels,
    required this.semanticsLabel,
    this.xs,
    this.goal,
    this.zeroBased = true,
    this.showValues = false,
    this.format,
  });

  final List<double> values;
  final List<String> labels;
  final String semanticsLabel;
  final List<double>? xs;

  /// Dashed target line.
  final double? goal;
  final bool zeroBased;

  /// Label every non-zero point; otherwise only the last one.
  final bool showValues;
  final String Function(double)? format;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      label: semanticsLabel,
      child: TweenAnimationBuilder<double>(
        key: ValueKey(values.length),
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutCubic,
        builder: (context, t, _) => CustomPaint(
          size: Size.infinite,
          painter: _NeonPainter(
            values: values,
            labels: labels,
            xs: xs,
            goal: goal,
            zeroBased: zeroBased,
            showValues: showValues,
            format: format ?? (v) => v.round().toString(),
            t: t,
            dotFill: scheme.surface,
            muted: scheme.onSurfaceVariant,
            labelStyle: theme.textTheme.labelSmall!.copyWith(
              color: scheme.onSurfaceVariant,
            ),
            valueStyle: theme.textTheme.labelMedium!.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _NeonPainter extends CustomPainter {
  _NeonPainter({
    required this.values,
    required this.labels,
    required this.xs,
    required this.goal,
    required this.zeroBased,
    required this.showValues,
    required this.format,
    required this.t,
    required this.dotFill,
    required this.muted,
    required this.labelStyle,
    required this.valueStyle,
  });

  final List<double> values;
  final List<String> labels;
  final List<double>? xs;
  final double? goal;
  final bool zeroBased;
  final bool showValues;
  final String Function(double) format;
  final double t;
  final Color dotFill;
  final Color muted;
  final TextStyle labelStyle;
  final TextStyle valueStyle;

  static const _side = 14.0, _top = 24.0, _bottom = 22.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final n = values.length;
    final w = size.width - 2 * _side, h = size.height - _top - _bottom;
    final positions =
        xs ?? [for (var i = 0; i < n; i++) n == 1 ? 0.5 : i / (n - 1)];

    var lo = zeroBased ? 0.0 : values.reduce(min);
    var hi = max(values.reduce(max), goal ?? 0);
    if (zeroBased) {
      hi = hi <= 0 ? 10 : hi * 1.18;
    } else {
      final pad = max(0.5, (hi - lo) * 0.25);
      lo -= pad;
      hi += pad;
    }
    double y(double v) => _top + h * (1 - (v - lo) / (hi - lo));
    final points = [
      for (var i = 0; i < n; i++)
        Offset(_side + w * positions[i], y(lo + (values[i] - lo) * t)),
    ];

    if (goal != null) {
      final gy = y(goal!);
      final dash = Paint()
        ..color = muted.withValues(alpha: 0.45)
        ..strokeWidth = 1;
      for (double x = 0; x < size.width; x += 8) {
        canvas.drawLine(
          Offset(x, gy),
          Offset(min(x + 4, size.width), gy),
          dash,
        );
      }
    }

    final line = _smooth(points);
    final fill = Path.from(line)
      ..lineTo(points.last.dx, _top + h)
      ..lineTo(points.first.dx, _top + h)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [coral.withValues(alpha: 0.28), coral.withValues(alpha: 0)],
        ).createShader(Rect.fromLTWH(0, _top, size.width, h)),
    );
    canvas.drawPath(
      line,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..color = coral.withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawPath(
      line,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..shader = const LinearGradient(colors: [coral, coralLight])
            .createShader(Rect.fromLTWH(_side, 0, w, size.height)),
    );

    for (var i = 0; i < n; i++) {
      final last = i == n - 1;
      final p = points[i];
      if (n <= 40 || last) {
        final r = last ? 5.0 : 3.5;
        if (last) {
          canvas.drawCircle(
            p,
            10,
            Paint()
              ..color = coral.withValues(alpha: 0.35)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
          );
        }
        canvas.drawCircle(p, r, Paint()..color = dotFill);
        canvas.drawCircle(
          p,
          r,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = coral,
        );
      }
      if (t == 1 && (showValues ? values[i] > 0 : last)) {
        _text(
          canvas,
          size,
          format(values[i]),
          valueStyle,
          Offset(p.dx, p.dy - 10),
          above: true,
        );
      }
      if (i < labels.length && labels[i].isNotEmpty) {
        _text(
          canvas,
          size,
          labels[i],
          labelStyle,
          Offset(p.dx, size.height - _bottom + 6),
        );
      }
    }
  }

  /// Monotone cubic curve: smooth, but never dips below the data.
  static Path _smooth(List<Offset> p) {
    final path = Path()..moveTo(p.first.dx, p.first.dy);
    final n = p.length;
    if (n == 1) return path;
    final m = [
      for (var i = 0; i < n - 1; i++)
        p[i + 1].dx == p[i].dx
            ? 0.0
            : (p[i + 1].dy - p[i].dy) / (p[i + 1].dx - p[i].dx),
    ];
    final tangent = List<double>.filled(n, 0)
      ..[0] = m.first
      ..[n - 1] = m.last;
    for (var i = 1; i < n - 1; i++) {
      tangent[i] = m[i - 1] * m[i] <= 0 ? 0 : (m[i - 1] + m[i]) / 2;
    }
    for (var i = 0; i < n - 1; i++) {
      if (m[i] == 0) {
        tangent[i] = 0;
        tangent[i + 1] = 0;
        continue;
      }
      final a = tangent[i] / m[i], b = tangent[i + 1] / m[i];
      final s = a * a + b * b;
      if (s > 9) {
        final k = 3 / sqrt(s);
        tangent[i] = k * a * m[i];
        tangent[i + 1] = k * b * m[i];
      }
    }
    for (var i = 0; i < n - 1; i++) {
      final dx = (p[i + 1].dx - p[i].dx) / 3;
      path.cubicTo(
        p[i].dx + dx,
        p[i].dy + tangent[i] * dx,
        p[i + 1].dx - dx,
        p[i + 1].dy - tangent[i + 1] * dx,
        p[i + 1].dx,
        p[i + 1].dy,
      );
    }
    return path;
  }

  void _text(
    Canvas canvas,
    Size size,
    String text,
    TextStyle style,
    Offset anchor, {
    bool above = false,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    final x = (anchor.dx - painter.width / 2)
        .clamp(0.0, max(0.0, size.width - painter.width))
        .toDouble();
    painter.paint(
      canvas,
      Offset(x, above ? anchor.dy - painter.height : anchor.dy),
    );
    painter.dispose();
  }

  @override
  bool shouldRepaint(_NeonPainter old) =>
      old.t != t ||
      old.values != values ||
      old.goal != goal ||
      old.labelStyle != labelStyle;
}

/// Weight trend as a neon line over time.
class WeightChart extends StatelessWidget {
  const WeightChart({super.key, required this.entries});

  /// Oldest first, at least two entries.
  final List<WeightEntry> entries;

  @override
  Widget build(BuildContext context) {
    final t0 = entries.first.date.millisecondsSinceEpoch;
    final span = max(1, entries.last.date.millisecondsSinceEpoch - t0);
    return NeonLineChart(
      values: [for (final e in entries) e.kg],
      xs: [
        for (final e in entries) (e.date.millisecondsSinceEpoch - t0) / span,
      ],
      labels: [
        for (final (i, e) in entries.indexed)
          i == 0 || i == entries.length - 1 ? formatShortDate(e.date) : '',
      ],
      zeroBased: false,
      format: formatKg,
      semanticsLabel:
          'Weight trend from ${formatKg(entries.first.kg)} kg to '
          '${formatKg(entries.last.kg)} kg.',
    );
  }
}
