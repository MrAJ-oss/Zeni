class User {
  final String name;
  final String voiceId;

  User({
    required this.name,
    required this.voiceId,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      name: json["name"],
      voiceId: json["voiceId"] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "voiceId": voiceId,
    };
  }
}