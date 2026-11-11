import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../all.dart';

const kReviewNotice =
    'Messages may be reviewed by MindSpace moderators to keep everyone safe.';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});
  @override
  State<MessagesScreen> createState() => _MessagesState();
}

class _MessagesState extends State<MessagesScreen> {
  bool requests = false;

  void _settings() async {
    var v = await ChatService.allowMessages();
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (d) => StatefulBuilder(
        builder: (_, set) => AlertDialog(
          title: const Text('Message settings'),
          content: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: v,
            activeThumbColor: kPrimary,
            title: const Text(
              'Allow messages from people who are not my friends',
            ),
            subtitle: const Text(
              'Friends can always message you. You can turn this off at any time.',
            ),
            onChanged: (x) {
              set(() => v = x);
              ChatService.setAllowMessages(x);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(d),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<UserProfile?>(
    stream: DbService.profile(),
    builder: (_, s) {
      final me = s.data;
      if (me == null)
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      if (me.isMinor)
        return Scaffold(
          appBar: AppBar(title: const Text('Messages')),
          body: const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'Messaging is available for ages 18+.',
                style: TextStyle(color: kMuted),
              ),
            ),
          ),
        );
      final uid = SocialService.uid;
      return Scaffold(
        appBar: AppBar(
          title: const Text('Messages'),
          actions: [
            IconButton(icon: const Icon(Icons.tune), onPressed: _settings),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: kPrimary,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.edit),
          label: const Text('New message'),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => NewMessageScreen(myLabel: me.label),
            ),
          ),
        ),
        body: StreamBuilder<List<Doc>>(
          stream: ChatService.conversations(),
          builder: (_, cs) {
            final all = cs.data ?? <Doc>[];
            final chats = all
                .where(
                  (d) =>
                      d['status'] == 'active' ||
                      (d['status'] == 'request' && d['initiator'] == uid),
                )
                .toList();
            final reqs = all
                .where((d) => d['status'] == 'request' && d['to'] == uid)
                .toList();
            final shown = requests ? reqs : chats;
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<bool>(
                    showSelectedIcon: false,
                    segments: [
                      const ButtonSegment(value: false, label: Text('Chats')),
                      ButtonSegment(
                        value: true,
                        label: Text('Requests (${reqs.length})'),
                      ),
                    ],
                    selected: {requests},
                    onSelectionChanged: (x) =>
                        setState(() => requests = x.first),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  kReviewNotice,
                  style: TextStyle(color: kMuted, fontSize: 12),
                ),
                const SizedBox(height: 12),
                if (shown.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        requests
                            ? 'No message requests.'
                            : 'No conversations yet.',
                        style: const TextStyle(color: kMuted),
                      ),
                    ),
                  ),
                for (final d in shown)
                  Builder(
                    builder: (_) {
                      final other = (d['members'] as List).firstWhere(
                        (m) => m != uid,
                      ) as String;
                      final name = (d['names'] as Map)[other] ?? 'User';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                otherUid: other,
                                otherLabel: name,
                                myLabel: me.label,
                              ),
                            ),
                          ),
                          child: Box(
                            child: Row(
                              children: [
                                const CircleAvatar(
                                  backgroundColor: kPrimary,
                                  child: Icon(
                                    Icons.person,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: TextStyle(
                                          fontWeight: ChatService.isUnread(d)
                                              ? FontWeight.w900
                                              : FontWeight.w700,
                                          color: kText,
                                        ),
                                      ),
                                      Text(
                                        d['lastText'] ?? '',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: kMuted,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (ChatService.isUnread(d))
                                  const CircleAvatar(
                                    radius: 6,
                                    backgroundColor: Colors.redAccent,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            );
          },
        ),
      );
    },
  );
}

class NewMessageScreen extends StatefulWidget {
  final String myLabel;
  const NewMessageScreen({super.key, required this.myLabel});
  @override
  State<NewMessageScreen> createState() => _NewMessageState();
}

class _NewMessageState extends State<NewMessageScreen> {
  final q = TextEditingController();
  List<Map<String, dynamic>> results = [];
  bool searched = false;

  void _open(String uid, String label) => Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (_) =>
          ChatScreen(otherUid: uid, otherLabel: label, myLabel: widget.myLabel),
    ),
  );

  Future<void> _search() async {
    final r = await SocialService.search(q.text);
    if (mounted)
      setState(() {
        results = r;
        searched = true;
      });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('New message')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        TextField(
          controller: q,
          onSubmitted: (_) => _search(),
          decoration: fieldDec(
            'Search by username',
            Icons.alternate_email,
            suffix: IconButton(
              icon: const Icon(Icons.arrow_forward),
              onPressed: _search,
            ),
          ),
        ),
        if (searched && results.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 14),
            child: Text(
              'No one found with that username.',
              style: TextStyle(color: kMuted),
            ),
          ),
        const SizedBox(height: 10),
        for (final r in results)
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: kPrimary,
              child: Icon(Icons.person, color: Colors.white),
            ),
            title: Text('@${r['username']}'),
            subtitle: Text(r['name'] ?? ''),
            onTap: () {
              if (r['allowMessages'] == false) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'This person is not accepting messages from people who are not friends.',
                    ),
                  ),
                );
              } else {
                _open(r['uid'], '@${r['username']}');
              }
            },
          ),
        const SizedBox(height: 16),
        Text('Friends', style: kTitle.copyWith(fontSize: 18)),
        StreamBuilder<List<Doc>>(
          stream: SocialService.friendships(),
          builder: (_, s) {
            final me = SocialService.uid;
            final fr = (s.data ?? <Doc>[])
                .where((d) => d['status'] == 'accepted')
                .toList();
            if (fr.isEmpty)
              return const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('No friends yet.', style: TextStyle(color: kMuted)),
              );
            return Column(
              children: [
                for (final d in fr)
                  Builder(
                    builder: (_) {
                      final other = (d['members'] as List).firstWhere(
                        (m) => m != me,
                      ) as String;
                      final name = (d['names'] as Map)[other] ?? 'Friend';
                      return ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: kPrimary,
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                        title: Text(name),
                        onTap: () => _open(other, name),
                      );
                    },
                  ),
              ],
            );
          },
        ),
      ],
    ),
  );
}

class ChatScreen extends StatefulWidget {
  final String otherUid, otherLabel, myLabel;
  const ChatScreen({
    super.key,
    required this.otherUid,
    required this.otherLabel,
    required this.myLabel,
  });
  @override
  State<ChatScreen> createState() => _ChatState();
}

class _ChatState extends State<ChatScreen> {
  final ctrl = TextEditingController();
  late final id = ChatService.cid(SocialService.uid, widget.otherUid);
  bool sending = false;
  Object? _marked;

  Future<void> _send() async {
    final t = ctrl.text.trim();
    if (t.isEmpty) return;
    setState(() => sending = true);
    try {
      await ChatService.send(
        otherUid: widget.otherUid,
        myLabel: widget.myLabel,
        otherLabel: widget.otherLabel,
        text: t,
      );
      ctrl.clear();
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not send. This person may not be accepting messages.',
            ),
          ),
        );
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = SocialService.uid;
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: ChatService.conversation(id),
      builder: (_, cs) {
        final c = cs.data?.data();
        final status = c?['status'] as String?;
        final isRecipient = c?['to'] == me;
        final canSend = status == null || status == 'active';
        final at = c?['lastAt'];
        if (c != null && at != null && at != _marked && c['lastFrom'] != me) {
          _marked = at;
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => ChatService.markRead(id),
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: Text(widget.otherLabel),
            actions: [
              if (c != null)
                PopupMenuButton<String>(
                  onSelected: (v) async {
                    if (v == 'block')
                      await ChatService.block(id);
                    else
                      await ChatService.report(id);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          v == 'block'
                              ? 'Blocked. They can no longer message you.'
                              : 'Reported. Thank you.',
                        ),
                      ),
                    );
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'report',
                      child: Text('Report conversation'),
                    ),
                    PopupMenuItem(value: 'block', child: Text('Block')),
                  ],
                ),
            ],
          ),
          body: Column(
            children: [
              Container(
                width: double.infinity,
                color: const Color(0xFFFFF3D6),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: const Text(
                  kReviewNotice,
                  style: TextStyle(fontSize: 12),
                ),
              ),
              if (status == 'request' && isRecipient)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  color: kPrimary.withValues(alpha: .08),
                  child: Column(
                    children: [
                      Text(
                        '${widget.otherLabel} wants to message you. You can read this, but they cannot send more until you accept.',
                        style: const TextStyle(fontSize: 13),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                            onPressed: () => ChatService.block(id),
                            child: const Text('Block'),
                          ),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: kPrimary,
                            ),
                            onPressed: () => ChatService.accept(id),
                            child: const Text('Accept'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: c == null
                    ? const Center(
                        child: Text(
                          'Say hello 👋',
                          style: TextStyle(color: kMuted),
                        ),
                      )
                    : StreamBuilder<List<Doc>>(
                        stream: ChatService.messages(id),
                        builder: (_, ms) => ListView(
                          reverse: true,
                          padding: const EdgeInsets.all(16),
                          children: [
                            for (final m in (ms.data ?? <Doc>[]).reversed)
                              Align(
                                alignment: m['from'] == me
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  constraints: BoxConstraints(
                                    maxWidth:
                                        MediaQuery.of(context).size.width * .75,
                                  ),
                                  decoration: BoxDecoration(
                                    color: m['from'] == me
                                        ? kPrimary
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: Text(
                                    m['text'],
                                    style: TextStyle(
                                      color: m['from'] == me
                                          ? Colors.white
                                          : kText,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
              ),
              if (status == 'blocked')
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'This conversation is blocked.',
                    style: TextStyle(color: kMuted),
                  ),
                )
              else if (status == 'request' && !isRecipient)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Waiting for them to accept your message request.',
                    style: TextStyle(color: kMuted),
                  ),
                )
              else if (canSend)
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: ctrl,
                            maxLength: 500,
                            onSubmitted: (_) => _send(),
                            decoration: fieldDec(
                              'Write a message',
                              Icons.chat_bubble_outline,
                            ).copyWith(counterText: ''),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.send, color: kPrimary),
                          onPressed: sending ? null : _send,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
