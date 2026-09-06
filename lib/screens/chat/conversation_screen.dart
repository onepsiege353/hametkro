import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../models/chat.dart';
import '../../services/chat_service.dart';
import '../../services/user_service.dart';
import '../../widgets/currency.dart';

class ConversationScreen extends StatefulWidget {
  final String conversationId;
  final String myUid;
  final String? listingId;
  const ConversationScreen({
    super.key,
    required this.conversationId,
    required this.myUid,
    this.listingId,
  });

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final _chat = ChatService();
  final _users = UserService();
  final _input = TextEditingController();
  final _scroll = ScrollController();
  String? _otherId;
  AppUser? _other;
  String? _otherName;
  String? _otherPhoto;
  bool _offerMode = false;
  double? _offerAmount;

  @override
  void initState() {
    super.initState();
    _chat.streamConversation(widget.conversationId).listen((conv) {
      _otherId = conv.participantIds.firstWhere(
          (p) => p != widget.myUid,
          orElse: () => '');
      if (_otherId != null && _otherId!.isNotEmpty) {
        _users.streamById(_otherId!).listen((u) {
          if (mounted) setState(() => _other = u);
        });
      }
    });
    _chat.markRead(widget.conversationId, widget.myUid);
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send() async {
    final text = _input.text.trim();
    if (text.isEmpty && !_offerMode) return;
    _input.clear();
    if (_offerMode) {
      final amount = _offerAmount ?? 0;
      if (amount <= 0) {
        setState(() => _offerMode = false);
        return;
      }
      await _chat.sendOffer(
          conversationId: widget.conversationId,
          senderId: widget.myUid,
          text: 'Je propose ${formatPrice(amount)} FCFA',
          amount: amount);
      setState(() => _offerMode = false);
    } else {
      await _chat.sendText(
          conversationId: widget.conversationId,
          senderId: widget.myUid,
          text: text);
    }
    _scrollDown();
  }

  void _scrollDown() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            _avatar(),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_other?.fullName ?? _otherName ?? '…',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                  const Text('Répond généralement vite',
                      style:
                          TextStyle(color: Colors.grey, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          _listingHeader(),
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _chat.streamMessages(widget.conversationId),
              builder: (context, snap) {
                final messages = snap.data ?? [];
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (messages.isNotEmpty) _scrollDown();
                });
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (messages.isEmpty) {
                  return _emptyChat();
                }
                return ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (c, i) {
                    final m = messages[i];
                    return _bubble(m);
                  },
                );
              },
            ),
          ),
          _offerBar(),
          _inputBar(),
        ],
      ),
    );
  }

  Widget _avatar() {
    return CircleAvatar(
      radius: 20,
      backgroundColor: const Color(0xFF009A44).withOpacity(0.15),
      backgroundImage: (_other?.photoUrl) != null
          ? CachedNetworkImageProvider(_other!.photoUrl!)
          : null,
      child: (_other?.photoUrl) == null
          ? const Icon(Icons.person, color: Color(0xFF009A44))
          : null,
    );
  }

  Widget _listingHeader() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF009A44).withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.sell, color: Color(0xFF009A44)),
          const SizedBox(width: 8),
          const Expanded(
            child: Text('En discussion à propos d\'une annonce',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _emptyChat() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.waving_hand_outlined,
              size: 60, color: Color(0xFF009A44)),
          const SizedBox(height: 10),
          const Text('Présente-toi et précise le prix souhaité.',
              style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () {
              _input.text = 'Bonjour, cet article est-il disponible ?';
              setState(() {});
            },
            icon: const Icon(Icons.bolt),
            label: const Text('Message rapide'),
          ),
        ],
      ),
    );
  }

  Widget _bubble(ChatMessage m) {
    final mine = m.senderId == widget.myUid;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.72),
        decoration: BoxDecoration(
          color: mine ? const Color(0xFF009A44) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(mine ? 14 : 3),
            bottomRight: Radius.circular(mine ? 3 : 14),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (m.isOffer)
              Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: mine
                      ? Colors.white.withOpacity(0.2)
                      : const Color(0xFFFF7A00).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'OFFRE : ${m.offerAmount != null ? formatPrice(m.offerAmount!) : ''} FCFA',
                  style: TextStyle(
                      color: mine ? Colors.white : const Color(0xFFB4571B),
                      fontWeight: FontWeight.w800,
                      fontSize: 11),
                ),
              ),
            Text(m.text,
                style: TextStyle(
                    color: mine ? Colors.white : Colors.black87,
                    fontSize: 14)),
            const SizedBox(height: 2),
            Text(
                '${m.createdAt.hour.toString().padLeft(2, '0')}:${m.createdAt.minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                    color: mine ? Colors.white70 : Colors.grey,
                    fontSize: 9)),
          ],
        ),
      ),
    );
  }

  Widget _offerBar() {
    if (!_offerMode) return const SizedBox.shrink();
    return Container(
      color: const Color(0xFFFFF3E8),
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          const Expanded(
            child: Text('Négocie un prix :', style: TextStyle(fontSize: 13)),
          ),
          SizedBox(
            width: 120,
            child: TextField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  hintText: 'Montant FCFA',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 10)),
              onChanged: (v) => _offerAmount = double.tryParse(v),
            ),
          ),
          TextButton(onPressed: _send, child: const Text('Envoyer')),
        ],
      ),
    );
  }

  Widget _inputBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Color(0x12000000), blurRadius: 8)],
        ),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Proposer un prix',
              icon: const Icon(Icons.request_quote_outlined),
              onPressed: () => setState(() => _offerMode = !_offerMode),
            ),
            Expanded(
              child: TextField(
                controller: _input,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _send(),
                decoration: InputDecoration(
                  hintText: 'Écris un message…',
                  isDense: true,
                  filled: true,
                  fillColor: const Color(0xFFF2F2F0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            IconButton.filled(
              onPressed: _send,
              style: IconButton.styleFrom(backgroundColor: const Color(0xFF009A44)),
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}
