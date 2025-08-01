class User {
  final String id;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? cookbookId;

  User({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    this.cookbookId,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      cookbookId: json['cookbook_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'cookbook_id': cookbookId,
    };
  }
}

class AuthResponse {
  final String accessToken;
  final int expires;
  final String refreshToken;

  AuthResponse({
    required this.accessToken,
    required this.expires,
    required this.refreshToken,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    return AuthResponse(
      accessToken: data['access_token'],
      expires: data['expires'],
      refreshToken: data['refresh_token'],
    );
  }
}