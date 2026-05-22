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

  // ── Show Professional Review Dialog ────────────────────────
  void _showRatingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        int selectedRating = 0;
        final commentController = TextEditingController();
        final List<String> ratingLabels = ['سيئة', 'مقبولة', 'متوسطة', 'جيدة', 'ممتازة'];

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Elegant Top Close Action Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'تقييم الجلسة والاستشارة',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, size: 18, color: Colors.black54),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24, thickness: 0.8),
                  
                  const Text(
                    'قيم تجربتك مع الخبير',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A3E25),
                    ),
                  ),
                  const SizedBox(height: 18),
                  
                  // Professional Wrapped Avatar Design
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Color(0xFF7A8256),
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      radius: 44,
                      backgroundColor: Colors.grey[100],
                      backgroundImage: expertImage != null
                          ? NetworkImage(expertImage!)
                          : const AssetImage('images/nekhlawi_icon.png') as ImageProvider,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  Text(
                    expertName != null ? 'م. $expertName' : 'م. خالد العتيبي',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A3E25),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'كيف كانت تجربتك مع الخبير خلال المحادثة؟',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  
                  // Stars + Label List Row Setup
                  StatefulBuilder(
                    builder: (context, setDialogState) {
                      return Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(5, (index) {
                              final starValue = index + 1;
                              return IconButton(
                                icon: Icon(
                                  starValue <= selectedRating ? Icons.star : Icons.star_border,
                                  color: const Color(0xFFF2A649),
                                  size: 36,
                                ),
                                onPressed: () {
                                  setDialogState(() => selectedRating = starValue);
                                },
                              );
                            }),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(5, (index) {
                              final isSelected = selectedRating == (index + 1);
                              return Expanded(
                                child: Text(
                                  ratingLabels[index],
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? const Color(0xFFF2A649) : Colors.grey[500],
                                  ),
                                ),
                              );
                            }),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Comment Input Box Field
                  TextField(
                    controller: commentController,
                    maxLines: 3,
                    maxLength: 500,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'لا تنسى تشاركنا رأيك ، لأن رأيك يهمنا ..',
                      hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                      counterText: '',
                      contentPadding: const EdgeInsets.all(14),
                      filled: true,
                      fillColor: Colors.grey[50],
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF7A8256), width: 1.5),
                      ),
                    ),
                  ),
                  
                  // Character Counter Row
                  StatefulBuilder(
                    builder: (context, setCounterState) {
                      commentController.addListener(() => setCounterState(() {}));
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4, left: 4),
                          child: Text(
                            '${commentController.text.length}/500',
                            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  // Professional Action Buttons
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7A8256),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () async {
                        if (selectedRating == 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('الرجاء اختيار التقييم بالنجوم أولاً')),
                          );
                          return;
                        }
                        
                        try {
                          // Insert directly to table structure matches completely
                          await supabase.from('Review').insert({
                            'Rating': selectedRating,
                            'Comment': commentController.text.trim(),
                            'CreatedAt': DateTime.now().toUtc().toIso8601String(),
                            'ExpertID': cleanExpertId,
                            'ExpertSessionID': _expertSessionId,
                          });

                          if (_expertSessionId != null) {
                            await supabase
                                .from('ExpertSession')
                                .update({'Status': 'completed'})
                                .eq('ExpertSessionID', _expertSessionId!);
                          }

                          if (context.mounted) {
                            Navigator.pop(context); // Close rating dialog card
                            Navigator.pop(context); // Gracefully leave ChatPage view
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('شكراً لتقييمك!')),
                            );
                          }
                        } catch (e) {
                          debugPrint('Error inserting review record: $e');
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('خطأ في الاتصال بقاعدة البيانات: $e')),
                            );
                          }
                        }
                      },
                      child: const Text(
                        'إرسال التقييم',
                        style: TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
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
        actions: [
          // Professional Session Ending Text Action Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: OutlinedButton(
              onPressed: _showRatingDialog,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.redAccent, width: 1.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
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
        final msg = messages[i];
        final isMine = msg['SenderID'].toString().trim().toLowerCase() == widget.userId.trim().toLowerCase();
        return isMine ? _buildSent(msg) : _buildReceived(msg);
      },
    );
  }

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