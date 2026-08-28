import 'dart:math' as math;
import 'package:flutter/material.dart';

/// The current state of the Sia avatar, used to drive animations.
enum SiaState { idle, listening, thinking, speaking }

/// A full-screen animated female character ("Sia") drawn entirely with
/// Flutter's [CustomPainter].
///
/// Features:
///  * Head, hair, eyes (with blinking), mouth (lip-sync), shoulders/body
///  * Hand gestures that react to [state]
///  * Glowing background aura that changes color per state
///  * Floating particles during speaking
///
/// Usage:
/// ```dart
/// SiaCharacterWidget(
///   state: AvatarState.speaking,
///   isSpeaking: true,
///   currentWordIndex: 5,
///   totalWords: 20,
/// )
/// ```
class SiaCharacterWidget extends StatefulWidget {
  final SiaState state;
  final bool isSpeaking;
  final int currentWordIndex;
  final int totalWords;

  const SiaCharacterWidget({
    super.key,
    this.state = SiaState.idle,
    this.isSpeaking = false,
    this.currentWordIndex = 0,
    this.totalWords = 0,
  });

  @override
  State<SiaCharacterWidget> createState() => _SiaCharacterWidgetState();
}

class _SiaCharacterWidgetState extends State<SiaCharacterWidget>
    with TickerProviderStateMixin {
  // ── Animation Controllers ──────────────────────────────────────────
  late AnimationController _breathController;
  late AnimationController _blinkController;
  late AnimationController _mouthController;
  late AnimationController _hairSwayController;
  late AnimationController _gestureController;
  late AnimationController _headTiltController;
  late AnimationController _glowPulseController;
  late AnimationController _particleController;

  // ── Derived animations ─────────────────────────────────────────────
  late Animation<double> _breathAnim;
  late Animation<double> _hairSwayAnim;
  late Animation<double> _glowPulseAnim;

  // ── Blink state ────────────────────────────────────────────────────
  bool _isBlinking = false;
  final math.Random _random = math.Random();

  // ── Mouth openness (driven by word index changes) ──────────────────
  double _mouthOpenness = 0.0;
  int _lastWordIndex = -1;

  // ── Particles ──────────────────────────────────────────────────────
  late List<_Particle> _particles;

  @override
  void initState() {
    super.initState();

    // 1. Breathing — subtle vertical scale (continuous)
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
    _breathAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );

    // 2. Blink — triggered periodically
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scheduleBlink();

    // 3. Mouth — fast spring to open/close
    _mouthController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _mouthController.addListener(() {
      setState(() {
        _mouthOpenness = _mouthController.value;
      });
    });

    // 4. Hair sway — continuous sine
    _hairSwayController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();
    _hairSwayAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _hairSwayController, curve: Curves.linear),
    );

    // 5. Gesture — hand emphasis during speech
    _gestureController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // 6. Head tilt
    _headTiltController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat(reverse: true);

    // 7. Glow pulse
    _glowPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _glowPulseAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _glowPulseController, curve: Curves.easeInOut),
    );

    // 8. Particles
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    _particles = List.generate(18, (_) => _Particle.random(_random));
  }

  void _scheduleBlink() {
    final delay = Duration(milliseconds: 2500 + _random.nextInt(3000));
    Future.delayed(delay, () {
      if (!mounted) return;
      setState(() => _isBlinking = true);
      _blinkController.forward().then((_) {
        _blinkController.reverse().then((_) {
          if (mounted) {
            setState(() => _isBlinking = false);
            _scheduleBlink();
          }
        });
      });
    });
  }

  @override
  void didUpdateWidget(covariant SiaCharacterWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // ── Lip-sync: word index changed → open mouth briefly ──
    if (widget.currentWordIndex != _lastWordIndex && widget.isSpeaking) {
      _lastWordIndex = widget.currentWordIndex;
      final openAmount = 0.4 + _random.nextDouble() * 0.6; // 0.4..1.0
      _mouthController.value = openAmount;
      Future.delayed(const Duration(milliseconds: 80), () {
        if (mounted) {
          _mouthController.animateTo(
            0.12 + _random.nextDouble() * 0.08,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
          );
        }
      });

      // Trigger a hand gesture every ~4 words
      if (widget.currentWordIndex % 4 == 0 && widget.currentWordIndex > 0) {
        _gestureController.forward(from: 0.0).then((_) {
          if (mounted) _gestureController.reverse();
        });
      }
    }

    // Reset mouth when speech stops
    if (!widget.isSpeaking && oldWidget.isSpeaking) {
      _mouthController.animateTo(0.0,
          duration: const Duration(milliseconds: 200));
      _lastWordIndex = -1;
    }
  }

  @override
  void dispose() {
    _breathController.dispose();
    _blinkController.dispose();
    _mouthController.dispose();
    _hairSwayController.dispose();
    _gestureController.dispose();
    _headTiltController.dispose();
    _glowPulseController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  Color _stateColor() {
    switch (widget.state) {
      case SiaState.idle:
        return const Color(0xFF00D9FF);
      case SiaState.listening:
        return const Color(0xFFFF6B6B);
      case SiaState.thinking:
        return const Color(0xFFFFE66D);
      case SiaState.speaking:
        return const Color(0xFF4ECDC4);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _breathAnim,
        _hairSwayAnim,
        _glowPulseAnim,
        _gestureController,
        _headTiltController,
        _particleController,
      ]),
      builder: (context, _) {
        return CustomPaint(
          painter: _SiaCharacterPainter(
            breathValue: _breathAnim.value,
            hairSwayValue: _hairSwayAnim.value,
            mouthOpenness: _mouthOpenness,
            isBlinking: _isBlinking,
            gestureValue: _gestureController.value,
            headTiltValue: _headTiltController.value,
            glowPulse: _glowPulseAnim.value,
            particleProgress: _particleController.value,
            stateColor: _stateColor(),
            state: widget.state,
            isSpeaking: widget.isSpeaking,
            particles: _particles,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

// ─── Particle Data ────────────────────────────────────────────────────────────
class _Particle {
  double x; // 0..1 normalized
  double y; // 0..1 normalized
  double speed;
  double size;
  double opacity;
  double phase; // phase offset for sine drift

  _Particle({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.opacity,
    required this.phase,
  });

  factory _Particle.random(math.Random r) {
    return _Particle(
      x: r.nextDouble(),
      y: r.nextDouble(),
      speed: 0.15 + r.nextDouble() * 0.35,
      size: 1.5 + r.nextDouble() * 3.0,
      opacity: 0.2 + r.nextDouble() * 0.5,
      phase: r.nextDouble() * math.pi * 2,
    );
  }
}

// ─── The Custom Painter ───────────────────────────────────────────────────────
class _SiaCharacterPainter extends CustomPainter {
  final double breathValue;
  final double hairSwayValue;
  final double mouthOpenness;
  final bool isBlinking;
  final double gestureValue;
  final double headTiltValue;
  final double glowPulse;
  final double particleProgress;
  final Color stateColor;
  final SiaState state;
  final bool isSpeaking;
  final List<_Particle> particles;

  _SiaCharacterPainter({
    required this.breathValue,
    required this.hairSwayValue,
    required this.mouthOpenness,
    required this.isBlinking,
    required this.gestureValue,
    required this.headTiltValue,
    required this.glowPulse,
    required this.particleProgress,
    required this.stateColor,
    required this.state,
    required this.isSpeaking,
    required this.particles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height * 0.38; // character positioned upper-center
    final scale = size.width / 400; // scale relative to 400px reference width

    // ── 1. Background Glow Aura ──────────────────────────────────────
    _drawBackgroundGlow(canvas, size, centerX, centerY, scale);

    // ── 2. Floating Particles ────────────────────────────────────────
    _drawParticles(canvas, size);

    // ── 3. Body / Shoulders ──────────────────────────────────────────
    _drawBody(canvas, centerX, centerY, scale);

    // ── 4. Neck ──────────────────────────────────────────────────────
    _drawNeck(canvas, centerX, centerY, scale);

    // ── 5. Head (with subtle tilt) ───────────────────────────────────
    final headTiltAngle = math.sin(headTiltValue * math.pi * 2) * 0.03;
    canvas.save();
    canvas.translate(centerX, centerY);
    canvas.rotate(headTiltAngle);
    canvas.translate(-centerX, -centerY);

    _drawHair(canvas, centerX, centerY, scale);
    _drawFace(canvas, centerX, centerY, scale);
    _drawEyes(canvas, centerX, centerY, scale);
    _drawMouth(canvas, centerX, centerY, scale);
    _drawEyebrows(canvas, centerX, centerY, scale);

    canvas.restore();

    // ── 6. Arms / Hands ──────────────────────────────────────────────
    _drawArms(canvas, centerX, centerY, scale);

    // ── 7. Sound wave indicator during speaking ──────────────────────
    if (isSpeaking) {
      _drawSpeakingIndicator(canvas, centerX, centerY, scale);
    }
  }

  void _drawBackgroundGlow(
      Canvas canvas, Size size, double cx, double cy, double sc) {
    final glowRadius = 160 * sc * (0.8 + glowPulse * 0.4);
    final intensity = isSpeaking ? 0.35 : 0.18;

    // Primary radial glow
    final glowPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.5,
        colors: [
          stateColor.withValues(alpha: intensity * glowPulse),
          stateColor.withValues(alpha: intensity * 0.4 * glowPulse),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: glowRadius));

    canvas.drawCircle(Offset(cx, cy), glowRadius, glowPaint);

    // Outer subtle ring
    if (isSpeaking) {
      final ringRadius = glowRadius * 1.3;
      final ringPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5 * sc
        ..color = stateColor.withValues(alpha: 0.15 * glowPulse);
      canvas.drawCircle(Offset(cx, cy), ringRadius, ringPaint);

      final ringPaint2 = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0 * sc
        ..color = stateColor.withValues(alpha: 0.08 * glowPulse);
      canvas.drawCircle(Offset(cx, cy), ringRadius * 1.2, ringPaint2);
    }
  }

  void _drawParticles(Canvas canvas, Size size) {
    for (final p in particles) {
      final y = (p.y - particleProgress * p.speed) % 1.0;
      final x = p.x + math.sin(particleProgress * math.pi * 2 + p.phase) * 0.03;
      final opacity = p.opacity * (isSpeaking ? 1.0 : 0.4);

      final paint = Paint()
        ..color = stateColor.withValues(alpha: opacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, p.size * 0.8);
      canvas.drawCircle(
        Offset(x * size.width, y * size.height),
        p.size,
        paint,
      );
    }
  }

  void _drawBody(Canvas canvas, double cx, double cy, double sc) {
    // Upper body / shoulders — elegant curved shape
    final breathOffset = breathValue * 2 * sc;
    final bodyPath = Path();

    // Shoulder curve
    bodyPath.moveTo(cx - 80 * sc, cy + 65 * sc + breathOffset);
    bodyPath.quadraticBezierTo(
      cx - 70 * sc,
      cy + 40 * sc + breathOffset,
      cx - 25 * sc,
      cy + 30 * sc + breathOffset,
    );
    // Neck area right
    bodyPath.lineTo(cx + 25 * sc, cy + 30 * sc + breathOffset);
    bodyPath.quadraticBezierTo(
      cx + 70 * sc,
      cy + 40 * sc + breathOffset,
      cx + 80 * sc,
      cy + 65 * sc + breathOffset,
    );
    // Bottom curve
    bodyPath.quadraticBezierTo(
      cx + 85 * sc,
      cy + 110 * sc + breathOffset,
      cx + 60 * sc,
      cy + 140 * sc + breathOffset,
    );
    bodyPath.lineTo(cx - 60 * sc, cy + 140 * sc + breathOffset);
    bodyPath.quadraticBezierTo(
      cx - 85 * sc,
      cy + 110 * sc + breathOffset,
      cx - 80 * sc,
      cy + 65 * sc + breathOffset,
    );
    bodyPath.close();

    // Gradient fill for elegant top
    final bodyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF2D1B69),
          const Color(0xFF1A0E3E),
          const Color(0xFF0D0620).withValues(alpha: 0.8),
        ],
      ).createShader(Rect.fromLTWH(
        cx - 90 * sc,
        cy + 30 * sc,
        180 * sc,
        120 * sc,
      ));

    canvas.drawPath(bodyPath, bodyPaint);

    // Subtle collar/neckline highlight
    final collarPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2 * sc
      ..color = stateColor.withValues(alpha: 0.3);

    final collarPath = Path();
    collarPath.moveTo(cx - 20 * sc, cy + 32 * sc + breathOffset);
    collarPath.quadraticBezierTo(
      cx,
      cy + 38 * sc + breathOffset,
      cx + 20 * sc,
      cy + 32 * sc + breathOffset,
    );
    canvas.drawPath(collarPath, collarPaint);
  }

  void _drawNeck(Canvas canvas, double cx, double cy, double sc) {
    final neckPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFE8C4A0),
          const Color(0xFFD4A574),
        ],
      ).createShader(Rect.fromLTWH(
        cx - 12 * sc,
        cy + 10 * sc,
        24 * sc,
        25 * sc,
      ));

    final neckRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx, cy + 22 * sc),
        width: 24 * sc,
        height: 26 * sc,
      ),
      Radius.circular(8 * sc),
    );
    canvas.drawRRect(neckRect, neckPaint);
  }

  void _drawFace(Canvas canvas, double cx, double cy, double sc) {
    // Face — soft oval
    final facePaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.0, -0.3),
        radius: 1.0,
        colors: [
          const Color(0xFFF5D5B8),
          const Color(0xFFE8C4A0),
          const Color(0xFFD4A574),
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(Rect.fromCircle(
        center: Offset(cx, cy - 15 * sc),
        radius: 45 * sc,
      ));

    final faceRect = Rect.fromCenter(
      center: Offset(cx, cy - 12 * sc),
      width: 72 * sc,
      height: 85 * sc,
    );
    canvas.drawOval(faceRect, facePaint);

    // Subtle cheek blush
    final blushPaint = Paint()
      ..color = const Color(0xFFFFB4B4).withValues(alpha: 0.25)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 10 * sc);
    canvas.drawCircle(Offset(cx - 22 * sc, cy - 3 * sc), 8 * sc, blushPaint);
    canvas.drawCircle(Offset(cx + 22 * sc, cy - 3 * sc), 8 * sc, blushPaint);
  }

  void _drawEyes(Canvas canvas, double cx, double cy, double sc) {
    final eyeY = cy - 18 * sc;
    final eyeSpacing = 16 * sc;

    for (final side in [-1.0, 1.0]) {
      final eyeX = cx + side * eyeSpacing;

      if (isBlinking) {
        // Closed eye — horizontal line
        final closedPaint = Paint()
          ..color = const Color(0xFF3D2914)
          ..strokeWidth = 2.0 * sc
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;
        canvas.drawLine(
          Offset(eyeX - 7 * sc, eyeY),
          Offset(eyeX + 7 * sc, eyeY),
          closedPaint,
        );
      } else {
        // Eye white
        final eyeWhitePaint = Paint()..color = Colors.white;
        final eyeRect = Rect.fromCenter(
          center: Offset(eyeX, eyeY),
          width: 16 * sc,
          height: 11 * sc,
        );
        canvas.drawOval(eyeRect, eyeWhitePaint);

        // Iris
        final irisPaint = Paint()..color = const Color(0xFF4A2C1A);
        canvas.drawCircle(Offset(eyeX, eyeY + 0.5 * sc), 4.5 * sc, irisPaint);

        // Pupil
        final pupilPaint = Paint()..color = const Color(0xFF1A0A00);
        canvas.drawCircle(Offset(eyeX, eyeY + 0.5 * sc), 2.5 * sc, pupilPaint);

        // Eye shine
        final shinePaint = Paint()..color = Colors.white.withValues(alpha: 0.9);
        canvas.drawCircle(
          Offset(eyeX - 1.5 * sc, eyeY - 1.5 * sc),
          1.5 * sc,
          shinePaint,
        );

        // Upper eyelid line
        final lidPaint = Paint()
          ..color = const Color(0xFF3D2914)
          ..strokeWidth = 1.5 * sc
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;
        final lidPath = Path();
        lidPath.moveTo(eyeX - 8 * sc, eyeY - 1 * sc);
        lidPath.quadraticBezierTo(
          eyeX,
          eyeY - 7 * sc,
          eyeX + 8 * sc,
          eyeY - 1 * sc,
        );
        canvas.drawPath(lidPath, lidPaint);

        // Eyelashes (subtle)
        if (side == -1.0) {
          // Left eye outer lashes
          canvas.drawLine(
            Offset(eyeX - 8 * sc, eyeY - 2 * sc),
            Offset(eyeX - 10 * sc, eyeY - 5 * sc),
            lidPaint..strokeWidth = 1.0 * sc,
          );
        } else {
          canvas.drawLine(
            Offset(eyeX + 8 * sc, eyeY - 2 * sc),
            Offset(eyeX + 10 * sc, eyeY - 5 * sc),
            lidPaint..strokeWidth = 1.0 * sc,
          );
        }
      }
    }
  }

  void _drawEyebrows(Canvas canvas, double cx, double cy, double sc) {
    final browY = cy - 30 * sc;
    final browPaint = Paint()
      ..color = const Color(0xFF3D2914).withValues(alpha: 0.7)
      ..strokeWidth = 2.0 * sc
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Slight expression based on state
    final raise = state == SiaState.listening ? -2 * sc : 0.0;

    for (final side in [-1.0, 1.0]) {
      final browPath = Path();
      final browCx = cx + side * 16 * sc;
      browPath.moveTo(browCx - 10 * sc * side, browY + 3 * sc + raise);
      browPath.quadraticBezierTo(
        browCx,
        browY - 2 * sc + raise,
        browCx + 10 * sc * side,
        browY + 1 * sc + raise,
      );
      canvas.drawPath(browPath, browPaint);
    }
  }

  void _drawMouth(Canvas canvas, double cx, double cy, double sc) {
    final mouthY = cy + 5 * sc;
    final mouthWidth = 16 * sc;
    final openHeight = mouthOpenness * 10 * sc; // 0..10 scaled

    if (mouthOpenness > 0.15) {
      // Open mouth — ellipse
      final mouthPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFC74040),
            const Color(0xFF8B2020),
          ],
        ).createShader(Rect.fromCenter(
          center: Offset(cx, mouthY + openHeight * 0.3),
          width: mouthWidth * (0.6 + mouthOpenness * 0.4),
          height: openHeight.clamp(3 * sc, 12 * sc),
        ));

      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx, mouthY + openHeight * 0.3),
          width: mouthWidth * (0.6 + mouthOpenness * 0.4),
          height: openHeight.clamp(3 * sc, 12 * sc),
        ),
        mouthPaint,
      );

      // Upper lip
      final lipPaint = Paint()
        ..color = const Color(0xFFE07070)
        ..strokeWidth = 1.5 * sc
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      final lipPath = Path();
      lipPath.moveTo(cx - mouthWidth * 0.4, mouthY);
      lipPath.quadraticBezierTo(cx, mouthY - 2 * sc, cx + mouthWidth * 0.4, mouthY);
      canvas.drawPath(lipPath, lipPaint);
    } else {
      // Closed — gentle smile curve
      final smilePaint = Paint()
        ..color = const Color(0xFFD06060)
        ..strokeWidth = 2.0 * sc
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      final smilePath = Path();
      smilePath.moveTo(cx - 10 * sc, mouthY);
      smilePath.quadraticBezierTo(
        cx,
        mouthY + 5 * sc,
        cx + 10 * sc,
        mouthY,
      );
      canvas.drawPath(smilePath, smilePaint);
    }

    // Nose (simple)
    final nosePaint = Paint()
      ..color = const Color(0xFFD4A574).withValues(alpha: 0.6)
      ..strokeWidth = 1.5 * sc
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final nosePath = Path();
    nosePath.moveTo(cx - 1 * sc, cy - 8 * sc);
    nosePath.quadraticBezierTo(
      cx - 4 * sc,
      cy - 1 * sc,
      cx,
      cy,
    );
    canvas.drawPath(nosePath, nosePaint);
  }

  void _drawHair(Canvas canvas, double cx, double cy, double sc) {
    final sway = math.sin(hairSwayValue * math.pi * 2) * 4 * sc;
    final speakingSway = isSpeaking ? sway * 1.5 : sway;

    // Hair color gradient
    final hairColors = [
      const Color(0xFF1A0A2E),
      const Color(0xFF2D1557),
      const Color(0xFF4A2080),
    ];

    final hairPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: hairColors,
      ).createShader(Rect.fromLTWH(
        cx - 60 * sc,
        cy - 80 * sc,
        120 * sc,
        150 * sc,
      ));

    // Main hair volume — top
    final hairPath = Path();
    hairPath.moveTo(cx - 40 * sc + speakingSway * 0.3, cy - 55 * sc);
    hairPath.quadraticBezierTo(
      cx - 50 * sc + speakingSway * 0.5,
      cy - 75 * sc,
      cx,
      cy - 72 * sc,
    );
    hairPath.quadraticBezierTo(
      cx + 50 * sc + speakingSway * 0.5,
      cy - 75 * sc,
      cx + 40 * sc + speakingSway * 0.3,
      cy - 55 * sc,
    );

    // Right side hair flowing down
    hairPath.quadraticBezierTo(
      cx + 48 * sc + speakingSway * 0.8,
      cy - 20 * sc,
      cx + 45 * sc + speakingSway,
      cy + 25 * sc,
    );
    hairPath.quadraticBezierTo(
      cx + 42 * sc + speakingSway * 1.2,
      cy + 60 * sc,
      cx + 35 * sc + speakingSway * 0.6,
      cy + 80 * sc,
    );

    // Bottom strand
    hairPath.lineTo(cx + 25 * sc, cy + 70 * sc);
    hairPath.lineTo(cx - 25 * sc, cy + 70 * sc);

    // Left side hair flowing down
    hairPath.quadraticBezierTo(
      cx - 42 * sc - speakingSway * 1.2,
      cy + 60 * sc,
      cx - 45 * sc - speakingSway,
      cy + 25 * sc,
    );
    hairPath.quadraticBezierTo(
      cx - 48 * sc - speakingSway * 0.8,
      cy - 20 * sc,
      cx - 40 * sc + speakingSway * 0.3,
      cy - 55 * sc,
    );
    hairPath.close();

    canvas.drawPath(hairPath, hairPaint);

    // Hair shine highlight
    final shinePaint = Paint()
      ..color = const Color(0xFF7B4EB8).withValues(alpha: 0.3)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6 * sc);
    final shinePath = Path();
    shinePath.moveTo(cx - 10 * sc, cy - 68 * sc);
    shinePath.quadraticBezierTo(
      cx + 5 * sc,
      cy - 60 * sc,
      cx + 15 * sc,
      cy - 65 * sc,
    );
    shinePath.quadraticBezierTo(
      cx + 5 * sc,
      cy - 55 * sc,
      cx - 10 * sc,
      cy - 60 * sc,
    );
    shinePath.close();
    canvas.drawPath(shinePath, shinePaint);

    // Individual flowing strands for more realism
    final strandPaint = Paint()
      ..color = const Color(0xFF3A1B6E).withValues(alpha: 0.5)
      ..strokeWidth = 1.5 * sc
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 3; i++) {
      final strandPath = Path();
      final strandX = cx + (i - 1) * 15 * sc;
      final strandSway = speakingSway * (0.8 + i * 0.15);
      strandPath.moveTo(strandX, cy - 50 * sc);
      strandPath.quadraticBezierTo(
        strandX + strandSway * 0.5 + (i - 1) * 5 * sc,
        cy + 10 * sc,
        strandX + strandSway + (i - 1) * 8 * sc,
        cy + 65 * sc,
      );
      canvas.drawPath(strandPath, strandPaint);
    }
  }

  void _drawArms(Canvas canvas, double cx, double cy, double sc) {
    final breathOffset = breathValue * 2 * sc;

    // Arm skin color
    final armPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFE8C4A0),
          const Color(0xFFD4A574),
        ],
      ).createShader(Rect.fromLTWH(cx - 100 * sc, cy + 50 * sc, 200 * sc, 80 * sc));

    // Left arm
    final leftArmPath = Path();
    leftArmPath.moveTo(cx - 72 * sc, cy + 55 * sc + breathOffset);
    leftArmPath.quadraticBezierTo(
      cx - 90 * sc,
      cy + 85 * sc + breathOffset,
      cx - 80 * sc,
      cy + 115 * sc + breathOffset,
    );
    leftArmPath.quadraticBezierTo(
      cx - 78 * sc,
      cy + 120 * sc + breathOffset,
      cx - 70 * sc,
      cy + 115 * sc + breathOffset,
    );
    leftArmPath.quadraticBezierTo(
      cx - 78 * sc,
      cy + 90 * sc + breathOffset,
      cx - 62 * sc,
      cy + 60 * sc + breathOffset,
    );
    leftArmPath.close();
    canvas.drawPath(leftArmPath, armPaint);

    // Right arm — animated gesture during speaking
    final gestureRaise = gestureValue * 25 * sc;
    final gestureSwing = math.sin(gestureValue * math.pi) * 15 * sc;

    final rightArmPath = Path();
    rightArmPath.moveTo(cx + 72 * sc, cy + 55 * sc + breathOffset);
    rightArmPath.quadraticBezierTo(
      cx + 90 * sc + gestureSwing,
      cy + 85 * sc + breathOffset - gestureRaise,
      cx + 80 * sc + gestureSwing * 0.5,
      cy + 115 * sc + breathOffset - gestureRaise,
    );
    rightArmPath.quadraticBezierTo(
      cx + 78 * sc + gestureSwing * 0.3,
      cy + 120 * sc + breathOffset - gestureRaise,
      cx + 70 * sc,
      cy + 115 * sc + breathOffset - gestureRaise * 0.5,
    );
    rightArmPath.quadraticBezierTo(
      cx + 78 * sc,
      cy + 90 * sc + breathOffset - gestureRaise * 0.3,
      cx + 62 * sc,
      cy + 60 * sc + breathOffset,
    );
    rightArmPath.close();
    canvas.drawPath(rightArmPath, armPaint);

    // Hand circles at arm ends
    final handPaint = Paint()..color = const Color(0xFFE8C4A0);
    // Left hand
    canvas.drawCircle(
      Offset(cx - 78 * sc, cy + 116 * sc + breathOffset),
      5 * sc,
      handPaint,
    );
    // Right hand (gesture-animated)
    canvas.drawCircle(
      Offset(
        cx + 78 * sc + gestureSwing * 0.5,
        cy + 116 * sc + breathOffset - gestureRaise,
      ),
      5 * sc,
      handPaint,
    );
  }

  void _drawSpeakingIndicator(
      Canvas canvas, double cx, double cy, double sc) {
    // Small animated equalizer bars below the character
    final barY = cy + 150 * sc;
    final barPaint = Paint()..color = stateColor;

    for (int i = 0; i < 5; i++) {
      final offset = (i - 2).abs() * 0.2;
      final height =
          4 * sc + math.sin((particleProgress + offset) * math.pi * 2) * 6 * sc;
      final barX = cx + (i - 2) * 8 * sc;
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(barX, barY), width: 3 * sc, height: height),
        Radius.circular(1.5 * sc),
      );
      canvas.drawRRect(rect, barPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SiaCharacterPainter oldDelegate) => true;
}
