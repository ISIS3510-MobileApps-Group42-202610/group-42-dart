// ============================================================================
// Definition of backend DTOs for the auth requests

// Register DTO
class RegisterRequest {
  final String name;
  final String lastName;
  final String email;
  final String password;
  final int? semester;
  final String? profilePic;
  final bool isSeller;

  // se instancia el objeto
  const RegisterRequest({
    required this.name,
    required this.lastName,
    required this.email,
    required this.password,
    this.semester,
    this.profilePic,
    this.isSeller = true,
  });

  // se mappea el objeto a un json
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

// Login DTO
class LoginRequest {
  final String email;
  final String password;

  const LoginRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() => {'email': email, 'password': password};
}

// Forgot Password DTO
class ForgotPasswordRequest {
  final String email;

  const ForgotPasswordRequest({required this.email});

  Map<String, dynamic> toJson() => {'email': email};
}

// Reset Password DTO
class ResetPasswordRequest {
  final String token;
  final String newPassword;

  const ResetPasswordRequest({required this.token, required this.newPassword});

  Map<String, dynamic> toJson() => {'token': token, 'newPassword': newPassword};
}

// Delete Account DTO
class DeleteAccountRequest {
  final String password;

  const DeleteAccountRequest({required this.password});

  Map<String, dynamic> toJson() => {'password': password};
}

// ============================================================================
// Definition of user responses (from the backend) xd

// Clase de usuario
class AuthUser {
  final int id;
  final String name;
  final String email;
  final bool isSeller;

  // se instancia el objeto
  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.isSeller,
  });

  // el factory es para que devuelva un objeto de la clase AuthUser
  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
    id: json['id'] as int,
    name: json['name'] as String,
    email: json['email'] as String,
    isSeller: json['isSeller'] as bool ?? false,
  );

  // se mappea el objeto a un json
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'isSeller': isSeller,
  };
}

// mensaje x, cuando no hay body per se o usuario devuelto por el back
class MessageResponse {
  final String message;

  const MessageResponse({required this.message});

  factory MessageResponse.fromJson(Map<String, dynamic> json) =>
      MessageResponse(message: json['message'] as String ?? 'OK');

  Map<String, dynamic> toJson() => {'message': message};
}

// respuesta de usuario del backend
class AuthResponse {
  final String accesToken; // JWT
  final AuthUser user;

  const AuthResponse({required this.accesToken, required this.user});

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
    accesToken: json['accessToken'] as String,
    user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
  );
}
