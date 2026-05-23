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

  // Fetched from DB — determines if review dialog shows
  String? _currentUserRole;

  String cleanUserId = '';
  String cleanExpertId = '';

  // True only if role fetched from DB is 'expert'
  bool get _isExpert =>
      (_currentUserRole ?? '').toLowerCase().trim() == 'expert';

  @override
  void initState() {
    super.initState();
    cleanUserId   = widget.userId.trim();
    cleanExpertId = widget.expertId.trim();
    _loadCurrentUserRole();
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

  // ── Fetch current user role from User table ───────────────
  Future<void> _loadCurrentUserRole() async {
    try {
      // SUPABASE: Fetch Role for the logged-in user
      final res = await supabase
          .from('User')                          // SUPABASE: table name
          .select('Role')                        // SUPABASE: User.Role column
          .eq('UserID', cleanUserId)             // SUPABASE: match logged-in user
          .single();
      if (mounted) {
        setState(() {
          _currentUserRole = (res['Role'] as String?) ?? 'user';
        });
      }
      debugPrint('Current user role: $_currentUserRole');
    } catch (e) {
      debugPrint('_loadCurrentUserRole: $e');
      if (mounted) setState(() => _currentUserRole = 'user');
    }
  }

  // ── Load expert info ──────────────────────────────────────
  Future<void> _loadExpert() async {
    try {
      // SUPABASE: Fetch expert name and profile picture from User table
      final res = await supabase
          .from('User')                          // SUPABASE: table name
          .select('Name, ProfilePicturePath')    // SUPABASE: columns
          .eq('UserID', cleanExpertId)           // SUPABASE: filter by expert ID
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
      // SUPABASE: Find existing session between user and expert
      final rows = await supabase
          .from('ExpertSession')                 // SUPABASE: table name
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
        // SUPABASE: Create new session if none exists
        final inserted = await supabase
            .from('ExpertSession')               // SUPABASE: table name
            .insert({
              'UserID':   cleanUserId,           // SUPABASE: ExpertSession.UserID
              'ExpertID': cleanExpertId,         // SUPABASE: ExpertSession.ExpertID
              'Status':   'active',              // SUPABASE: ExpertSession.Status
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
      // SUPABASE: Fetch all messages for this session ordered by time
      final rows = await supabase
          .from('ChatMessage')                   // SUPABASE: table name
          .select()
          .eq('ExpertSessionID', _expertSessionId!) // SUPABASE: filter by session
          .order('SentAt', ascending: true);

      if (mounted) {
        setState(() {
          messages = (rows as List).map((r) {
            final m = Map<String, dynamic>.from(r);
            if (m['MessageText'] != null) m['_plain'] = m['MessageText'] as String;
            return m;
          }).toList();
        });
        _scrollToBottom();

        // Mark all received messages as seen after loading
        await _markAllSeen();
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
            final exists = messages.any((m) => m['MessageID'] == data['MessageID']);
            if (exists || !mounted) return;

            if (data['MessageText'] != null) {
              data['_plain'] = data['MessageText'] as String;
            }

            setState(() => messages.add(data));
            _scrollToBottom();

            // If message is from the other party mark delivered + seen immediately
            final senderId = data['SenderID']?.toString().trim().toLowerCase() ?? '';
            if (senderId != cleanUserId.toLowerCase()) {
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
              final idx = messages.indexWhere(
                  (m) => m['MessageID'] == updated['MessageID']);
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

  // ── Mark delivered ────────────────────────────────────────
  Future<void> _markDelivered(String messageId) async {
    try {
      // SUPABASE: Update IsDelivered flag on ChatMessage
      await supabase
          .from('ChatMessage')                   // SUPABASE: table name
          .update({'IsDelivered': true})          // SUPABASE: ChatMessage.IsDelivered
          .eq('MessageID', messageId)
          .eq('IsDelivered', false);
    } catch (e) {
      debugPrint('_markDelivered: $e');
    }
  }

  // ── Mark seen ─────────────────────────────────────────────
  Future<void> _markSeen(String messageId) async {
    try {
      // SUPABASE: Update IsSeen flag on ChatMessage
      await supabase
          .from('ChatMessage')                   // SUPABASE: table name
          .update({'IsDelivered': true, 'IsSeen': true}) // SUPABASE: both flags
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
      // SUPABASE: Bulk update all unread messages from the other party
      await supabase
          .from('ChatMessage')                   // SUPABASE: table name
          .update({'IsDelivered': true, 'IsSeen': true})
          .eq('ExpertSessionID', _expertSessionId!)
          .neq('SenderID', cleanUserId)          // SUPABASE: only other party's messages
          .eq('IsSeen', false);

      // Reflect seen status in local state immediately
      if (mounted) {
        setState(() {
          messages = messages.map((m) {
            final senderId = m['SenderID']?.toString().trim() ?? '';
            if (senderId != cleanUserId && m['IsSeen'] == false) {
              return {...m, 'IsDelivered': true, 'IsSeen': true};
            }
            return m;
          }).toList();
        });
      }
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
      // SUPABASE: Insert new message into ChatMessage table
      final inserted = await supabase
          .from('ChatMessage')                   // SUPABASE: table name
          .insert({
            'ExpertSessionID': _expertSessionId, // SUPABASE: ChatMessage.ExpertSessionID
            'SenderID':        cleanUserId,      // SUPABASE: ChatMessage.SenderID
            'MessageText':     text,             // SUPABASE: ChatMessage.MessageText
            'AttachmentURL':   null,
            'IsDelivered':     false,
            'IsSeen':          false,
            'SentAt':          now,
          })
          .select()
          .single();

      if (mounted) {
        setState(() {
          final idx = messages.indexWhere((m) => m['MessageID'] == tempId);
          if (idx != -1) messages[idx] = {...inserted, '_plain': text};
        });
      }
    } catch (e) {
      debugPrint('_sendMessage: $e');
      if (mounted) {
        setState(() => messages.removeWhere((m) => m['MessageID'] == tempId));
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('فشل في إرسال الرسالة')));
      }
    }
  }

  // ── End session handler ───────────────────────────────────
  void _onEndSession() {
    debugPrint('End session tapped — role: $_currentUserRole, isExpert: $_isExpert');
    if (_isExpert) {
      // Expert just ends session without review
      _endSessionOnly();
    } else {
      // Regular user sees review dialog
      _showRatingDialog();
    }
  }

  Future<void> _endSessionOnly() async {
    try {
      if (_expertSessionId != null) {
        // SUPABASE: Update session status to completed
        await supabase
            .from('ExpertSession')               // SUPABASE: table name
            .update({'Status': 'أكتملت'})        // SUPABASE: ExpertSession.Status
            .eq('ExpertSessionID', _expertSessionId!);
      }
    } catch (e) {
      debugPrint('_endSessionOnly: $e');
    }
    if (mounted) Navigator.pop(context);
  }

  // ── Review dialog ─────────────────────────────────────────
  void _showRatingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        int selectedRating = 0;
        final commentController = TextEditingController();
        const ratingLabels = ['سيئة', 'مقبولة', 'متوسطة', 'جيدة', 'ممتازة'];

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: StatefulBuilder(
                builder: (context, setDialogState) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [

                      // ── Top row: title + close ──────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const SizedBox(width: 32),
                          const Text(
                            'قيم تجربتك مع الخبير',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4A3E25),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(dialogContext),
                            child: Container(
                              width: 32, height: 32,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, size: 18, color: Colors.black54),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // ── Expert avatar ───────────────────
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Color(0xFF7A8256),
                          shape: BoxShape.circle,
                        ),
                        child: CircleAvatar(
                          radius: 44,
                          backgroundColor: Colors.grey.shade100,
                          backgroundImage: expertImage != null
                              ? NetworkImage(expertImage!)
                              : const AssetImage('images/nekhlawi_icon.png')
                                  as ImageProvider,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ── Expert name ─────────────────────
                      Text(
                        expertName != null ? 'م. $expertName' : 'الخبير',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4A3E25),
                        ),
                      ),

                      const SizedBox(height: 6),

                      const Text(
                        'كيف كانت تجربتك مع الخبير ؟',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),

                      const SizedBox(height: 20),

                      // ── Stars row ───────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (i) {
                          final val = i + 1;
                          return GestureDetector(
                            onTap: () => setDialogState(() => selectedRating = val),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Icon(
                                val <= selectedRating
                                    ? Icons.star
                                    : Icons.star_border,
                                color: const Color(0xFFF2A649),
                                size: 38,
                              ),
                            ),
                          );
                        }),
                      ),

                      const SizedBox(height: 8),

                      // ── Rating labels ───────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(5, (i) {
                          final isActive = selectedRating == i + 1;
                          return Expanded(
                            child: Text(
                              ratingLabels[i],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isActive
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isActive
                                    ? const Color(0xFFF2A649)
                                    : Colors.grey.shade400,
                              ),
                            ),
                          );
                        }),
                      ),

                      const SizedBox(height: 20),

                      // ── Comment box ─────────────────────
                      TextField(
                        controller: commentController,
                        maxLines: 4,
                        maxLength: 500,
                        textDirection: TextDirection.rtl,
                        onChanged: (_) => setDialogState(() {}),
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'لا تنسى تشاركنا رأيك ، لأن رأيك يهمنا ..',
                          hintStyle: TextStyle(
                              fontSize: 13, color: Colors.grey.shade400),
                          counterText:
                              '${commentController.text.length}/500',
                          counterStyle: TextStyle(
                              fontSize: 11, color: Colors.grey.shade400),
                          contentPadding: const EdgeInsets.all(14),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: Color(0xFF7A8256), width: 1.5),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── Submit button ───────────────────
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7A8256),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () async {
                            if (selectedRating == 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'الرجاء اختيار التقييم بالنجوم أولاً')),
                              );
                              return;
                            }
                            try {
                              // SUPABASE: Insert review into Review table
                              await supabase.from('Review').insert({
                                'Rating':          selectedRating,                         // SUPABASE: Review.Rating
                                'Comment':         commentController.text.trim(),          // SUPABASE: Review.Comment
                                'CreatedAt':       DateTime.now().toUtc().toIso8601String(), // SUPABASE: Review.CreatedAt
                                'ExpertID':        cleanExpertId,                          // SUPABASE: Review.ExpertID
                                'ExpertSessionID': _expertSessionId,                       // SUPABASE: Review.ExpertSessionID
                              });

                              // SUPABASE: Mark session as completed
                              if (_expertSessionId != null) {
                                await supabase
                                    .from('ExpertSession')               // SUPABASE: table name
                                    .update({'Status': 'أكتملت'})        // SUPABASE: ExpertSession.Status
                                    .eq('ExpertSessionID', _expertSessionId!);
                              }

                              if (dialogContext.mounted) {
                                Navigator.pop(dialogContext);
                              }
                              if (mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('شكراً لتقييمك! ✨')),
                                );
                              }
                            } catch (e) {
                              debugPrint('Review insert error: $e');
                              if (dialogContext.mounted) {
                                ScaffoldMessenger.of(dialogContext)
                                    .showSnackBar(
                                  SnackBar(content: Text('خطأ: $e')),
                                );
                              }
                            }
                          },
                          child: const Text(
                            'تقييم',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
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
    final isSeen       = msg['IsSeen']        == true;
    final isDelivered  = msg['IsDelivered']   == true;
    final isOptimistic = msg['_isOptimistic'] == true;
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
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: OutlinedButton(
              onPressed: _onEndSession,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.redAccent, width: 1.2),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
              child: const Text(
                'إنهاء الجلسة',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
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
        final msg    = messages[i];
        final isMine = msg['SenderID']
                .toString()
                .trim()
                .toLowerCase() ==
            cleanUserId.toLowerCase();
        return isMine ? _buildSent(msg) : _buildReceived(msg);
      },
    );
  }

  Widget _buildSent(Map<String, dynamic> msg) => Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(
              top: 4, bottom: 4, right: 8, left: 40),
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
              Text(_plainText(msg),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      color: AppColors.white, fontSize: 15)),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(_formatTime(msg['SentAt'] as String?),
                      style: const TextStyle(
                          fontSize: 10, color: Colors.white70)),
                  const SizedBox(width: 4),
                  _buildTicks(msg),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _buildReceived(Map<String, dynamic> msg) => Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.only(
              top: 4, bottom: 4, left: 8, right: 40),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
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
                      Text(_plainText(msg),
                          textAlign: TextAlign.left,
                          style: const TextStyle(
                              color: AppColors.darkGreen,
                              fontSize: 15)),
                      const SizedBox(height: 4),
                      Text(_formatTime(msg['SentAt'] as String?),
                          style: const TextStyle(
                              fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildInputBar() => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        color: AppColors.white,
        child: Row(
          children: [
            const Icon(Icons.mic, color: AppColors.grey),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 120),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                      color: AppColors.grey.withOpacity(0.2), width: 1),
                ),
                child: TextField(
                  controller: _controller,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  keyboardType: TextInputType.multiline,
                  maxLines: null,
                  minLines: 1,
                  style: const TextStyle(
                      fontSize: 16,
                      height: 1.4,
                      color: AppColors.darkGreen),
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
            const Icon(Icons.emoji_emotions_outlined,
                color: AppColors.grey),
            const SizedBox(width: 10),
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                  color: AppColors.primary, shape: BoxShape.circle),
              child: IconButton(
                onPressed: _sendMessage,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.send,
                    color: AppColors.white, size: 21),
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
