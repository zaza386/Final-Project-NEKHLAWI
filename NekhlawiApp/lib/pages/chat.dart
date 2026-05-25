import 'dart:io';
import 'package:flutter/material.dart';
import 'package:nekhlawi_app/core/theme/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:nekhlawi_app/pages/expert_profile.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

class ChatPage extends StatefulWidget {
  final String expertId;
  final String userId;
  final String sessionId;

  const ChatPage({
    super.key,
    required this.expertId,
    required this.userId,
    required this.sessionId,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final supabase     = Supabase.instance.client;
  final _controller  = TextEditingController();
  final _scrollCtrl  = ScrollController();
  final _imagePicker = ImagePicker();
  final _recorder    = AudioRecorder();

  List<Map<String, dynamic>> messages = [];
  String? expertName;
  String? expertRawImage; // قمنا بتغييره للاحتفاظ بالمسار الخام لفحصه ذكياً لاحقاً
  bool   _loadingSession = true;
  bool   _isSending      = false;
  bool   _isRecording    = false;
  RealtimeChannel? _channel;
  String? _currentUserRole;

  String? _playingMessageId;
  final Map<String, AudioPlayer> _audioPlayers = {};

  String get cleanUserId   => widget.userId.trim();
  String get cleanExpertId => widget.expertId.trim();
  String get _sessionId    => widget.sessionId.trim();

  bool get _isExpert =>
      (_currentUserRole ?? '').toLowerCase().trim() == 'expert';

  @override
  void initState() {
    super.initState();
    _loadCurrentUserRole();
    _loadExpert();
    _loadMessages();
    _listenForMessages();
    _listenForSessionEnd();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollCtrl.dispose();
    _recorder.dispose();
    for (final p in _audioPlayers.values) p.dispose();
    if (_channel != null) supabase.removeChannel(_channel!);
    super.dispose();
  }

  // دالة الفحص الذكية والشاملة لجميع أنواع الصور (روابط، أصول محلية، أو سوبابيز)
  ImageProvider _getAvatarImage(String? path) {
    if (path == null || path.isEmpty) {
      return const AssetImage('images/nekhlawi_icon.png');
    }

    // 1. إذا كان رابط كامل يبدأ بـ http أو https
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return NetworkImage(path);
    }

    // 2. إذا كان مسار Asset محلي
    if (path.startsWith('assets/') || path.startsWith('images/')) {
      return AssetImage(path);
    }

    // 3. الاحتياطي: مسار نسبي مخزن في سوبابيز ستورج
    return NetworkImage(supabase.storage.from('pic').getPublicUrl(path));
  }

  Future<void> _loadCurrentUserRole() async {
    try {
      final res = await supabase
          .from('User')
          .select('Role')
          .eq('UserID', cleanUserId)
          .single();
      if (mounted) {
        setState(() => _currentUserRole = (res['Role'] as String?) ?? 'user');
      }
    } catch (e) {
      debugPrint('_loadCurrentUserRole: $e');
      if (mounted) setState(() => _currentUserRole = 'user');
    }
  }

  Future<void> _loadExpert() async {
    try {
      final res = await supabase
          .from('User')
          .select('Name, ProfilePicturePath')
          .eq('UserID', cleanExpertId)
          .single();
      final path = res['ProfilePicturePath'] as String?;
      if (mounted) {
        setState(() {
          expertName     = res['Name'] as String?;
          expertRawImage = path; // نحتفظ بالمسار هنا كما هو لتمريره للدالة الذكية
        });
      }
    } catch (e) {
      debugPrint('_loadExpert: $e');
    }
  }

  Future<void> _loadMessages() async {
    setState(() => _loadingSession = true);
    try {
      final rows = await supabase
          .from('ChatMessage')
          .select('MessageID, ExpertSessionID, SenderID, MessageText, AttachmentURL, SentAt')
          .eq('ExpertSessionID', _sessionId)
          .order('SentAt', ascending: true);

      if (mounted) {
        setState(() {
          messages = (rows as List).map((r) {
            final m = Map<String, dynamic>.from(r);
            m['_plain'] = m['MessageText'] as String? ?? '';
            return m;
          }).toList();
          _loadingSession = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('_loadMessages: $e');
      if (mounted) setState(() => _loadingSession = false);
    }
  }

  void _listenForMessages() {
    _channel = supabase
        .channel('chat:$_sessionId')
        .onPostgresChanges(
      event:  PostgresChangeEvent.insert,
      schema: 'public',
      table:  'ChatMessage',
      filter: PostgresChangeFilter(
        type:   PostgresChangeFilterType.eq,
        column: 'ExpertSessionID',
        value:  _sessionId,
      ),
      callback: (payload) {
        final data = Map<String, dynamic>.from(payload.newRecord);
        final exists = messages.any((m) => m['MessageID'] == data['MessageID']);
        if (exists || !mounted) return;
        data['_plain'] = data['MessageText'] as String? ?? '';
        setState(() => messages.add(data));
        _scrollToBottom();
      },
    )
        .subscribe();
  }

  void _listenForSessionEnd() {
    supabase
        .channel('session_status:$_sessionId')
        .onPostgresChanges(
      event:  PostgresChangeEvent.update,
      schema: 'public',
      table:  'ExpertSession',
      filter: PostgresChangeFilter(
        type:   PostgresChangeFilterType.eq,
        column: 'ExpertSessionID',
        value:  _sessionId,
      ),
      callback: (payload) {
        final status = payload.newRecord['Status'] as String?;
        if (status == 'أكتملت' && mounted) {
          _showSessionEndedDialog();
        }
      },
    )
        .subscribe();
  }

  void _showSessionEndedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('انتهت الجلسة'),
          content: const Text('تم إنهاء الجلسة تلقائياً.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('حسناً'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;
    _controller.clear();
    await _insertMessage(text: text, attachmentUrl: null);
  }

  Future<void> _startRecording() async {
    try {
      final ok = await _recorder.hasPermission();
      if (!ok) { _showError('لا يوجد إذن للميكروفون'); return; }
      final dir  = await getTemporaryDirectory();
      final path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: path);
      setState(() => _isRecording = true);
    } catch (e) {
      debugPrint('_startRecording: $e');
      _showError('فشل في بدء التسجيل');
    }
  }

  Future<void> _stopAndSendRecording() async {
    try {
      final path = await _recorder.stop();
      setState(() => _isRecording = false);
      if (path == null) return;
      final file = File(path);
      if (!await file.exists()) return;
      await _uploadAndSend(file, 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a', bucket: 'chat_audio');
    } catch (e) {
      debugPrint('_stopAndSendRecording: $e');
      _showError('فشل في إرسال الرسالة الصوتية');
      setState(() => _isRecording = false);
    }
  }

  Future<void> _cancelRecording() async {
    try { await _recorder.cancel(); } catch (_) {}
    setState(() => _isRecording = false);
  }

  Future<void> _toggleAudio(String msgId, String url) async {
    if (_playingMessageId == msgId) {
      await _audioPlayers[msgId]?.pause();
      setState(() => _playingMessageId = null);
      return;
    }
    if (_playingMessageId != null) {
      await _audioPlayers[_playingMessageId!]?.stop();
    }
    final player = _audioPlayers.putIfAbsent(msgId, () => AudioPlayer());
    try {
      await player.setUrl(url);
      player.playerStateStream.listen((s) {
        if (s.processingState == ProcessingState.completed && mounted) {
          setState(() => _playingMessageId = null);
        }
      });
      await player.play();
      setState(() => _playingMessageId = msgId);
    } catch (e) {
      debugPrint('_toggleAudio: $e');
      _showError('فشل في تشغيل الصوت');
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _imagePicker.pickImage(source: source, imageQuality: 80);
      if (picked == null) return;
      await _uploadAndSend(File(picked.path), picked.name, bucket: 'chat_attachments');
    } catch (e) {
      debugPrint('_pickImage: $e');
      _showError('فشل في اختيار الصورة');
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx', 'mp4', 'mov'],
      );
      if (result == null || result.files.single.path == null) return;
      final f = result.files.single;
      await _uploadAndSend(File(f.path!), f.name, bucket: 'chat_attachments');
    } catch (e) {
      debugPrint('_pickFile: $e');
      _showError('فشل في اختيار الملف');
    }
  }

  Future<void> _uploadAndSend(File file, String fileName, {required String bucket}) async {
    setState(() => _isSending = true);
    try {
      final ext  = fileName.split('.').last.toLowerCase();
      final path = '$_sessionId/${DateTime.now().millisecondsSinceEpoch}.$ext';

      await supabase.storage.from(bucket).upload(path, file);

      final url = supabase.storage.from(bucket).getPublicUrl(path);

      await _insertMessage(text: fileName, attachmentUrl: url);
    } catch (e) {
      debugPrint('_uploadAndSend: $e');
      _showError('فشل في رفع الملف');
    }finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _insertMessage({required String text, required String? attachmentUrl}) async {
    final now    = DateTime.now().toUtc().toIso8601String();
    final tempId = 'opt_${DateTime.now().millisecondsSinceEpoch}';

    setState(() => messages.add({
      'MessageID':       tempId,
      'ExpertSessionID': _sessionId,
      'SenderID':        cleanUserId,
      'MessageText':     text,
      '_plain':          text,
      'AttachmentURL':   attachmentUrl,
      'SentAt':          now,
      '_isOptimistic':   true,
    }));
    _scrollToBottom();

    try {
      final inserted = await supabase
          .from('ChatMessage')
          .insert({
        'ExpertSessionID': _sessionId,
        'SenderID':        cleanUserId,
        'MessageText':     text,
        'AttachmentURL':   attachmentUrl,
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
      debugPrint('_insertMessage: $e');
      if (mounted) {
        setState(() => messages.removeWhere((m) => m['MessageID'] == tempId));
        _showError('فشل في إرسال الرسالة');
      }
    }
  }

  void _onEndSession() {
    if (_isExpert) {
      if (mounted) Navigator.pop(context);
    } else {
      _showRatingDialog();
    }
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2)),
                ),
                ListTile(
                  leading: const CircleAvatar(
                      backgroundColor: Color(0xFF7A8256),
                      child: Icon(Icons.camera_alt, color: Colors.white)),
                  title: const Text('التقاط صورة'),
                  onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); },
                ),
                ListTile(
                  leading: const CircleAvatar(
                      backgroundColor: Color(0xFF7A8256),
                      child: Icon(Icons.photo_library, color: Colors.white)),
                  title: const Text('اختيار من المعرض'),
                  onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); },
                ),
                ListTile(
                  leading: const CircleAvatar(
                      backgroundColor: Color(0xFF7A8256),
                      child: Icon(Icons.insert_drive_file, color: Colors.white)),
                  title: const Text('إرفاق ملف'),
                  onTap: () { Navigator.pop(context); _pickFile(); },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

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
                builder: (context, setDialogState) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(width: 32),
                        const Text('قيم تجربتك مع الخبير',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF4A3E25))),
                        GestureDetector(
                          onTap: () => Navigator.pop(dialogContext),
                          child: Container(
                            width: 32, height: 32,
                            decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                            child: const Icon(Icons.close, size: 18, color: Colors.black54),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Avatar
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(color: Color(0xFF7A8256), shape: BoxShape.circle),
                      child: CircleAvatar(
                        radius: 44,
                        backgroundColor: Colors.grey.shade100,
                        // استخدام الدالة الذكية هنا لعرض صورة الخبير بشكل سليم في التقييم
                        backgroundImage: _getAvatarImage(expertRawImage),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(expertName != null ? 'م. $expertName' : 'الخبير',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF4A3E25))),
                    const SizedBox(height: 6),
                    const Text('كيف كانت تجربتك مع الخبير ؟',
                        style: TextStyle(fontSize: 13, color: Colors.grey)),
                    const SizedBox(height: 20),
                    // Stars
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (i) {
                        final val = i + 1;
                        return GestureDetector(
                          onTap: () => setDialogState(() => selectedRating = val),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(
                              val <= selectedRating ? Icons.star : Icons.star_border,
                              color: const Color(0xFFF2A649), size: 38,
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 8),
                    // Labels
                    Row(
                      children: List.generate(5, (i) {
                        final isActive = selectedRating == i + 1;
                        return Expanded(
                          child: Text(ratingLabels[i],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                                color: isActive ? const Color(0xFFF2A649) : Colors.grey.shade400,
                              )),
                        );
                      }),
                    ),
                    const SizedBox(height: 20),
                    // Comment
                    TextField(
                      controller: commentController,
                      maxLines: 4, maxLength: 500,
                      textDirection: TextDirection.rtl,
                      onChanged: (_) => setDialogState(() {}),
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'لا تنسى تشاركنا رأيك ، لأن رأيك يهمنا ..',
                        hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                        counterText: '${commentController.text.length}/500',
                        counterStyle: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                        contentPadding: const EdgeInsets.all(14),
                        filled: true, fillColor: Colors.grey.shade50,
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
                    const SizedBox(height: 20),
                    // Submit
                    SizedBox(
                      width: double.infinity, height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7A8256), elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          if (selectedRating == 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('الرجاء اختيار التقييم بالنجوم أولاً')));
                            return;
                          }
                          try {
                            await supabase.from('Review').insert({
                              'Rating':          selectedRating,
                              'Comment':         commentController.text.trim(),
                              'CreatedAt':       DateTime.now().toUtc().toIso8601String(),
                              'ExpertID':        cleanExpertId,
                              'ExpertSessionID': _sessionId,
                            });

                            if (dialogContext.mounted) Navigator.pop(dialogContext);
                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('شكراً لتقييمك! ✨')));
                            }
                          } catch (e) {
                            debugPrint('Review error: $e');
                            if (dialogContext.mounted) {
                              ScaffoldMessenger.of(dialogContext)
                                  .showSnackBar(SnackBar(content: Text('خطأ: $e')));
                            }
                          }
                        },
                        child: const Text('تقييم',
                            style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

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

  String _formatTime(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) { return ''; }
  }

  bool _isImageUrl(String? u) {
    if (u == null) return false;
    final l = u.toLowerCase();
    return l.endsWith('.jpg') || l.endsWith('.jpeg') || l.endsWith('.png') || l.endsWith('.webp');
  }

  bool _isAudioUrl(String? u) {
    if (u == null) return false;
    final l = u.toLowerCase();
    return l.endsWith('.m4a') || l.endsWith('.mp3') || l.endsWith('.aac') || l.endsWith('.wav');
  }

  bool _isVideoUrl(String? u) {
    if (u == null) return false;
    final l = u.toLowerCase();
    return l.endsWith('.mp4') || l.endsWith('.mov') || l.endsWith('.avi');
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F4F4),
        appBar: _buildAppBar(),
        body: _loadingSession
            ? const Center(child: CircularProgressIndicator(color: AppColors.darkBrown))
            : Column(children: [
          Expanded(child: _buildMessageList()),
          if (_isSending)
            LinearProgressIndicator(
              backgroundColor: AppColors.header,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            padding: const EdgeInsets.symmetric(horizontal: 14),
          ),
          child: const Text('الخروج من الجلسة',
              style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13)),
        ),
      ),
    ],
    title: GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => ExpertProfilePage(expertId: cleanExpertId))),
      child: Row(children: [
        const SizedBox(width: 8),
        CircleAvatar(
          radius: 22,
          backgroundColor: AppColors.grey.withOpacity(0.2),
          // استدعاء دالة الفحص الذكية هنا لعرض الصورة في شريط الـ AppBar
          backgroundImage: _getAvatarImage(expertRawImage),
          onBackgroundImageError: (_, __) {},
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(expertName ?? '...',
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 18, color: AppColors.darkGreen, fontWeight: FontWeight.w700)),
        ),
      ]),
    ),
  );

  Widget _buildMessageList() {
    if (messages.isEmpty) {
      return const Center(child: Text('لا توجد رسائل', style: TextStyle(color: AppColors.grey)));
    }
    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: messages.length,
      itemBuilder: (context, i) {
        final msg    = messages[i];
        final isMine = msg['SenderID'].toString().trim().toLowerCase() == cleanUserId.toLowerCase();
        return isMine ? _buildSent(msg) : _buildReceived(msg);
      },
    );
  }

  Widget _buildSent(Map<String, dynamic> msg) {
    final url = msg['AttachmentURL'] as String?;
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(top: 4, bottom: 4, right: 8, left: 60),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: const BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16), topRight: Radius.circular(4),
            bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildContent(msg, url, isMine: true),
            const SizedBox(height: 4),
            Text(_formatTime(msg['SentAt'] as String?),
                style: const TextStyle(fontSize: 10, color: Colors.white70)),
          ],
        ),
      ),
    );
  }

  Widget _buildReceived(Map<String, dynamic> msg) {
    final url = msg['AttachmentURL'] as String?;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(top: 4, bottom: 4, left: 8, right: 60),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4), topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16),
          ),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildContent(msg, url, isMine: false),
            const SizedBox(height: 4),
            Text(_formatTime(msg['SentAt'] as String?),
                style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(Map<String, dynamic> msg, String? url, {required bool isMine}) {
    final color = isMine ? AppColors.white : AppColors.darkGreen;
    final msgId = msg['MessageID'] as String? ?? '';

    if (_isImageUrl(url)) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(url!, width: 200, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.grey)),
      );
    }

    if (_isAudioUrl(url)) {
      final playing = _playingMessageId == msgId;
      return GestureDetector(
        onTap: () => _toggleAudio(msgId, url!),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(playing ? Icons.pause_circle_filled : Icons.play_circle_filled,
                color: isMine ? Colors.white : AppColors.primary, size: 36),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('رسالة صوتية', style: TextStyle(color: color, fontSize: 13)),
                Container(
                  width: 100, height: 3, margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: isMine ? Colors.white38 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (_isVideoUrl(url)) {
      return Container(
        width: 200, height: 110,
        decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(10)),
        child: const Center(child: Icon(Icons.play_circle_fill, color: Colors.white, size: 48)),
      );
    }

    if (url != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.insert_drive_file, color: color, size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Text(url.split('/').last,
                style: TextStyle(color: color, fontSize: 13, decoration: TextDecoration.underline),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      );
    }

    return Text(_plainText(msg),
        textAlign: isMine ? TextAlign.right : TextAlign.left,
        style: TextStyle(color: color, fontSize: 15));
  }

  Widget _buildInputBar() {
    if (_isRecording) {
      return Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: SafeArea(
          child: Row(
            children: [
              GestureDetector(
                onTap: _cancelRecording,
                child: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(children: [
                  const Icon(Icons.circle, color: Colors.redAccent, size: 10),
                  const SizedBox(width: 8),
                  Text('جاري التسجيل...', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                ]),
              ),
              GestureDetector(
                onTap: _stopAndSendRecording,
                child: Container(
                  width: 48, height: 48,
                  decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                  child: const Icon(Icons.send, color: Colors.white, size: 22),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: SafeArea(
        child: Row(
          children: [
            // Attach
            IconButton(
              icon: const Icon(Icons.attach_file, color: AppColors.primary),
              onPressed: _showAttachmentOptions,
            ),
            // Text field
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 120),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _controller,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  keyboardType: TextInputType.multiline,
                  maxLines: null, minLines: 1,
                  style: const TextStyle(fontSize: 15, color: AppColors.darkGreen),
                  decoration: const InputDecoration(
                    hintText: 'اكتب رسالة...',
                    hintTextDirection: TextDirection.rtl,
                    hintStyle: TextStyle(color: Color.fromARGB(255, 95, 95, 90)),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final hasText = _controller.text.trim().isNotEmpty;
                return GestureDetector(
                  onTap: hasText ? _sendMessage : null,
                  onLongPressStart: hasText ? null : (_) => _startRecording(),
                  onLongPressEnd:   hasText ? null : (_) => _stopAndSendRecording(),
                  child: Container(
                    width: 44, height: 44,
                    decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                    child: Icon(hasText ? Icons.send : Icons.mic, color: Colors.white, size: 22),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}