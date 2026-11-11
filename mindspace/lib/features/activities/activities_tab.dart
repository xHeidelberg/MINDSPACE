import 'dart:async';

import 'package:flutter/material.dart';

import '../../all.dart';

final activityFilter = ValueNotifier<String>('All');
final minutesToday = ValueNotifier<int>(0);

const kTypes = ['Read', 'Write', 'Play', 'Watch', 'Move', 'Breathe'];
const kFocus = ['Anxiety', 'Stress', 'Eating', 'Depression'];

enum Kind {
  breathe,
  bubbles,
  stretch,
  ground,
  affirm,
  scene,
  worry,
  gratitude,
  squeeze,
  doodle,
  bodyscan,
  write,
  moves,
  pattern,
  float,
  paint,
  scenery,
}

class Activity {
  final String title, desc, type;
  final IconData icon;
  final Color color;
  final Kind kind;
  final List<String> focus, items;
  final bool free;
  const Activity(
    this.title,
    this.desc,
    this.type,
    this.icon,
    this.color,
    this.kind,
    this.focus, {
    this.items = const [],
    this.free = false,
  });
}

const activities = [
  Activity(
    'Box breathing',
    'Follow the glowing circle',
    'Breathe',
    Icons.air,
    Color(0xFF3F8F8A),
    Kind.breathe,
    ['Anxiety', 'Stress'],
    free: true,
  ),
  Activity(
    'Pop your worries',
    'Tap floating bubbles, no score',
    'Play',
    Icons.bubble_chart,
    Color(0xFF4A90D9),
    Kind.bubbles,
    ['Anxiety', 'Stress'],
  ),
  Activity(
    'Desk reset',
    'Six gentle moves for burnout',
    'Move',
    Icons.self_improvement,
    Color(0xFFE9895B),
    Kind.stretch,
    ['Stress', 'Depression'],
  ),
  Activity(
    '5-4-3-2-1 grounding',
    'Tap your way back to now',
    'Read',
    Icons.touch_app,
    Color(0xFF7B6FD0),
    Kind.ground,
    ['Anxiety'],
  ),
  Activity(
    'Kind words',
    'Swipe through gentle reminders',
    'Read',
    Icons.favorite_border,
    Color(0xFFD9638F),
    Kind.affirm,
    ['Depression', 'Anxiety'],
    items: [
      'You do not have to be perfect to be worthy.',
      'Small steps still count as progress.',
      'Your feelings are valid, and they will shift.',
      'Rest is productive too.',
      'You have gotten through hard days before.',
      'Be as gentle with yourself as you would be with a friend.',
    ],
  ),
  Activity(
    'Kind to my body',
    'Self-compassion around food',
    'Read',
    Icons.spa_outlined,
    Color(0xFF6FA86B),
    Kind.affirm,
    ['Eating'],
    items: [
      'My body deserves care, not punishment.',
      'Food is fuel and comfort, not a test.',
      'My worth is not measured by what I eat.',
      'It is okay to take up space.',
      'Every meal is a chance to be kind to myself.',
      'I am more than how I look.',
    ],
  ),
  Activity(
    'Ocean ripples',
    'Touch the water and unwind',
    'Watch',
    Icons.waves,
    Color(0xFF2F7DA6),
    Kind.scene,
    ['Stress', 'Depression', 'Anxiety'],
  ),
  Activity(
    'Worry release',
    'Write it, then watch it float away',
    'Write',
    Icons.cloud_upload_outlined,
    Color(0xFF5B7FA6),
    Kind.worry,
    ['Anxiety', 'Stress'],
  ),
  Activity(
    'Gratitude jar',
    'Fill a jar with three small good things',
    'Write',
    Icons.local_drink_outlined,
    Color(0xFFD89B2B),
    Kind.gratitude,
    ['Depression', 'Eating'],
  ),
  Activity(
    'Squeeze and release',
    'Tense, hold, then let go',
    'Move',
    Icons.fitness_center,
    Color(0xFFB0609A),
    Kind.squeeze,
    ['Anxiety', 'Stress'],
  ),
  Activity(
    'Calm doodle',
    'Draw with soft, glowing color',
    'Play',
    Icons.brush,
    Color(0xFFD9656F),
    Kind.doodle,
    ['Stress', 'Depression', 'Eating'],
  ),
  Activity(
    'Body scan',
    'A slow, guided wind-down',
    'Breathe',
    Icons.nights_stay_outlined,
    Color(0xFF3D6FA3),
    Kind.bodyscan,
    ['Anxiety', 'Stress'],
  ),
];

class ActivitiesTab extends StatelessWidget {
  const ActivitiesTab({super.key});

  void _open(BuildContext c, Activity a) async {
    if (!a.free && !await ensureAccess(c)) return;
    if (!c.mounted) return;
    Navigator.push(
      c,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, _, _) => ActivityRunner(a),
        transitionsBuilder: (_, anim, _, child) => FadeTransition(
          opacity: anim,
          child: ScaleTransition(
            scale: Tween(begin: .94, end: 1.0).animate(
              CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<String>(
    valueListenable: activityFilter,
    builder: (_, f, _) {
      final shown = [
        ...activities,
        ...moreActivities,
      ].where((a) => f == 'All' || a.type == f || a.focus.contains(f)).toList();
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Take 5', style: kTitle.copyWith(fontSize: 30)),
                    const Text(
                      'Tiny breaks, real relief.',
                      style: TextStyle(color: kMuted),
                    ),
                  ],
                ),
              ),
              ValueListenableBuilder<int>(
                valueListenable: minutesToday,
                builder: (_, m, _) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: kPrimary.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '🌱 $m min today',
                    style: const TextStyle(
                      color: kPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final c in ['All', ...kFocus, ...kTypes])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(c),
                      selected: f == c,
                      selectedColor: kPrimary,
                      showCheckmark: false,
                      labelStyle: TextStyle(
                        color: f == c ? Colors.white : kText,
                        fontWeight: FontWeight.w600,
                      ),
                      onSelected: (_) => activityFilter.value = c,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < shown.length; i++)
            TweenAnimationBuilder<double>(
              key: ValueKey('$f${shown[i].title}'),
              tween: Tween(begin: 0, end: 1),
              duration: Duration(milliseconds: 350 + i * 90),
              curve: Curves.easeOutCubic,
              builder: (_, v, child) => Opacity(
                opacity: v,
                child: Transform.translate(
                  offset: Offset(0, 28 * (1 - v)),
                  child: child,
                ),
              ),
              child: _Card(shown[i], () => _open(context, shown[i])),
            ),
        ],
      );
    },
  );
}

class _Card extends StatelessWidget {
  final Activity a;
  final VoidCallback onTap;
  const _Card(this.a, this.onTap);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [a.color, Color.lerp(a.color, Colors.black, .25)!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: const BoxDecoration(
                      color: Colors.white24,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(a.icon, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          a.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          a.desc,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${a.type.toUpperCase()}  ·  5 MIN',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.play_circle_fill,
                    color: Colors.white,
                    size: 36,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class ActivityRunner extends StatefulWidget {
  final Activity a;
  const ActivityRunner(this.a, {super.key});
  @override
  State<ActivityRunner> createState() => _ActivityRunnerState();
}

class _ActivityRunnerState extends State<ActivityRunner> {
  static const total = 300;
  int left = total;
  bool done = false;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => left--);
      if (left <= 0) _finish();
    });
  }

  void _finish() {
    if (done) return;
    timer?.cancel();
    final secs = total - left;
    minutesToday.value += (secs / 60).ceil().clamp(1, 5);
    DbService.logActivity(widget.a.title, secs).catchError((_) {});
    setState(() => done = true);
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Widget _player() {
    final a = widget.a;
    switch (a.kind) {
      case Kind.breathe:
        return const BreathePlayer();
      case Kind.bubbles:
        return const BubblesPlayer();
      case Kind.stretch:
        return const StretchPlayer();
      case Kind.ground:
        return GroundPlayer(onDone: _finish);
      case Kind.affirm:
        return AffirmPlayer(items: a.items, onDone: _finish);
      case Kind.scene:
        return const ScenePlayer();
      case Kind.worry:
        return WorryPlayer(onDone: _finish);
      case Kind.gratitude:
        return GratitudePlayer(onDone: _finish);
      case Kind.squeeze:
        return SqueezePlayer(onDone: _finish);
      case Kind.doodle:
        return const DoodlePlayer();
      case Kind.bodyscan:
        return BodyScanPlayer(onDone: _finish);
      case Kind.write:
        return WritePlayer(items: a.items, onDone: _finish);
      case Kind.moves:
        return MovesPlayer(items: a.items);
      case Kind.pattern:
        return PatternBreathePlayer(items: a.items);
      case Kind.float:
        return FloatPlayer(items: a.items);
      case Kind.paint:
        return PaintPlayer(items: a.items);
      case Kind.scenery:
        return SceneryPlayer(items: a.items);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.a;
    final mm = '${left ~/ 60}:${(left % 60).toString().padLeft(2, '0')}';
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [a.color, Color.lerp(a.color, Colors.black, .4)!],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 20, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        a.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Text(
                      done ? '' : mm,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                child: LinearProgressIndicator(
                  value: (total - left) / total,
                  minHeight: 5,
                  color: Colors.white,
                  backgroundColor: Colors.white24,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  child: done ? _Done(a, total - left) : _player(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: done
                    ? FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: a.color,
                          minimumSize: const Size(220, 50),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Back to Take 5'),
                      )
                    : TextButton(
                        onPressed: _finish,
                        child: const Text(
                          "I'm done early",
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Done extends StatelessWidget {
  final Activity a;
  final int secs;
  const _Done(this.a, this.secs);
  @override
  Widget build(BuildContext context) => Center(
    child: TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.elasticOut,
      builder: (_, v, _) => Transform.scale(
        scale: v,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check, size: 64, color: a.color),
            ),
            const SizedBox(height: 24),
            const Text(
              'Nice work 💚',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You gave yourself ${(secs / 60).ceil().clamp(1, 5)} min of calm.',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    ),
  );
}
