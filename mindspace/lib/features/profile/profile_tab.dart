import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../all.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  Widget _row(
    BuildContext c,
    IconData i,
    String t, {
    String? info,
    Widget? go,
    VoidCallback? onTapOverride,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Box(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(i, color: kPrimary),
        title: Text(
          t,
          style: const TextStyle(fontWeight: FontWeight.w600, color: kText),
        ),
        trailing: const Icon(Icons.chevron_right, color: kMuted),
        onTap:
            onTapOverride ??
            (go != null
                ? () => Navigator.push(c, MaterialPageRoute(builder: (_) => go))
                : info == null
                ? () {}
                : () => showDialog(
                    context: c,
                    builder: (d) => AlertDialog(
                      title: Text(t),
                      content: Text(info),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(d),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  )),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => StreamBuilder<UserProfile?>(
    stream: DbService.profile(),
    builder: (_, s) {
      final p = s.data;
      final status = p == null
          ? ''
          : !p.isMinor
          ? 'Adult account'
          : p.consentStatus == 'approved'
          ? 'Parental consent verified'
          : p.consentStatus == 'pending'
          ? 'Consent under review'
          : 'Consent needed';
      final hasPic = p?.photoUrl.isNotEmpty ?? false;
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 8),
          Center(
            child: CircleAvatar(
              radius: 46,
              backgroundColor: kPrimary,
              backgroundImage: hasPic ? NetworkImage(p!.photoUrl) : null,
              child: hasPic
                  ? null
                  : Text(
                      (p?.name.isNotEmpty ?? false)
                          ? p!.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 38,
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Center(child: Text(p?.name ?? '', style: kTitle)),
          if (p?.username.isNotEmpty ?? false)
            Center(
              child: Text(
                '@${p!.username}',
                style: const TextStyle(
                  color: kPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (p?.bio.isNotEmpty ?? false)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Center(
                child: Text(
                  p!.bio,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: kMuted),
                ),
              ),
            ),
          Center(
            child: Text(
              FirebaseAuth.instance.currentUser?.email ?? '',
              style: const TextStyle(color: kMuted, fontSize: 12),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Chip(
              avatar: Icon(
                (p?.restricted ?? false)
                    ? Icons.lock_outline
                    : Icons.verified_outlined,
                size: 16,
                color: kPrimary,
              ),
              label: Text(status),
              backgroundColor: kPrimary.withValues(alpha: .1),
              side: BorderSide.none,
            ),
          ),
          if ((p?.restricted ?? false) && p?.consentStatus == 'none')
            Center(
              child: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ConsentScreen()),
                ),
                child: const Text('Upload parental consent'),
              ),
            ),
          const SizedBox(height: 18),
          _row(
            context,
            Icons.edit_outlined,
            'Edit profile',
            go: const EditProfileScreen(),
          ),
          _row(context, Icons.auto_awesome, 'My day', go: const MyDayScreen()),
          _row(
            context,
            Icons.group_outlined,
            'Friends',
            go: const FriendsScreen(),
          ),
          _row(
            context,
            Icons.chat_bubble_outline,
            'Messages',
            go: const MessagesScreen(),
          ),
          _row(context, Icons.notifications_none, 'Reminders'),
          _row(
            context,
            Icons.shield_outlined,
            'Privacy & your data',
            info: 'We only store what you add to your profile, your check-ins, bookings and day cards. We never ask for diagnoses or medical records.',
          ),
          _row(context, Icons.sos_outlined, 'Urgent help', info: kCrisisInfo),
          _row(
            context,
            Icons.info_outline,
            'About MindSpace',
            onTapOverride: () async {
              final i = await PackageInfo.fromPlatform();
              if (!context.mounted) return;
              showDialog(
                context: context,
                builder: (d) => AlertDialog(
                  title: const Text('About MindSpace'),
                  content: Text(
                    'Version ${i.version} (build ${i.buildNumber})\n\nMindSpace is a self-care companion, not a replacement for professional care.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(d),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.redAccent,
              minimumSize: const Size.fromHeight(50),
              side: const BorderSide(color: Colors.redAccent),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            onPressed: () async {
              await AuthService.signOut();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const AuthGate()),
                (_) => false,
              );
            },
            icon: const Icon(Icons.logout),
            label: const Text('Log out'),
          ),
        ],
      );
    },
  );
}
