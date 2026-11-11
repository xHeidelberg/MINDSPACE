import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

const _w = TextStyle(color: Colors.white);
Color _hex(String s) =>
    Color(int.parse('FF${s.replaceAll('#', '')}', radix: 16));

// ----- Breathing with any pattern: items = [in, hold, out, hold] seconds -----
class PatternBreathePlayer extends StatefulWidget {
  final List<String> items;
  const PatternBreathePlayer({super.key, required this.items});
  @override
  State<PatternBreathePlayer> createState() => _PatternState();
}

class _PatternState extends State<PatternBreathePlayer>
    with SingleTickerProviderStateMixin {
  late final p = widget.items.map(int.parse).toList();
  late final total = p.fold<int>(0, (a, b) => a + b);
  late final c = AnimationController(
    vsync: this,
    duration: Duration(seconds: total),
  )..repeat();
  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: c,
    builder: (_, _) {
      final t = c.value * total;
      var acc = 0.0, ph = 0, f = 0.0;
      for (var i = 0; i < 4; i++) {
        if (p[i] == 0) continue;
        if (t < acc + p[i]) {
          ph = i;
          f = (t - acc) / p[i];
          break;
        }
        acc += p[i];
      }
      final e = Curves.easeInOut.transform(f);
      final s = ph == 0
          ? .55 + .45 * e
          : ph == 1
          ? 1.0
          : ph == 2
          ? 1 - .45 * e
          : .55;
      Widget ring(double size, double o) => Container(
        width: size * s,
        height: size * s,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: o),
        ),
      );
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 280,
            height: 280,
            child: Stack(
              alignment: Alignment.center,
              children: [
                ring(280, .12),
                ring(220, .2),
                Container(
                  width: 150 * s,
                  height: 150 * s,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: Text(
                    '${(p[ph] * (1 - f)).ceil()}',
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF3F8F8A),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Text(
            ['Breathe in', 'Hold', 'Breathe out', 'Hold'][ph],
            style: _w.copyWith(fontSize: 30, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            p.where((x) => x > 0).join(' · ') + ' seconds',
            style: _w.copyWith(color: Colors.white70),
          ),
        ],
      );
    },
  );
}

// ----- Floating things to tap: items = [emoji] -----
class _F {
  double x, speed, size, off, popAt = -1;
  _F(this.x, this.speed, this.size, this.off);
}

class FloatPlayer extends StatefulWidget {
  final List<String> items;
  const FloatPlayer({super.key, required this.items});
  @override
  State<FloatPlayer> createState() => _FloatState();
}

class _FloatState extends State<FloatPlayer>
    with SingleTickerProviderStateMixin {
  final r = math.Random();
  late final bs = List.generate(
    9,
    (_) => _F(
      r.nextDouble(),
      .05 + r.nextDouble() * .07,
      44 + r.nextDouble() * 30,
      r.nextDouble(),
    ),
  );
  late final Ticker tk;
  double t = 0;
  int pops = 0;

  @override
  void initState() {
    super.initState();
    tk = createTicker((d) {
      t = d.inMilliseconds / 1000;
      for (final b in bs) {
        if (b.popAt >= 0 && t - b.popAt > .25) {
          b.popAt = -1;
          b.x = r.nextDouble();
          b.off = (1 - (t * b.speed) % 1) % 1;
        }
      }
      setState(() {});
    })..start();
  }

  @override
  void dispose() {
    tk.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (_, cs) {
      final w = cs.maxWidth, h = cs.maxHeight;
      return Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Collected $pops  ·  no score, just breathe',
                style: _w.copyWith(color: Colors.white70),
              ),
            ),
          ),
          for (final b in bs)
            Positioned(
              left: b.x * (w - b.size) + math.sin(t * .8 + b.off * 6) * 12,
              top: (1 - ((t * b.speed + b.off) % 1)) * (h + b.size) - b.size,
              child: GestureDetector(
                onTap: () {
                  if (b.popAt >= 0) return;
                  HapticFeedback.lightImpact();
                  setState(() {
                    b.popAt = t;
                    pops++;
                  });
                },
                child: Builder(
                  builder: (_) {
                    final p = b.popAt < 0
                        ? 0.0
                        : ((t - b.popAt) / .25).clamp(0.0, 1.0);
                    return Opacity(
                      opacity: 1 - p,
                      child: Transform.scale(
                        scale: 1 + p * .6,
                        child: Text(
                          widget.items[0],
                          style: TextStyle(fontSize: b.size),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      );
    },
  );
}

// ----- Drawing with palette + mirroring: items = [mirrorCount, #hex, #hex...] -----
class PaintPlayer extends StatefulWidget {
  final List<String> items;
  const PaintPlayer({super.key, required this.items});
  @override
  State<PaintPlayer> createState() => _PaintState();
}

class _PaintState extends State<PaintPlayer> {
  final strokes = <List<Offset>>[];
  @override
  Widget build(BuildContext context) {
    final mirror = int.parse(widget.items[0]);
    final colors = widget.items.skip(1).map(_hex).toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Column(
        children: [
          Text(
            mirror > 1
                ? 'Draw once. It repeats $mirror times.'
                : 'Draw anything. No one will see it.',
            style: _w.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Container(
                color: Colors.white.withValues(alpha: .14),
                child: GestureDetector(
                  onPanStart: (d) =>
                      setState(() => strokes.add([d.localPosition])),
                  onPanUpdate: (d) =>
                      setState(() => strokes.last.add(d.localPosition)),
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: _PaintPainter(strokes, mirror, colors),
                  ),
                ),
              ),
            ),
          ),
          TextButton.icon(
            onPressed: () => setState(strokes.clear),
            icon: const Icon(Icons.refresh, color: Colors.white70),
            label: const Text(
              'Start fresh',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaintPainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final int mirror;
  final List<Color> colors;
  _PaintPainter(this.strokes, this.mirror, this.colors);
  @override
  void paint(Canvas cv, Size s) {
    final mid = Offset(s.width / 2, s.height / 2);
    for (var k = 0; k < mirror; k++) {
      cv.save();
      cv.translate(mid.dx, mid.dy);
      cv.rotate(2 * math.pi * k / mirror);
      cv.translate(-mid.dx, -mid.dy);
      for (var si = 0; si < strokes.length; si++) {
        final st = strokes[si];
        final p = Paint()
          ..strokeWidth = 7
          ..strokeCap = StrokeCap.round;
        if (st.length == 1) {
          p.color = colors[si % colors.length];
          cv.drawCircle(st.first, 3.5, p);
        }
        for (var j = 1; j < st.length; j++) {
          p.color = colors[(si + j ~/ 8) % colors.length];
          cv.drawLine(st[j - 1], st[j], p);
        }
      }
      cv.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _PaintPainter o) => true;
}

// ----- Guided moves: items = ['emoji|instruction', ...] -----
class MovesPlayer extends StatefulWidget {
  final List<String> items;
  const MovesPlayer({super.key, required this.items});
  @override
  State<MovesPlayer> createState() => _MovesState();
}

class _MovesState extends State<MovesPlayer>
    with SingleTickerProviderStateMixin {
  late final bounce = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);
  int i = 0, s = 30;
  Timer? tm;
  @override
  void initState() {
    super.initState();
    tm = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(() {
        if (--s <= 0) _next();
      }),
    );
  }

  void _next() {
    s = 30;
    i = (i + 1) % widget.items.length;
  }

  @override
  void dispose() {
    tm?.cancel();
    bounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.items[i].split('|');
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Move ${i + 1} of ${widget.items.length}',
          style: _w.copyWith(color: Colors.white70),
        ),
        const SizedBox(height: 16),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          transitionBuilder: (c, a) => FadeTransition(
            opacity: a,
            child: SlideTransition(
              position: Tween(
                begin: const Offset(.2, 0),
                end: Offset.zero,
              ).animate(a),
              child: c,
            ),
          ),
          child: Column(
            key: ValueKey(i),
            children: [
              AnimatedBuilder(
                animation: bounce,
                builder: (_, _) => Transform.translate(
                  offset: Offset(
                    0,
                    -16 * Curves.easeInOut.transform(bounce.value),
                  ),
                  child: Text(m[0], style: const TextStyle(fontSize: 100)),
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  m[1],
                  textAlign: TextAlign.center,
                  style: _w.copyWith(fontSize: 22, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: 76,
          height: 76,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox.expand(
                child: CircularProgressIndicator(
                  value: s / 30,
                  strokeWidth: 6,
                  color: Colors.white,
                  backgroundColor: Colors.white24,
                ),
              ),
              Text(
                '$s',
                style: _w.copyWith(fontSize: 22, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: () => setState(_next),
          child: const Text(
            'Next move',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      ],
    );
  }
}

// ----- Guided writing: items = prompts. Nothing is saved. -----
class WritePlayer extends StatefulWidget {
  final List<String> items;
  final VoidCallback onDone;
  const WritePlayer({super.key, required this.items, required this.onDone});
  @override
  State<WritePlayer> createState() => _WriteState();
}

class _WriteState extends State<WritePlayer> {
  final ctrl = TextEditingController();
  int i = 0;
  void _next() {
    ctrl.clear();
    if (i == widget.items.length - 1) {
      widget.onDone();
    } else {
      setState(() => i++);
    }
  }

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Center(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: Column(
          key: ValueKey(i),
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Step ${i + 1} of ${widget.items.length}',
              style: _w.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 10),
            Text(
              widget.items[i],
              textAlign: TextAlign.center,
              style: _w.copyWith(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              maxLines: 3,
              maxLength: 100,
              onChanged: (_) => setState(() {}),
              style: _w,
              cursorColor: Colors.white,
              decoration: InputDecoration(
                hintText: 'Type here...',
                hintStyle: const TextStyle(color: Colors.white54),
                counterStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.white.withValues(alpha: .18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            Text(
              'Never saved. It stays on your screen only.',
              style: _w.copyWith(color: Colors.white60, fontSize: 12),
            ),
            const SizedBox(height: 14),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFFD89B2B),
                minimumSize: const Size(200, 48),
              ),
              onPressed: ctrl.text.trim().isEmpty ? null : _next,
              child: Text(i == widget.items.length - 1 ? 'Finish' : 'Next'),
            ),
          ],
        ),
      ),
    ),
  );
}

// ----- Ambient scenes: items = [style, #top, #bottom]; tap for ripples -----
class _Rp {
  final Offset p;
  final double t;
  _Rp(this.p, this.t);
}

class SceneryPlayer extends StatefulWidget {
  final List<String> items;
  const SceneryPlayer({super.key, required this.items});
  @override
  State<SceneryPlayer> createState() => _SceneryState();
}

class _SceneryState extends State<SceneryPlayer>
    with SingleTickerProviderStateMixin {
  final sw = Stopwatch()..start();
  final rp = <_Rp>[];
  late final c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 10),
  )..repeat();
  double get now => sw.elapsedMilliseconds / 1000;
  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned.fill(
        child: GestureDetector(
          onTapDown: (d) {
            HapticFeedback.selectionClick();
            rp.add(_Rp(d.localPosition, now));
            if (rp.length > 12) rp.removeAt(0);
          },
          child: AnimatedBuilder(
            animation: c,
            builder: (_, _) => CustomPaint(
              painter: _ScenePainter(
                widget.items[0],
                _hex(widget.items[1]),
                _hex(widget.items[2]),
                now,
                List.of(rp),
              ),
            ),
          ),
        ),
      ),
      Align(
        alignment: Alignment.topCenter,
        child: IgnorePointer(
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Watch, or touch the screen.',
              style: _w.copyWith(color: Colors.white70),
            ),
          ),
        ),
      ),
    ],
  );
}

class _ScenePainter extends CustomPainter {
  final String style;
  final Color a, b;
  final double t;
  final List<_Rp> rp;
  _ScenePainter(this.style, this.a, this.b, this.t, this.rp);

  @override
  void paint(Canvas cv, Size s) {
    final rect = Offset.zero & s;
    cv.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [a, b],
        ).createShader(rect),
    );
    switch (style) {
      case 'waves':
        for (var k = 0; k < 3; k++) {
          final path = Path()..moveTo(0, s.height);
          for (double x = 0; x <= s.width; x += 6) {
            path.lineTo(
              x,
              s.height * (.58 + .1 * k) +
                  math.sin(
                        x / s.width * 2 * math.pi * (1.2 + .4 * k) +
                            t * (.6 + .25 * k) +
                            k,
                      ) *
                      (14 + 4.0 * k),
            );
          }
          path
            ..lineTo(s.width, s.height)
            ..close();
          cv.drawPath(
            path,
            Paint()..color = Colors.white.withValues(alpha: .12 + .08 * k),
          );
        }
      case 'rain':
        for (var i = 0; i < 70; i++) {
          final x = ((i * 53) % 100) / 100 * s.width,
              y = ((t * (.5 + (i % 5) * .1) + i * .137) % 1) * s.height;
          cv.drawLine(
            Offset(x, y),
            Offset(x - 3, y + 16),
            Paint()
              ..color = Colors.white.withValues(alpha: .45)
              ..strokeWidth = 1.6,
          );
        }
      case 'snow':
        for (var i = 0; i < 60; i++) {
          final x = ((i * 37) % 100) / 100 * s.width + math.sin(t + i) * 14,
              y = ((t * (.04 + (i % 4) * .02) + i * .171) % 1) * s.height;
          cv.drawCircle(
            Offset(x, y),
            2.0 + (i % 3),
            Paint()..color = Colors.white.withValues(alpha: .8),
          );
        }
      case 'aurora':
        for (var k = 0; k < 4; k++) {
          final y0 = s.height * (.25 + .1 * k);
          final path = Path()..moveTo(0, y0);
          for (double x = 0; x <= s.width; x += 8) {
            path.lineTo(
              x,
              y0 + math.sin(x / s.width * 2 * math.pi * 1.3 + t * .4 + k) * 40,
            );
          }
          cv.drawPath(
            path,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 46
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20)
              ..color =
                  (k.isEven ? const Color(0xFF4DFFB5) : const Color(0xFF8A7CFF))
                      .withValues(alpha: .25),
          );
        }
      default:
        for (var i = 0; i < 6; i++) {
          final c = Offset(
            s.width * (.5 + .38 * math.sin(t * .3 + i * 1.7)),
            s.height * (.5 + .4 * math.cos(t * .25 + i * 2.3)),
          );
          cv.drawCircle(
            c,
            s.width * (.18 + .04 * (i % 3)),
            Paint()
              ..color = Colors.white.withValues(alpha: .18)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30),
          );
        }
    }
    for (final r in rp) {
      final age = t - r.t;
      if (age > 3) continue;
      cv.drawCircle(
        r.p,
        age * 90,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = Colors.white.withValues(alpha: (1 - age / 3) * .7),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ScenePainter o) => true;
}
