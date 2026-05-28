import 'dart:math';
import 'package:flutter/material.dart';

class ConfettiOverlay extends StatefulWidget {
  final Widget child;
  final bool play;

  const ConfettiOverlay({super.key, required this.child, this.play = false});

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = [];
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _controller.addListener(() => setState(() {}));
  }

  @override
  void didUpdateWidget(ConfettiOverlay old) {
    super.didUpdateWidget(old);
    if (widget.play && !old.play) {
      _spawnParticles();
      _controller.forward(from: 0);
    }
  }

  void _spawnParticles() {
    _particles.clear();
    const colors = [Color(0xFFFFD700), Color(0xFFFF9500), Color(0xFF5AC8FA)];
    for (int i = 0; i < 40; i++) {
      _particles.add(_Particle(
        x: _random.nextDouble(),
        color: colors[_random.nextInt(colors.length)],
        speed: 0.01 + _random.nextDouble() * 0.03,
        size: 4 + _random.nextDouble() * 6,
        drift: -0.5 + _random.nextDouble(),
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_controller.value > 0 && _controller.value < 1)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _ConfettiPainter(
                  particles: _particles,
                  progress: _controller.value,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Particle {
  final double x;
  final Color color;
  final double speed;
  final double size;
  final double drift;
  _Particle({
    required this.x,
    required this.color,
    required this.speed,
    required this.size,
    required this.drift,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final y = size.height * (p.speed * 30) * progress * progress;
      final x = size.width * p.x + sin(progress * 10 + p.drift) * 30;
      final paint = Paint()
        ..color = p.color.withAlpha((255 * (1 - progress)).toInt());
      canvas.drawRect(
        Rect.fromCenter(
            center: Offset(x, y - 20), width: p.size, height: p.size * 0.6),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) =>
      old.progress != progress || old.particles != particles;
}
