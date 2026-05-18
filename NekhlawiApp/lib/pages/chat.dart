import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:nekhlawi_app/core/theme/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:nekhlawi_app/pages/expert_profile.dart';

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
  final ScrollController _scrollCtrl = ScrollController();

  List<Map<String, dynamic>> messages = [];
  String? expertName;
  String? expertImage;
  String? _expertSessionId;
  bool _loadingSession = true;
  RealtimeChannel? _channel;

  String cleanUserId = '';
  String cleanExpertId = '';

  @override
  void initState() {
    super.initState();
    cleanUserId = widget.userId.trim();
    cleanExpertId = widget.expertId.trim();

    _loadExpert();
    _resolveSession();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollCtrl.dispose();
    if (_channel != null) supabase.removeChannel(_channel!);
    super.dispose();
  }

  // ── Load expert info ──────────────────────────────────────
  Future<void> _loadExpert() async {
    try {
      final res = await supabase
          .from('User')
          .select('Name, ProfilePicturePath')
          .eq('UserID', cleanExpertId)
          .single();

      final imagePath = res['ProfilePicturePath'] as String?;
      if (mounted) {
        setState(() {
          expertName  = res['Name'] as String?;
          expertImage = (imagePath != null && imagePath.isNotEmpty)
              ? imagePath   
              : null;
        });
      }
    } catch (e) {
      debugPrint('_loadExpert: $e');
    }
  }

  // ── Resolve or reuse ExpertSession ────────────────────────
  Future<void> _resolveSession() async {
    try {
      final rows = await supabase
          .from('ExpertSession')
          .select('ExpertSessionID')
          .or(
            'and(UserID.eq.$cleanUserId,ExpertID.eq.$cleanExpertId),'
            'and(UserID.eq.$cleanExpertId,ExpertID.eq.$cleanUserId)',
          )
          .order('StartAt', ascending: false)
          .limit(1);

      String sessionId;
      if (rows.isNotEmpty) {
        sessionId = rows.first['ExpertSessionID'] as String;
      } else {
        final inserted = await supabase
            .from('ExpertSession')
            .insert({
              'UserID':   cleanUserId,
              'ExpertID': cleanExpertId,
              'Status':   'active',
            })
            .select('ExpertSessionID')
            .single();
        sessionId = inserted['ExpertSessionID'] as String;
      }

      if (mounted) {
        setState(() {
          _expertSessionId = sessionId;
          _loadingSession  = false;
        });
        await _loadMessages();
        _listenForMessages();
        await _markAllSeen();
      }
    } catch (e) {
      debugPrint('_resolveSession: $e');
      if (mounted) setState(() => _loadingSession = false);
    }
  }

  // ── Load messages ─────────────────────────────────────────
  Future<void> _loadMessages() async {
    if (_expertSessionId == null) return;
    try {
      final rows = await supabase
          .from('ChatMessage')
          .select()
          .eq('ExpertSessionID', _expertSessionId!)
          .order('SentAt', ascending: true);

      if (mounted) {
        setState(() {
          messages = (rows as List).map((r) {
            final m = Map<String, dynamic>.from(r);
            if (m['MessageText'] != null) {
              m['_plain'] = m['MessageText'] as String;
            }
            return m;
          }).toList();
        });
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('_loadMessages: $e');
    }
  }

  // ── Realtime listener ─────────────────────────────────────
  void _listenForMessages() {
    if (_expertSessionId == null) return;

    _channel = supabase
        .channel('chat:$_expertSessionId')
        .onPostgresChanges(
          event:  PostgresChangeEvent.insert,
          schema: 'public',
          table:  'ChatMessage',
          filter: PostgresChangeFilter(
            type:   PostgresChangeFilterType.eq,
            column: 'ExpertSessionID',
            value:  _expertSessionId!,
          ),
          callback: (payload) async {
            final data = Map<String, dynamic>.from(payload.newRecord);

            final exists =
                messages.any((m) => m['MessageID'] == data['MessageID']);
            if (exists || !mounted) return;

            if (data['MessageText'] != null) {
              data['_plain'] = data['MessageText'] as String;
            }

            setState(() => messages.add(data));
            _scrollToBottom();

            if (data['SenderID'].toString().trim().toLowerCase() != widget.userId.trim().toLowerCase()) {
              await _markDelivered(data['MessageID'] as String);
              await _markSeen(data['MessageID'] as String);
            }
          },
        )
        .onPostgresChanges(
          event:  PostgresChangeEvent.update,
          schema: 'public',
          table:  'ChatMessage',
          filter: PostgresChangeFilter(
            type:   PostgresChangeFilterType.eq,
            column: 'ExpertSessionID',
            value:  _expertSessionId!,
          ),
          callback: (payload) {
            final updated = payload.newRecord;
            if (!mounted) return;
            setState(() {
              final idx = messages
                  .indexWhere((m) => m['MessageID'] == updated['MessageID']);
              if (idx != -1) {
                messages[idx] = {
                  ...messages[idx],
                  'IsDelivered': updated['IsDelivered'],
                  'IsSeen':      updated['IsSeen'],
                };
              }
            });
          },
        )
        .subscribe();
  }

  // ── Mark single message delivered ─────────────────────────
  Future<void> _markDelivered(String messageId) async {
    try {
      await supabase
          .from('ChatMessage')
          .update({'IsDelivered': true})
          .eq('MessageID', messageId)
          .eq('IsDelivered', false);
    } catch (e) {
      debugPrint('_markDelivered: $e');
    }
  }

  // ── Mark single message seen ──────────────────────────────
  Future<void> _markSeen(String messageId) async {
    try {
      await supabase
          .from('ChatMessage')
          .update({'IsSeen': true})
          .eq('MessageID', messageId)
          .eq('IsSeen', false);
    } catch (e) {
      debugPrint('_markSeen: $e');
    }
  }

  // ── Mark ALL unseen messages from other party as seen ─────
  Future<void> _markAllSeen() async {
    if (_expertSessionId == null) return;
    try {
      await supabase
          .from('ChatMessage')
          .update({'IsDelivered': true, 'IsSeen': true})
          .eq('ExpertSessionID', _expertSessionId!)
          .neq('SenderID', cleanUserId)  
          .eq('IsSeen', false);
    } catch (e) {
      debugPrint('_markAllSeen: $e');
    }
  }

  // ── Send message ──────────────────────────────────────────
  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _expertSessionId == null) return;

    _controller.clear();

    final now    = DateTime.now().toUtc().toIso8601String();
    final tempId = 'opt_${DateTime.now().millisecondsSinceEpoch}';

    final optimistic = {
      'MessageID':       tempId,
      'ExpertSessionID': _expertSessionId,
      'SenderID':        cleanUserId,
      'MessageText':     text, 
      '_plain':          text,           
      'AttachmentURL':   null,
      'IsDelivered':     false,
      'IsSeen':          false,
      'SentAt':          now,
      '_isOptimistic':   true,
    };

    setState(() => messages.add(optimistic));
    _scrollToBottom();

    try {
      final inserted = await supabase
          .from('ChatMessage')
          .insert({
            'ExpertSessionID': _expertSessionId,
            'SenderID':        cleanUserId,
            'MessageText':     text, 
            'AttachmentURL':   null,
            'IsDelivered':     false,
            'IsSeen':          false,
            'SentAt':          now,
          })
          .select()
          .single();

      if (mounted) {
        setState(() {
          final idx =
              messages.indexWhere((m) => m['MessageID'] == tempId);
          if (idx != -1) {
            messages[idx] = {...inserted, '_plain': text};
          }
        });
      }
    } catch (e) {
      debugPrint('_sendMessage: $e');
      if (mounted) {
        setState(
            () => messages.removeWhere((m) => m['MessageID'] == tempId));
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('فشل في إرسال الرسالة')));
      }
    }
  }

  // ── Helpers ───────────────────────────────────────────────
  String _plainText(Map<String, dynamic> msg) =>
      msg['_plain'] as String? ?? msg['MessageText'] as String? ?? '';

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent + 200,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildTicks(Map<String, dynamic> msg) {
    final isSeen      = msg['IsSeen']      == true;
    final isDelivered = msg['IsDelivered'] == true;
    final isOptimistic= msg['_isOptimistic'] == true;

    if (isOptimistic) {
      return const Icon(Icons.access_time, size: 12, color: Colors.white54);
    }
    if (isSeen) {
      return const Icon(Icons.done_all, size: 14, color: Colors.lightBlueAccent);
    }
    if (isDelivered) {
      return const Icon(Icons.done_all, size: 14, color: Colors.white70);
    }
    return const Icon(Icons.done, size: 14, color: Colors.white70);
  }

  // ── Build ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: _buildAppBar(),
        body: _loadingSession
            ? const Center(child: CircularProgressIndicator())
            : Column(children: [
                Expanded(child: _buildMessageList()),
                _buildInputBar(),
              ]),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() => AppBar(
        backgroundColor: AppColors.header,
        elevation: 0,
        title: GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) =>
                    ExpertProfilePage(expertId: cleanExpertId)),
          ),
          child: Row(children: [
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.grey.withOpacity(0.2),
              backgroundImage: expertImage != null
                  ? NetworkImage(expertImage!)
                  : const AssetImage('images/nekhlawi_icon.png')
                      as ImageProvider,
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
          ]),
        ),
      );

  Widget _buildMessageList() {
    if (messages.isEmpty) {
      return const Center(
          child: Text('لا توجد رسائل',
              style: TextStyle(color: AppColors.grey)));
    }
    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.all(12),
      itemCount: messages.length,
      itemBuilder: (context, i) {
        final msg = messages[i];
        final isMine = msg['SenderID'].toString().trim().toLowerCase() == widget.userId.trim().toLowerCase();
        return isMine ? _buildSent(msg) : _buildReceived(msg);
      },
    );
  }

  // رسايلك (المرسل) -> أقصى اليمين تماماً
  Widget _buildSent(Map<String, dynamic> msg) => Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(top: 4, bottom: 4, right: 8, left: 40),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75),
          decoration: const BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.only(
              topLeft:     Radius.circular(16),
              topRight:    Radius.circular(4),
              bottomLeft:  Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _plainText(msg),
                textAlign: TextAlign.right,
                style: const TextStyle(color: AppColors.white, fontSize: 15),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    _formatTime(msg['SentAt'] as String?),
                    style: const TextStyle(fontSize: 10, color: Colors.white70),
                  ),
                  const SizedBox(width: 4),
                  _buildTicks(msg),
                ],
              ),
            ],
          ),
        ),
      );

  // رسايل الخبير (المستقبل) -> أقصى اليسار تماماً بدون صور داخل المحادثة
  Widget _buildReceived(Map<String, dynamic> msg) => Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.only(top: 4, bottom: 4, left: 8, right: 40),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft:     Radius.circular(4),
                      topRight:    Radius.circular(16),
                      bottomLeft:  Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                    boxShadow: [
                      BoxShadow(
                          color:      Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset:     const Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _plainText(msg),
                        textAlign: TextAlign.left,
                        style: const TextStyle(color: AppColors.darkGreen, fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTime(msg['SentAt'] as String?),
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );

 Widget _buildInputBar() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        color: AppColors.white, 
        child: Row(
          children: [
            const Icon(Icons.mic, color: AppColors.grey),
            const SizedBox(width: 10),

            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 120),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), 
                decoration: BoxDecoration(
                  color: AppColors.white, 
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.grey.withOpacity(0.2), width: 1), 
                ),
                child: TextField(
                  controller: _controller,
                  textDirection: TextDirection.rtl, 
                  textAlign: TextAlign.right,
                  keyboardType: TextInputType.multiline,
                  maxLines: null,
                  minLines: 1,
                  style: const TextStyle(fontSize: 16, height: 1.4, color: AppColors.darkGreen),
                  decoration: const InputDecoration(
                    hintText: 'اكتب رسالة...',
                    hintTextDirection: TextDirection.rtl,
                    hintStyle: TextStyle(color: AppColors.grey),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero, 
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),

            const Icon(Icons.attach_file, color: AppColors.grey),
            const SizedBox(width: 8),
            const Icon(Icons.camera_alt, color: AppColors.grey),
            const SizedBox(width: 8),
            const Icon(Icons.emoji_emotions_outlined, color: AppColors.grey),
            const SizedBox(width: 10),

            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: _sendMessage,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(
                  Icons.send, 
                  color: AppColors.white, 
                  size: 21,
                ),
              ),
            ),
          ],
        ),
      );

  String _formatTime(String? iso) {
    if (iso == null) return '';
    final dt = DateTime.parse(iso).toLocal();
    return '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}