import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/theme/app_colors.dart';
import '../core/widgets/header_background.dart';
import 'booking_page.dart';

class ExpertProfilePage extends StatefulWidget {
  final String expertId;

  const ExpertProfilePage({super.key, required this.expertId});

  @override
  State<ExpertProfilePage> createState() => _ExpertProfilePageState();
}

class _ExpertProfilePageState extends State<ExpertProfilePage> {
  final supabase = Supabase.instance.client;
  late Future<Map<String, dynamic>> _expertFuture;

  @override
  void initState() {
    super.initState();
    _expertFuture = supabase
        .from('ExpertProfile')
        .select('*, User(Name, ProfilePicturePath)')
        .eq('ExpertID', widget.expertId)
        .single();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: FutureBuilder<Map<String, dynamic>>(
          future: _expertFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final data = snapshot.data ?? {};
            final user = data['User'] as Map<String, dynamic>? ?? {};

            String? imageUrl;
            if (user['ProfilePicturePath'] != null && user['ProfilePicturePath'].toString().isNotEmpty) {
              imageUrl = supabase.storage.from('pic').getPublicUrl(user['ProfilePicturePath']);
            }

            return Stack(
              children: [
                Container(color: Colors.white),

                // 1. إعادة الهيدر الأصلي وتفعيل سهم الرجوع
                HeaderBackground(
                  title: '',
                  // تأكدي من تمرير الـ context أو تفعيل خاصية الرجوع إذا كانت متوفرة في الـ Widget
                ),

                // 2. تفعيل ضغط السهم الموجود "أصلاً" في الهيدر
                Positioned(
                  top: 40,
                  right: 10,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 50,
                      height: 50,
                      color: Colors.transparent, // شفاف تماماً، فقط ليعطيكِ مساحة ضغط فوق السهم الأصلي
                    ),
                  ),
                ),

                Positioned(
                  top: 100,
                  left: 0,
                  right: 0,
                  bottom: 90,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 70,
                          backgroundColor: Colors.white,
                          child: CircleAvatar(
                            radius: 65,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
                            child: imageUrl == null ? const Icon(Icons.person, size: 60, color: Colors.grey) : null,
                          ),
                        ),
                        const SizedBox(height: 12),

                        Text(user['Name'] ?? 'اسم الخبير', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        Text(data['Specialization'] ?? 'تخصص الخبير', style: const TextStyle(fontSize: 16, color: Color(0xFF9EAD76))),
                        const SizedBox(height: 24),

                        _buildInfoContainer(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${data['RatingAvg'] ?? 0}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                  const Text('تقييم', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                ],
                              ),
                              Row(children: List.generate(5, (index) => const Icon(Icons.star_border, color: Colors.orange, size: 20))),
                              const Text('0.0 من 5', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        ),

                        _buildInfoContainer(child: _buildRow(Icons.school_outlined, data['Specialization'] ?? 'أمراض النبات')),
                        _buildInfoContainer(child: _buildRow(Icons.work_outline, '${data['ExperienceYears'] ?? 0} سنوات')),
                        _buildInfoContainer(child: _buildRow(Icons.attach_money, '${data['Price'] ?? 300} ر.س')),

                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                          child: Align(alignment: Alignment.centerRight, child: Text('نبذة تعريفية', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                        ),

                        _buildInfoContainer(
                          child: Text(
                            (data['Bio'] == null || data['Bio'].isEmpty) ? 'لا توجد نبذة متاحة حالياً' : data['Bio'],
                            style: const TextStyle(color: Colors.black87),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),

                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
                    ),
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(color: const Color(0xFFF4F4F4), borderRadius: BorderRadius.circular(15)),
                          child: IconButton(icon: const Icon(Icons.chat_bubble_outline, color: Color(0xFF9EAD76)), onPressed: () {}),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BookingPage(expertId: widget.expertId),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF9EAD76),
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 55),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            ),
                            child: const Text('احجز الآن', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // الدوال المساعدة بقيت كما هي لضمان عدم تغير الشكل
  Widget _buildInfoContainer({required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: child,
    );
  }

  Widget _buildRow(IconData icon, String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(text, style: const TextStyle(fontSize: 15, color: Colors.grey)),
        Icon(icon, color: Colors.grey, size: 22),
      ],
    );
  }
}