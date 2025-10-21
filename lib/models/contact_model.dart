// lib/models/contact_model.dart
class ContactModel {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String userId;
  final DateTime createdAt;

  ContactModel({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    required this.userId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'user_id': userId,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory ContactModel.fromMap(Map<String, dynamic> map) {
    return ContactModel(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      phone: map['phone'],
      userId: map['user_id'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
    );
  }

  ContactModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? userId,
    DateTime? createdAt,
  }) {
    return ContactModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
