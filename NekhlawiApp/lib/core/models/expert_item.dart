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
    final user = map['User'] as Map<String, dynamic>?;

    return ExpertItem(
      expertId: (map['ExpertID'] ?? '').toString(),
      name: (user?['Name'] ?? '').toString(),
      specialization: (map['Specialization'] ?? '').toString(),
      avatarUrl: user?['ProfilePicturePath']?.toString(),
    );
  }
}