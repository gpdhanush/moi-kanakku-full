class FeedbackModel {
  final String id;
  final String userId;
  final String type; // COMPLAINT, GENERAL, etc.
  final String message;
  final String adminResponse;
  final String status; // OPEN, CLOSED, etc.
  final DateTime? respondedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  FeedbackModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.message,
    required this.adminResponse,
    required this.status,
    this.respondedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FeedbackModel.fromJson(Map<String, dynamic> json) {
    return FeedbackModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      type: json['type'] ?? 'GENERAL',
      message: json['message'] ?? json['feedbacks'] ?? '',
      adminResponse: json['adminResponse'] ?? json['reply'] ?? '',
      status: json['status'] ?? 'OPEN',
      respondedAt: json['respondedAt'] != null
          ? DateTime.parse(json['respondedAt'].toString())
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'message': message,
      'adminResponse': adminResponse,
      'status': status,
      'respondedAt': respondedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
