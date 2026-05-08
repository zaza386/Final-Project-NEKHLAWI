import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nekhlawi_app/pages/to_do_page.dart';
import 'package:nekhlawi_app/pages/chat.dart';
import '../data/expert_session_repo.dart';
import '../models/expert_session_item.dart';
import "package:nekhlawi_app/pages/accept_decline_session.dart";

class UserSessionsCarousel extends StatefulWidget {
  const UserSessionsCarousel({
    super.key,
    required this.userId,
    required this.userRole,
    this.statuses = const [
      'pending',
      'accepted',
      'rejected',
      'started',
    ],
    this.iconAssetPath = 'assets/images/home_brown_icon.png',
    this.isExpert = false,
  });

  final String userId;
  final String userRole;
  final List<String> statuses;
  final String iconAssetPath;
  final bool isExpert;

  @override
  State<UserSessionsCarousel> createState() =>
      _UserSessionsCarouselState();
}

class _UserSessionsCarouselState
    extends State<UserSessionsCarousel> {

  final _repo = ExpertSessionRepo();

  PageController? _pageController;
  Timer? _timer;

  Future<List<ExpertSessionItem>>? _future;

  int _currentIndex = 0;
  int _itemsLength = 0;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  void _loadSessions() {

    setState(() {

      _future = _repo.fetchUserSessions(
        userId: widget.userId,
        statuses: widget.statuses,
        isExpert: widget.isExpert,
      );

    });
  }

  void _startAutoScroll() {

    if (_timer?.isActive ?? false) return;

    if (_itemsLength <= 1 || _pageController == null) return;

    _timer = Timer.periodic(
      const Duration(seconds: 3),
          (_) {

        if (!mounted) return;

        final next =
            (_currentIndex + 1) % _itemsLength;

        _pageController!.animateToPage(
          next,
          duration:
          const Duration(milliseconds: 600),
          curve: Curves.easeOut,
        );
      },
    );
  }

  @override
  void dispose() {

    _timer?.cancel();
    _pageController?.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return FutureBuilder<List<ExpertSessionItem>>(
      future: _future,
      builder: (context, snap) {

        if (snap.connectionState ==
            ConnectionState.waiting) {

          return const SizedBox(
            height: 190,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snap.hasError) {

          return SizedBox(
            height: 190,
            child: Center(
              child: Text('صار خطأ: ${snap.error}'),
            ),
          );
        }

        final sessions = snap.data ?? [];

        _itemsLength = sessions.length;

        if (sessions.isEmpty) {

          _timer?.cancel();

          return const SizedBox(
            height: 190,
            child: Center(
              child: Text('لا توجد جلسات حالياً'),
            ),
          );
        }

        _pageController ??=
            PageController(viewportFraction: 0.75);

        WidgetsBinding.instance.addPostFrameCallback(
              (_) => _startAutoScroll(),
        );

        return Column(
          children: [

            SizedBox(
              height: 165,

              child: PageView.builder(
                controller: _pageController,
                itemCount: sessions.length,

                onPageChanged: (i) {
                  setState(() {
                    _currentIndex = i;
                  });
                },

                itemBuilder: (context, index) {

                  return Center(
                    child: SizedBox(
                      width: 220,
                      height: 165,

                      child: _SessionHomeCard(
                        session: sessions[index],
                        iconAssetPath:
                        widget.iconAssetPath,
                        userRole: widget.userRole,
                        onRefresh: _loadSessions,
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 15),

            _DotsIndicator(
              count: sessions.length,
              activeIndex: _currentIndex,
            ),
          ],
        );
      },
    );
  }
}

class _SessionHomeCard extends StatelessWidget {

  const _SessionHomeCard({
    required this.session,
    required this.iconAssetPath,
    required this.userRole,
    required this.onRefresh,
  });

  final ExpertSessionItem session;
  final String iconAssetPath;
  final String userRole;
  final VoidCallback onRefresh;

  String _formatDate(DateTime dt) =>
      DateFormat('EEEE، d MMM yyyy').format(dt);

  String _formatTime(DateTime dt) =>
      DateFormat('hh:mm a').format(dt);

  @override
  Widget build(BuildContext context) {

    final bool isExpert =
        userRole.toLowerCase() == 'expert' ||
            userRole == 'خبير';

    final String displayName =
    isExpert
        ? (session.userName ?? 'المزارع')
        : session.expertName;

    return InkWell(

      borderRadius: BorderRadius.circular(18),

      onTap: () {

        if (session.status == 'started') {

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatPage(
                expertId: session.expertID,
                userId: session.userID,
              ),
            ),
          );
        }
      },

      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),

        child: Container(

          decoration: BoxDecoration(
            color: const Color(0xFF4C3D19),

            image: DecorationImage(
              image: AssetImage(iconAssetPath),
              fit: BoxFit.cover,
            ),
          ),

          child: Stack(
            children: [

              Positioned(
                top: 14,
                right: 14,

                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.end,

                  children: [

                    Text(
                      'استشارة مع $displayName',

                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      '${_formatDate(session.startAt)}\n${_formatTime(session.startAt)}',

                      textAlign: TextAlign.right,

                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              Positioned(
                bottom: 12,
                left: 12,

                child: Row(
                  children: [

                    _buildCircularActionButton(

                      icon: Icons.event_note_rounded,

                      onTap: () async {

                        final result =
                        await Navigator.push(

                          context,

                          MaterialPageRoute(
                            builder: (_) =>
                                AcceptDeclineSessionPage(
                                  title: isExpert
                                      ? 'إدارة الاستشارة'
                                      : 'حالة الاستشارة',

                                  sessionId:
                                  session.expertSessionID,

                                  userRole: userRole,
                                ),
                          ),
                        );

                        if (result == true) {
                          onRefresh();
                        }
                      },
                    ),

                    const SizedBox(width: 8),

                    _buildCircularActionButton(
                      icon: Icons.info_outline_rounded,

                      onTap: () {

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                            const TodoPage(
                              title: 'معلومات السشن',
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              Positioned(
                bottom: 12,
                right: 12,

                child: _StatusPill(
                  status: session.status,
                  isExpert: isExpert,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCircularActionButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {

    return GestureDetector(

      onTap: onTap,

      child: Container(

        padding: const EdgeInsets.all(6),

        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.8),
          shape: BoxShape.circle,
        ),

        child: Icon(
          icon,
          size: 18,
          color: const Color(0xFF4C3D19),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {

  const _StatusPill({
    required this.status,
    required this.isExpert,
  });

  final String status;
  final bool isExpert;

  @override
  Widget build(BuildContext context) {

    String displayStatus = '';
    Color pillColor = Colors.grey.shade200;

    switch (status) {

      case 'pending':
        displayStatus =
        isExpert
            ? 'طلب جديد'
            : 'قيد المراجعة';

        pillColor = Colors.orange.shade100;
        break;

      case 'accepted':
        displayStatus = 'تم القبول';
        pillColor = Colors.green.shade100;
        break;

      case 'rejected':
        displayStatus = 'تم الرفض';
        pillColor = Colors.red.shade100;
        break;

      case 'started':
        displayStatus = 'بدأت الجلسة';
        pillColor = Colors.blue.shade100;
        break;

      case 'completed':
        displayStatus = 'مكتملة';
        pillColor = Colors.grey.shade300;
        break;

      default:
        displayStatus = status;
    }

    return Container(

      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),

      decoration: BoxDecoration(
        color: pillColor,
        borderRadius: BorderRadius.circular(999),
      ),

      child: Text(

        displayStatus,

        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: Color(0xFF4C3D19),
        ),
      ),
    );
  }
}

class _DotsIndicator extends StatelessWidget {

  const _DotsIndicator({
    required this.count,
    required this.activeIndex,
  });

  final int count;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {

    return Row(

      mainAxisAlignment: MainAxisAlignment.center,

      children: List.generate(

        count,

            (i) => AnimatedContainer(

          duration:
          const Duration(milliseconds: 700),

          margin:
          const EdgeInsets.symmetric(horizontal: 4),

          width: i == activeIndex ? 10 : 6,
          height: i == activeIndex ? 10 : 6,

          decoration: BoxDecoration(
            color:
            i == activeIndex
                ? const Color(0xFF4C3D19)
                : Colors.grey.shade400,

            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}