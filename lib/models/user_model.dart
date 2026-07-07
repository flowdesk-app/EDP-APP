enum UserRole { admin, employee }

class UserModel {
  final String email;
  final String password;
  final UserRole role;
  final String? supplierId;

  UserModel({
    required this.email,
    required this.password,
    required this.role,
    this.supplierId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    email: json['email'] as String,
    password: json['password'] as String,
    role: json['role'] == 'admin' ? UserRole.admin : UserRole.employee,
    supplierId: json['supplierId'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'email': email,
    'password': password,
    'role': role == UserRole.admin ? 'admin' : 'employee',
    'supplierId': supplierId,
  };
}
