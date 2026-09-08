class UpcomingFunctionRequest {
  String? id;
  String? userId;
  String? title;
  String? description;
  String? functionDate;
  String? location;
  String? invitationUrl;
  String? status;

  UpcomingFunctionRequest({
    this.id,
    this.userId,
    this.title,
    this.description,
    this.functionDate,
    this.location,
    this.invitationUrl,
    this.status,
  });

  UpcomingFunctionRequest.fromJson(Map<String, dynamic> json) {
    id = json['id']?.toString();
    userId = json['userId']?.toString();
    title = json['title'];
    description = json['description'];
    functionDate = json['functionDate'];
    location = json['location'];
    invitationUrl = json['invitationUrl'];
    status = json['status'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (id != null) data['id'] = id;
    if (userId != null) data['userId'] = userId;
    if (title != null) data['title'] = title;
    if (description != null) data['description'] = description;
    if (functionDate != null) data['functionDate'] = functionDate;
    if (location != null) data['location'] = location;
    if (invitationUrl != null) data['invitationUrl'] = invitationUrl;
    if (status != null) data['status'] = status;
    return data;
  }
}

// Response model for displaying upcoming functions
class UpcomingFunction {
  String id;
  String userId;
  String title;
  String? description;
  String functionDate;
  String location;
  String? invitationUrl;
  String status; // ACTIVE, CANCELLED, COMPLETED
  DateTime? createdAt;
  DateTime? updatedAt;

  UpcomingFunction({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.functionDate,
    required this.location,
    this.invitationUrl,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory UpcomingFunction.fromJson(Map<String, dynamic> json) {
    return UpcomingFunction(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      functionDate: json['functionDate']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      invitationUrl: json['invitationUrl']?.toString(),
      status: json['status']?.toString() ?? 'ACTIVE',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'functionDate': functionDate,
      'location': location,
      'invitationUrl': invitationUrl,
      'status': status,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  bool get isActive => status == 'ACTIVE';
  bool get isCancelled => status == 'CANCELLED';
  bool get isCompleted => status == 'COMPLETED';
}
