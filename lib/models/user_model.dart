enum UserRole { admin, employee, employee1, employee2, employee3 }

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

  factory UserModel.fromJson(Map<String, dynamic> json) {
    UserRole parsedRole = UserRole.employee;
    if (json['role'] == 'admin') parsedRole = UserRole.admin;
    else if (json['role'] == 'employee1') parsedRole = UserRole.employee1;
    else if (json['role'] == 'employee2') parsedRole = UserRole.employee2;
    else if (json['role'] == 'employee3') parsedRole = UserRole.employee3;

    return UserModel(
      email: json['email'] as String,
      password: json['password'] as String,
      role: parsedRole,
      supplierId: json['supplierId'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'email': email,
    'password': password,
    'role': role.name,
    'supplierId': supplierId,
  };
}
