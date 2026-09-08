class PersonResponseModel {
  String? id;
  String? firstName;
  String? secondName;
  String? business;
  String? city;
  String? mobile;

  PersonResponseModel({
    this.id,
    this.firstName,
    this.secondName,
    this.business,
    this.city,
    this.mobile,
  });

  PersonResponseModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    firstName = json['firstName'];
    secondName = json['secondName'];
    business = json['business'];
    city = json['city'];
    mobile = json['mobile'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['firstName'] = firstName;
    data['secondName'] = secondName;
    data['business'] = business;
    data['city'] = city;
    data['mobile'] = mobile;
    return data;
  }
}
