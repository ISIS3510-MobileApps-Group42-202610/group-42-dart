// Definition of backend DTO


// ==============================
// Register DTO
class RegisterRequest {
  final String name;
  final String lastName;
  final String email;
  final String password;
  final int? semester;
  final String? profilePic;
  final bool isSeller;

  const RegisterRequest({
    required this.name,
    required this.lastName,
    required this.email,
    required this.password,
    this.semester,
    this.profilePic,
    this.isSeller = true,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'lastName': lastName,
    'email': email,
    'password': password,
    if (semester != null) 'semester': semester,
    if (profilePic != null) 'profilePic': profilePic,
    'isSeller': isSeller,
  };
}


// ==============================
// Login DTO
class LoginRequest {
  final String email;
  final String password;

  const LoginRequest({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
    'email': email,
    'password': password,
  };
}