import 'package:flutter/material.dart';
import 'package:nekhlawi_app/core/theme/app_colors.dart';
import 'package:nekhlawi_app/core/widgets/header_background.dart';
import 'package:nekhlawi_app/core/widgets/expert_card.dart';
import '../core/data/expert_repo.dart';
import '../core/models/expert_item.dart';

class BookingExpertsPage extends StatefulWidget {
  const BookingExpertsPage({super.key});

  @override
  State<BookingExpertsPage> createState() => _BookingExpertsPageState();
}

class _BookingExpertsPageState extends State<BookingExpertsPage> {
  final _repo = ExpertRepo();
  final _searchController = TextEditingController();

  Future<List<ExpertItem>>? _future;

  static const int pricePerHour = 100;
  static const String locationText = 'السعودية';

  @override
  void initState() {
    super.initState();
    _future = _repo.fetchExperts();
  }

  void _runSearch(String value) {
    setState(() {
      _future = _repo.fetchExperts(query: value);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _goToExpertProfile(String expertId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ExpertProfilePage(expertId: expertId)),
    );
  }

  void _goToBooking(String expertId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AppointmentBookingPage(expertId: expertId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Stack(
          children: [
            Container(color: Colors.white),

            const HeaderBackground(title: 'استشر خبير'),

            Positioned(
              top: 140,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    // بحث فقط (السهم تمت إزالته)
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: _runSearch,
                            decoration: InputDecoration(
                              hintText: 'ابحث عن خبير ...',
                              prefixIcon: const Icon(Icons.search),
                              filled: true,
                              fillColor: const Color(0xFFF4F4F4),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    Expanded(
                      child: FutureBuilder<List<ExpertItem>>(
                        future: _future,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          if (snapshot.hasError) {
                            return Center(
                              child: Text(
                                'صار خطأ في تحميل الخبراء:\n${snapshot.error}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.red),
                              ),
                            );
                          }

                          final experts = snapshot.data ?? [];

                          if (experts.isEmpty) {
  final isSearching = _searchController.text.trim().isNotEmpty;
  return Center(
    child: Text(
      isSearching ? 'لا يوجد ما تبحث عنه' : 'ما فيه خبراء حالياً',
      style: const TextStyle(color: Colors.grey),
    ),
  );
}

                          return ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            itemCount: experts.length + 1,
                            itemBuilder: (context, index) {
                              if (index == experts.length) {
                                return const Padding(
                                  padding: EdgeInsets.only(top: 10, bottom: 16),
                                  child: Center(
                                    child: Text('©️ 2025 - 2026',
                                        style: TextStyle(color: Colors.grey)),
                                  ),
                                );
                              }

                              final e = experts[index];

                              return ExpertCard(
  name: e.name,
  specialization: e.specialization,
  pricePerHour: 100,
  onOpenProfile: () => _goToExpertProfile(e.expertId),
);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Placeholder pages
class ExpertProfilePage extends StatelessWidget {
  final String expertId;
  const ExpertProfilePage({super.key, required this.expertId});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('بروفايل الخبير')),
        body: Center(child: Text('Expert ID: $expertId\n(صفحة البروفايل لسه)')),
      ),
    );
  }
}

class AppointmentBookingPage extends StatelessWidget {
  final String expertId;
  const AppointmentBookingPage({super.key, required this.expertId});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('حجز موعد')),
        body: Center(child: Text('Expert ID: $expertId\n(صفحة الحجز لسه)')),
      ),
    );
  }
}