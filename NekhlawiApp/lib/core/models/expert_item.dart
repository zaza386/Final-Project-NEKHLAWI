class ExpertItem {
  final String expertId;
  final String name;
  final String specialization;
  final String? avatarUrl;


  ExpertItem({
    required this.expertId,
    required this.name,
    required this.specialization,
    this.avatarUrl,
  });

  factory ExpertItem.fromMap(Map<String, dynamic> map) {
    // 1. الوصول لكائن المستخدم (الجزء المربوط)
    final userPart = map['User'];

    // 2. استخراج الاسم والصورة بحذر
    String extractedName = '';
    String? extractedAvatar;

    if (userPart is Map) {
      extractedName = (userPart['Name'] ?? '').toString();
      extractedAvatar = userPart['ProfilePicturePath']?.toString();
    } else if (userPart is List && userPart.isNotEmpty) {
      // احتياطاً إذا رجعت كقائمة
      extractedName = (userPart[0]['Name'] ?? '').toString();
      extractedAvatar = userPart[0]['ProfilePicturePath']?.toString();
    }

    // 3. بناء الكائن
    return ExpertItem(
      expertId: (map['ExpertID'] ?? '').toString(),
      name: extractedName,
      specialization: (map['Specialization'] ?? '').toString(),
      avatarUrl: extractedAvatar,
    );
  }
}