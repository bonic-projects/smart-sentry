class UserModel {
  String id;
  final String name;
  final String email;
  final String password;
  bool isEmergencyContact;

  UserModel(
      {required this.id,
      required this.name,
      required this.email,
      required this.password,
      this.isEmergencyContact = false});

  // Convert UserModel to a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password': password,
    };
  }

  // Create UserModel from a Map
  factory UserModel.fromJson(Map<String, dynamic> map, String documentId) {
    return UserModel(
      id: documentId,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      password: map['password'] ?? '',
    );
  }
}
