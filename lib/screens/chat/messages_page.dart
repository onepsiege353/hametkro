import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/chat.dart';
import '../../providers/auth_provider.dart';
import '../../services/chat_service.dart';
import '../../services/user_service.dart';
import 'conversation_screen.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final _chat = ChatService();
  final _users = UserService();

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthProvider>().user;
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      backgroundColor: const Color(0xFFF7F7F5),
      body: me == null
          ? const Center(child: Text('Connecte-toi pour voir tes messages'))
          : StreamBuilder<List<Conversation>>(
              stream: _chat.streamMyConversations(me.uid),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final convs = snap.data ?? [];
                if (convs.isEmpty) {
                  return _empty();
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: convs.length,
                  itemBuilder: (c, i) => _ConversationTile(
                    conversation: convs[i],
                    myUid: me.uid,
                    onTap: () async {
                      await Navigator.push(context,
                          MaterialPageRoute(builder: (_) {
                        return ConversationScreen(
                          conversationId: convs[i].id,
                          myUid: me.uid,
                          listingId: convs[i].listingId,
                        );
                      }));
                    },
                  ),
                );
              },
            ),
    );
  }

  Widget _empty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.forum_outlined, size: 60, color: Colors.grey),
          const SizedBox(height: 10),
          const Text('Aucune conversation',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 6),
          const Text('Contacte un vendeur depuis une annonce.',
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final Conversation conversation;
  final String myUid;
  final VoidCallback onTap;
  const _ConversationTile(
      {required this.conversation, required this.myUid, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final otherId = conversation.participantIds.firstWhere(
        (p) => p != myUid,
        orElse: () => '');
    final unread = int.tryParse(
            (conversation.unreadCount[myUid] ?? '0')) ??
        0;
    return StreamBuilder<UserLite>(
      stream: Stream.fromFuture(_fetch(otherId)),
      builder: (context, snap) {
        final u = snap.data;
        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFEDEDEA)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFF009A44).withOpacity(0.15),
                  backgroundImage: u?.photoUrl != null
                      ? CachedNetworkImageProvider(u!.photoUrl!)
                      : null,
                  child: u?.photoUrl == null
                      ? const Icon(Icons.person, color: Color(0xFF009A44))
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(u?.fullName ?? conversation.listingTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 3),
                      Text(
                        conversation.listingTitle.isNotEmpty
                            ? 'À propos : ${conversation.listingTitle}'
                            : 'Nouvelle conversation',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 12),
                      ),
                      const SizedBox(height: 2),
                      Text(conversation.lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
                if (unread > 0)
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                        color: Color(0xFFE6453C), shape: BoxShape.circle),
                    child: Text('$unread',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 11)),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<UserLite> _fetch(String id) async {
    try {
      final users = UserService();
      final u = await users.getById(id);
      if (u == null) return const UserLite('', 'Vendeur', null);
      return UserLite(id, u.fullName, u.photoUrl);
    } catch (_) {
      return const UserLite('', 'Vendeur', null);
    }
  }
}

class UserLite {
  final String id;
  final String fullName;
  final String? photoUrl;
  const UserLite(this.id, this.fullName, this.photoUrl);
}
