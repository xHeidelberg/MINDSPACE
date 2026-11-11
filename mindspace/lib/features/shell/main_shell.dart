import 'package:flutter/material.dart';

import '../../all.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final unread = ChatService.unreadCount();

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<int>(
    valueListenable: currentTab,
    builder: (_, i, _) => Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            StreamBuilder<UserProfile?>(
              stream: DbService.profile(),
              builder: (_, s) {
                final p = s.data;
                if (p == null || !p.restricted) return const SizedBox.shrink();
                final pending = p.consentStatus == 'pending';
                return Material(
                  color: const Color(0xFFFFF3D6),
                  child: ListTile(
                    dense: true,
                    leading: const Icon(
                      Icons.family_restroom,
                      color: Color(0xFFB57A00),
                    ),
                    title: Text(
                      pending
                          ? 'Consent form under review'
                          : 'Parental consent needed to unlock all features',
                      style: const TextStyle(fontSize: 13),
                    ),
                    trailing: pending
                        ? null
                        : TextButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ConsentScreen(),
                              ),
                            ),
                            child: const Text('Upload'),
                          ),
                  ),
                );
              },
            ),
            Expanded(
              child: IndexedStack(
                index: i,
                children: const [
                  HomeTab(),
                  ActivitiesTab(),
                  AppointmentsTab(),
                  MessagesScreen(),
                  ProfileTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: StreamBuilder<int>(
        stream: unread,
        builder: (_, s) {
          final n = s.data ?? 0;
          return NavigationBar(
            backgroundColor: Colors.white,
            indicatorColor: kPrimary.withValues(alpha: .15),
            selectedIndex: i,
            onDestinationSelected: (v) => currentTab.value = v,
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home, color: kPrimary),
                label: 'Home',
              ),
              const NavigationDestination(
                icon: Icon(Icons.timer_outlined),
                selectedIcon: Icon(Icons.timer, color: kPrimary),
                label: 'Take 5',
              ),
              const NavigationDestination(
                icon: Icon(Icons.calendar_today_outlined),
                selectedIcon: Icon(Icons.calendar_today, color: kPrimary),
                label: 'Sessions',
              ),
              NavigationDestination(
                icon: Badge.count(
                  count: n,
                  isLabelVisible: n > 0,
                  child: const Icon(Icons.chat_bubble_outline),
                ),
                selectedIcon: Badge.count(
                  count: n,
                  isLabelVisible: n > 0,
                  child: const Icon(Icons.chat_bubble, color: kPrimary),
                ),
                label: 'Messages',
              ),
              const NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person, color: kPrimary),
                label: 'Profile',
              ),
            ],
          );
        },
      ),
    ),
  );
}
