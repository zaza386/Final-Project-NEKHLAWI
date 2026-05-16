class ExpertSessionItem {
  final String expertSessionID;
  final String userID;
  final String expertID;
  final String status;

  final DateTime startAt;
  final DateTime? endAt;
  final DateTime? bookedAt;

  final String expertName;
  final String userName;
  final String? declineReason;

  ExpertSessionItem({
    required this.expertSessionID,
    required this.userID,
    required this.expertID,
    required this.status,
    required this.startAt,
    this.endAt,
    this.bookedAt,
    required this.expertName,
    required this.userName,
    this.declineReason
  });

  factory ExpertSessionItem.fromMap(
    Map<String, dynamic> map, {
    required String expertName,
    required String userName,
  }) {
    DateTime parseDT(dynamic v) => DateTime.parse(v.toString());

    return ExpertSessionItem(
      expertSessionID: map['ExpertSessionID'].toString(),
      userID: map['UserID'].toString(),
      expertID: map['ExpertID'].toString(),
      status: (map['Status'] ?? '').toString(),
      startAt: parseDT(map['StartAt']),
      endAt: map['EndAt'] == null ? null : parseDT(map['EndAt']),
      bookedAt: map['BookedAt'] == null ? null : parseDT(map['BookedAt']),
      expertName: expertName,
      userName: userName,
    );
  }
}
