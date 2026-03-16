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


// ==============================
// Forgot Password DTO
class ForgotPasswordRequest {
  final String email;

  const ForgotPasswordRequest({
    required this.email,
  });

  Map<String, dynamic> toJson() => {
    'email': email,
  };
}


// ==============================
// Reset Password DTO
class ResetPasswordRequest {
  final String token;
  final String newPassword;

  const ResetPasswordRequest({
    required this.token,
    required this.newPassword,
  });

  Map<String, dynamic> toJson() => {
    'token': token,
    'newPassword': newPassword,
  };
}

// ==============================
// Delete Account DTO
class DeleteAccountRequest {
  final String password;

  const DeleteAccountRequest({
    required this.password,
  });

  Map<String, dynamic> toJson() => {
    'password': password,
  };
}


// Definition of user responses xd


