class DeviceInfoModel {
  final String device_id;
  final String device_name;
  final String brand;
  final String model;
  final String manufacturer;
  final String? android_version;
  final String? ram_size;
  final String? token;

  DeviceInfoModel({
    required this.brand,
    required this.manufacturer,
    required this.model,
    required this.device_name,
    required this.device_id,
    this.ram_size,
    this.android_version,
    this.token,
  });

  /// Convert JSON to Model
  factory DeviceInfoModel.fromJson(Map<String, dynamic> json) {
    return DeviceInfoModel(
      device_id: json['id'] ?? '',
      brand: json['brand'] ?? '',
      manufacturer: json['manufacturer'] ?? '',
      model: json['model'] ?? '',
      device_name: json['name'] ?? '',
      ram_size: json['physicalRamSize'] ?? '',
      android_version: json['androidVersion'] ?? '',
      token: json['token'] ?? '',
    );
  }

  /// Convert Model to JSON
  Map<String, dynamic> toJson() {
    return {
      'device_id': device_id,
      'brand': brand,
      'manufacturer': manufacturer,
      'model': model,
      'device_name': device_name,
      'ram_size': ram_size,
      'android_version': android_version,
      'token': token,
    };
  }
}
