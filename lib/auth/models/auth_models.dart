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
    'last_name': lastName,
    'email': email,
    'password': password,
    if (semester != null) 'semester': semester,
    if (profilePic != null) 'profile_pic': profilePic,
    'is_seller': isSeller,
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

  Map<String, dynamic> toJson() => {'token': token, 'new_password': newPassword};
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
  final String lastName;
  final String email;
  final int? semester;
  final String? profilePic;
  final bool isSeller;

  // se instancia el objeto
  const AuthUser({
    required this.id,
    required this.name,
    required this.lastName,
    required this.email,
    this.semester,
    this.profilePic,
    required this.isSeller,
  });

  // el factory es para que devuelva un objeto de la clase AuthUser
  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
    id: (json['id'] as num).toInt(),
    name: json['name'] as String? ?? '',
    lastName: json['last_name'] as String? ?? '',
    email: json['email'] as String? ?? '',
    semester: json['semester'] is num
        ? (json['semester'] as num).toInt()
        : null,
    profilePic: json['profile_pic'] as String?,
    isSeller: json['is_seller'] as bool? ?? false,
  );

  // se mappea el objeto a un json
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'last_name': lastName,
    'email': email,
    if (semester != null) 'semester': semester,
    if (profilePic != null) 'profile_pic': profilePic,
    'is_seller': isSeller,
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
  final String accessToken; // JWT
  final AuthUser user;

  const AuthResponse({required this.accessToken, required this.user});

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
    accessToken: json['access_token'] as String,
    user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
  );
}
