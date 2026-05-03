import 'package:flutter/material.dart';
import 'package:nekhlawi_app/core/theme/app_colors.dart';
import '../core/widgets/custom_input.dart';

class ExpertProfilePage extends StatefulWidget {
  final String expertId;
  final String? expertName;
  final String? profilePicture;
  final String? specialty;
  final int yearsOfExperience;
  final String? bio;
  final double rating;
  final int reviewsCount;
  final double consultationPrice;
  final bool isVerified;
  final List<String>? availableTimeSlots;
  final VoidCallback? onBookNow;

  const ExpertProfilePage({
    super.key,
    required this.expertId,
    this.expertName = 'اسم الخبير',
    this.profilePicture,
    this.specialty = 'أمراض النبات',
    this.yearsOfExperience = 0,
    this.bio = '',
    this.rating = 0.0,
    this.reviewsCount = 0,
    this.consultationPrice = 0.0,
    this.isVerified = false,
    this.availableTimeSlots,
    this.onBookNow,
  });

  @override
  State<ExpertProfilePage> createState() => _ExpertProfilePageState();
}

class _ExpertProfilePageState extends State<ExpertProfilePage> {
  late final specialtyCtrl = TextEditingController(text: widget.specialty ?? '');
  late final yearsCtrl =
      TextEditingController(text: '${widget.yearsOfExperience} سنوات');
  late final bioCtrl = TextEditingController(text: widget.bio ?? '');
  late final priceCtrl =
      TextEditingController(text: '${widget.consultationPrice} ر.س');
  late final ratingCtrl = TextEditingController(text: '${widget.rating}');
  late final reviewsCtrl =
      TextEditingController(text: '${widget.reviewsCount} تقييم');

  @override
  void dispose() {
    specialtyCtrl.dispose();
    yearsCtrl.dispose();
    bioCtrl.dispose();
    priceCtrl.dispose();
    ratingCtrl.dispose();
    reviewsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F7FB),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              children: [
                // ── Header with profile picture ────────────
                _ExpertHeader(
                  profilePicture: widget.profilePicture,
                  name: widget.expertName ?? '',
                  specialty: widget.specialty ?? '',
                  isVerified: widget.isVerified,
                  onBack: () => Navigator.pop(context),
                  avatarRadius: 58,
                  headerHeight: MediaQuery.of(context).size.height * 0.25,
                ),
                const SizedBox(height: 16),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Rating & Reviews ───────────────────
                      _RatingReviewsBar(
                        rating: widget.rating,
                        reviewsCount: widget.reviewsCount,
                      ),
                      const SizedBox(height: 20),

                      // ── Specialty ──────────────────────────
                      CustomInput(
                        hint: 'التخصص',
                        icon: Icons.school_outlined,
                        controller: specialtyCtrl,
                        enabled: false,
                      ),
                      const SizedBox(height: 12),

                      // ── Years of Experience ────────────────
                      CustomInput(
                        hint: 'سنوات الخبرة',
                        icon: Icons.work_history_outlined,
                        controller: yearsCtrl,
                        enabled: false,
                      ),
                      const SizedBox(height: 12),

                      // ── Consultation Price ─────────────────
                      CustomInput(
                        hint: 'سعر الاستشارة',
                        icon: Icons.attach_money_outlined,
                        controller: priceCtrl,
                        enabled: false,
                      ),
                      const SizedBox(height: 20),

                      // ── Bio Section ────────────────────────
                      const _SectionTitle(title: 'نبذة تعريفية'),
                      const SizedBox(height: 10),
                      _BioCard(bio: widget.bio ?? ''),
                      const SizedBox(height: 20),

                      // ── Available Time Slots ───────────────
                      if (widget.availableTimeSlots != null &&
                          widget.availableTimeSlots!.isNotEmpty) ...[
                        const _SectionTitle(title: 'أوقات الاستشارة المتاحة'),
                        const SizedBox(height: 10),
                        _TimeSlotsList(
                            timeSlots: widget.availableTimeSlots ?? []),
                        const SizedBox(height: 20),
                      ],

                      // ── Book Now Button ────────────────────
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: widget.onBookNow ?? () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('حجز الاستشارة قريبًا'),
                                backgroundColor: AppColors.primary,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(Icons.calendar_today),
                          label: const Text(
                            'احجز الآن',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ── Back Button ────────────────────────
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF6B7280),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: const BorderSide(
                                color: Color(0xFFE9ECF3),
                              ),
                            ),
                          ),
                          child: const Text(
                            'العودة',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════
// Expert Header
// ══════════════════════════════════════════════

class _ExpertHeader extends StatelessWidget {
  final String? profilePicture;
  final String name;
  final String specialty;
  final bool isVerified;
  final VoidCallback onBack;
  final double avatarRadius;
  final double headerHeight;

  const _ExpertHeader({
    required this.profilePicture,
    required this.name,
    required this.specialty,
    required this.isVerified,
    required this.onBack,
    required this.avatarRadius,
    required this.headerHeight,
  });

  @override
  Widget build(BuildContext context) {
    final avatarDiameter = avatarRadius * 2;

    return SizedBox(
      height: headerHeight + avatarRadius + 100,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // ── Header Background ──────────────
          ClipPath(
            clipper: _CurvedHeaderClipper(),
            child: SizedBox(
              height: headerHeight,
              width: double.infinity,
              child: Container(
                color: AppColors.header,
                child: const Center(
                  child: Icon(
                    Icons.agriculture,
                    color: Colors.white,
                    size: 64,
                  ),
                ),
              ),
            ),
          ),

          // ── Back Button ────────────────────
          Positioned(
            top: 6,
            right: 12,
            child: _CircleIconButton(icon: Icons.arrow_back, onTap: onBack),
          ),

          // ── Avatar ─────────────────────────
          Positioned(
            top: headerHeight - avatarRadius,
            child: Stack(
              children: [
                Container(
                  width: avatarDiameter,
                  height: avatarDiameter,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                        color: Colors.black.withOpacity(0.12),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(4),
                  child: CircleAvatar(
                    backgroundColor: const Color(0xFFEFF2F8),
                    backgroundImage: profilePicture == null
                        ? null
                        : NetworkImage(profilePicture!),
                    child: profilePicture == null
                        ? const Icon(
                            Icons.person,
                            size: 48,
                            color: Color(0xFF8B95A5),
                          )
                        : null,
                  ),
                ),
                // ── Verified Badge ────────────────
                if (isVerified)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Name & Specialty ───────────────
          Positioned(
            top: headerHeight + avatarRadius + 10,
            child: Column(
              children: [
                Text(
                  name.isEmpty ? '—' : name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  specialty.isEmpty ? '—' : specialty,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════
// Rating & Reviews Bar
// ══════════════════════════════════════════════

class _RatingReviewsBar extends StatelessWidget {
  final double rating;
  final int reviewsCount;

  const _RatingReviewsBar({
    required this.rating,
    required this.reviewsCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9ECF3)),
      ),
      child: Row(
        children: [
          // ── Stars ──────────────────────────
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  for (int i = 0; i < 5; i++)
                    Icon(
                      i < rating.toInt()
                          ? Icons.star_rounded
                          : (i < rating
                              ? Icons.star_half_rounded
                              : Icons.star_outline_rounded),
                      color: const Color(0xFFFDB022),
                      size: 18,
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '$rating من 5',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const Spacer(),
          // ── Reviews Count ──────────────────
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$reviewsCount',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'تقييم',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════
// Bio Card
// ══════════════════════════════════════════════

class _BioCard extends StatelessWidget {
  final String bio;

  const _BioCard({required this.bio});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9ECF3)),
      ),
      child: Text(
        bio.isEmpty
            ? 'لا توجد نبذة متاحة حاليًا'
            : bio,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF4B5563),
          fontWeight: FontWeight.w500,
          height: 1.6,
        ),
        textAlign: TextAlign.right,
      ),
    );
  }
}

// ══════════════════════════════════════════════
// Time Slots List
// ══════════════════════════════════════════════

class _TimeSlotsList extends StatelessWidget {
  final List<String> timeSlots;

  const _TimeSlotsList({required this.timeSlots});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        for (final slot in timeSlots)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.3),
              ),
            ),
            child: Text(
              slot,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
      ],
    );
  }
}

// ══════════════════════════════════════════════
// Section Title
// ══════════════════════════════════════════════

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w900,
          color: Color(0xFF111827),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════
// Circle Icon Button
// ══════════════════════════════════════════════

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: const Color(0xFF1F2937)),
      ),
    );
  }
}

// ══════════════════════════════════════════════
// Curved Header Clipper
// ══════════════════════════════════════════════

class _CurvedHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 50);
    path.quadraticBezierTo(
        size.width * 0.5, size.height, size.width, size.height - 50);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
