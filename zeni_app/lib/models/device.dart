class Device {
  final String id;
  final String name;
  final bool approved;

  Device({
    required this.id,
    required this.name,
    required this.approved,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json["id"],
      name: json["name"],
      approved: json["approved"] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "approved": approved,
    };
  }
}