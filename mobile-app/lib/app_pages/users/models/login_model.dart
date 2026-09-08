class SignUpRequestModel {
  String? name;
  String? email;
  String? mobile;
  String? city;
  String? password;
  String? fcm_token;

  String? device_id;
  String? device_name;
  String? brand;
  String? model;
  String? manufacturer;
  String? android_version;
  String? ram_size;

  SignUpRequestModel({
    this.name,
    this.email,
    this.mobile,
    this.city,
    this.password,
    this.fcm_token,

    this.device_id,
    this.device_name,
    this.brand,
    this.model,
    this.manufacturer,
    this.android_version,
    this.ram_size,
  });

  SignUpRequestModel.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    email = json['email'];
    mobile = json['mobile'];
    city = json['city'];
    password = json['password'];
    fcm_token = json['fcm_token'];

    device_id = json['device_id'];
    device_name = json['device_name'];
    brand = json['brand'];
    model = json['model'];
    manufacturer = json['manufacturer'];
    android_version = json['android_version'];
    ram_size = json['ram_size'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['email'] = email;
    data['mobile'] = mobile;
    data['city'] = city;
    data['password'] = password;
    data['fcm_token'] = fcm_token;

    data['device_id'] = device_id;
    data['device_name'] = device_name;
    data['brand'] = brand;
    data['model'] = model;
    data['manufacturer'] = manufacturer;
    data['android_version'] = android_version;
    data['ram_size'] = ram_size;
    return data;
  }
}
