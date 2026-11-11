import 'package:flutter/material.dart';

import '../../all.dart';

DateTime _day(DateTime x) => DateTime(x.year, x.month, x.day);

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  int _mins(Iterable<ProgressEntry> e) =>
      (e.fold<int>(0, (a, b) => a + b.seconds) / 60).round();

  String _label(DateTime d, DateTime today) {
    if (d == today) return 'Today';
    if (d == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return fmtDate(d);
  }

  Widget _stat(String label, String value) => Expanded(
    child: Box(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Text(value, style: kTitle.copyWith(fontSize: 26, color: kPrimary)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: kMuted, fontSize: 12)),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('My progress')),
    body: StreamBuilder<List<ProgressEntry>>(
      stream: ProgressService.stream(),
      builder: (_, s) {
        if (!s.hasData) return const Center(child: CircularProgressIndicator());
        final list = s.data!;
        final now = DateTime.now(), today = _day(now);
        final days = List.generate(
          7,
          (i) => today.subtract(Duration(days: 6 - i)),
        );
        final perDay = [
          for (final d in days) _mins(list.where((e) => _day(e.at) == d)),
        ];
        final peak = perDay.reduce((a, b) => a > b ? a : b).clamp(1, 1 << 30);
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                _stat('Today', '${perDay.last} min'),
                const SizedBox(width: 10),
                _stat(
                  'Last 7 days',
                  '${perDay.fold<int>(0, (a, b) => a + b)} min',
                ),
                const SizedBox(width: 10),
                _stat('All time', '${_mins(list)} min'),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${list.length} sessions in total. Every minute counts, and rest days are part of it. 💚',
              style: const TextStyle(color: kMuted, fontSize: 13),
            ),
            const SizedBox(height: 20),
            Text('Last 7 days', style: kTitle.copyWith(fontSize: 18)),
            const SizedBox(height: 10),
            Box(
              child: SizedBox(
                height: 120,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var i = 0; i < 7; i++)
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              perDay[i] > 0 ? '${perDay[i]}' : '',
                              style: const TextStyle(
                                fontSize: 10,
                                color: kMuted,
                              ),
                            ),
                            TweenAnimationBuilder<double>(
                              tween: Tween(
                                begin: 0,
                                end: 6 + 70 * perDay[i] / peak,
                              ),
                              duration: const Duration(milliseconds: 600),
                              curve: Curves.easeOutCubic,
                              builder: (_, h, _) => Container(
                                width: 18,
                                height: h,
                                decoration: BoxDecoration(
                                  color: days[i] == today
                                      ? kPrimary
                                      : kPrimary.withValues(alpha: .35),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'MTWTFSS'[days[i].weekday - 1],
                              style: TextStyle(
                                fontSize: 11,
                                color: days[i] == today ? kPrimary : kMuted,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('History', style: kTitle.copyWith(fontSize: 18)),
            const SizedBox(height: 10),
            if (list.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'Nothing yet. Your first Take 5 will appear here.',
                    style: TextStyle(color: kMuted),
                  ),
                ),
              ),
            for (var i = 0; i < list.length; i++) ...[
              if (i == 0 || _day(list[i].at) != _day(list[i - 1].at))
                Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 6),
                  child: Text(
                    _label(_day(list[i].at), today),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: kMuted,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Box(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        list[i].completed
                            ? Icons.check_circle
                            : Icons.timelapse,
                        color: list[i].completed ? kPrimary : kMuted,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              list[i].title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: kText,
                              ),
                            ),
                            Text(
                              '${list[i].type}${list[i].completed ? '' : ' · stopped early'}',
                              style: const TextStyle(
                                color: kMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        list[i].seconds >= 60
                            ? '${(list[i].seconds / 60).round()} min'
                            : '${list[i].seconds} s',
                        style: const TextStyle(color: kMuted),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        );
      },
    ),
  );
}
