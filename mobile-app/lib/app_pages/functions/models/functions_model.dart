class FunctionRequest {
  String? id;
  String? userId;
  String? functionName;
  String? date;
  String? firstName;
  String? secondName;
  String? place;
  String? nativePlace;
  String? invitationUrl;
  String? imageUrl;

  FunctionRequest({
    this.id,
    this.userId,
    this.functionName,
    this.date,
    this.firstName,
    this.secondName,
    this.place,
    this.nativePlace,
    this.invitationUrl,
  });

  FunctionRequest.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    userId = json['userId'];
    functionName = json['functionName'];
    date = json['date'];
    firstName = json['firstName'];
    secondName = json['secondName'];
    place = json['place'];
    nativePlace = json['nativePlace'];
    invitationUrl = json['invitationUrl'];
    imageUrl = json['imageUrl'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['userId'] = userId;
    data['functionName'] = functionName;
    data['date'] = date;
    data['firstName'] = firstName;
    data['secondName'] = secondName;
    data['place'] = place;
    data['nativePlace'] = nativePlace;
    data['invitationUrl'] = invitationUrl;
    data['imageUrl'] = imageUrl;
    return data;
  }
}
