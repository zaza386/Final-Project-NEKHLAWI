import 'package:flutter/material.dart';
import 'package:nekhlawi_app/core/theme/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:nekhlawi_app/pages/expert_profile.dart';
import 'package:uuid/uuid.dart';

class ChatPage extends StatefulWidget {
  final String expertId;
  final String userId;

  const ChatPage({
    super.key,
    required this.expertId,
    required this.userId,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final supabase = Supabase.instance.client;

  final TextEditingController _controller = TextEditingController();

  final _uuid = const Uuid();

  List<Map<String, dynamic>> messages = [];

  String? expertName;
  String? expertImage;

  RealtimeChannel? _channel;

  String get roomId {
    final ids = [widget.userId, widget.expertId]..sort();
    return ids.join("_");
  }

  @override
  void initState() {
    super.initState();

    _loadExpert();
    _loadMessages();
    _listenForMessages();
  }

  @override
  void dispose() {
    _controller.dispose();

    if (_channel != null) {
      supabase.removeChannel(_channel!);
    }

    super.dispose();
  }

  Future<void> _loadExpert() async {
    try {
      final res = await supabase
          .from('User')
          .select('Name, ProfilePicturePath')
          .eq('UserID', widget.expertId)
          .single();

      final imagePath = res['ProfilePicturePath'];

      final imageUrl = imagePath != null
          ? supabase.storage.from('pic').getPublicUrl(imagePath)
          : null;

      setState(() {
        expertName = res['Name'];
        expertImage = imageUrl;
      });
    } catch (e) {
      debugPrint("LOAD EXPERT ERROR:");
      debugPrint(e.toString());
    }
  }

  Future<void> _loadMessages() async {
    try {
      final response = await supabase
          .from('messages')
          .select()
          .eq('room_id', roomId)
          .order('created_at');

      setState(() {
        messages = List<Map<String, dynamic>>.from(response);
      });

      debugPrint("MESSAGES LOADED: ${messages.length}");
    } catch (e) {
      debugPrint("LOAD MESSAGES ERROR:");
      debugPrint(e.toString());
    }
  }

  void _listenForMessages() {
    _channel = supabase
        .channel('chat-$roomId')
        .onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'messages',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'room_id',
        value: roomId,
      ),
      callback: (payload) {
        debugPrint("REALTIME MESSAGE RECEIVED");

        final data = payload.newRecord;

        final alreadyExists = messages.any(
              (m) => m['id'] == data['id'],
        );

        if (alreadyExists) return;

        setState(() {
          messages.add(data);
        });
      },
    )
        .subscribe();

    debugPrint("REALTIME SUBSCRIBED");
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();

    debugPrint("SEND BUTTON CLICKED");

    if (text.isEmpty) {
      debugPrint("TEXT EMPTY");
      return;
    }

    try {
      final payload = {
        'id': _uuid.v4(),
        'room_id': roomId,
        'sender_id': widget.userId,
        'receiver_id': widget.expertId,
        'text': text,
        'created_at': DateTime.now().toIso8601String(),
      };

      debugPrint("INSERTING:");
      debugPrint(payload.toString());

      await supabase.from('messages').insert(payload);

      debugPrint("INSERT SUCCESS");

      _controller.clear();

      await _loadMessages();
    } catch (e) {
      debugPrint("INSERT ERROR:");
      debugPrint(e.toString());
    }
  }

  void _openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExpertProfilePage(
          expertId: widget.expertId,
        ),
      ),
    );
  }

  bool _isMine(Map<String, dynamic> msg) {
    return msg['sender_id'] == widget.userId;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,

        appBar: AppBar(
          backgroundColor: AppColors.header,
          elevation: 0,
          title: GestureDetector(
            onTap: _openProfile,
            child: Row(
              children: [
                const SizedBox(width: 8),

                CircleAvatar(
                  radius: 22,
                  backgroundImage: expertImage != null
                      ? NetworkImage(expertImage!)
                      : null,
                  child: expertImage == null
                      ? const Icon(Icons.person)
                      : null,
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Text(
                    expertName ?? '...',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 18,
                      color: AppColors.darkGreen,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        body: Column(
          children: [
            Expanded(
              child: messages.isEmpty
                  ? const Center(
                child: Text("لا توجد رسائل"),
              )
                  : ListView.builder(
                reverse: true,
                padding: const EdgeInsets.all(12),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];

                  if (_isMine(msg)) {
                    return _buildSent(msg['text'] ?? '');
                  }

                  return _buildReceived(msg['text'] ?? '');
                },
              ),
            ),

            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildSent(String text) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: AppColors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildReceived(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundImage: expertImage != null
                ? NetworkImage(expertImage!)
                : null,
          ),

          const SizedBox(width: 8),

          Flexible(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                text,
                style: const TextStyle(
                  color: AppColors.darkGreen,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 8,
      ),
      color: AppColors.white,
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: "اكتب رسالة...",
                  border: InputBorder.none,
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          Container(
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: _sendMessage,
              icon: const Icon(
                Icons.send,
                color: AppColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}