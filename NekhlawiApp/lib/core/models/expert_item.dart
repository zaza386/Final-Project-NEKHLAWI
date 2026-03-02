class ExpertItem {
  final String expertId;
  final String name;
  final String specialization;

  ExpertItem({
    required this.expertId,
    required this.name,
    required this.specialization,
  });

  factory ExpertItem.fromMap(Map<String, dynamic> map) {
    final user = map['User'] as Map<String, dynamic>?;

    return ExpertItem(
      expertId: (map['ExpertID'] ?? '').toString(),
      name: (user?['Name'] ?? '').toString(),
      specialization: (map['Specialization'] ?? '').toString(),
    );
  }
}