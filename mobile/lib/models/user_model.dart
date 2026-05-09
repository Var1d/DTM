import '../utils/constants.dart';

class UserModel {
  final int id;
  final String name;
  final String email;
  final String? avatarUrl;

  UserModel({required this.id, required this.name, required this.email, this.avatarUrl});

  factory UserModel.fromJson(Map<String, dynamic> json) {
    String? avatar = json['avatar_url'];
    
    // Jika URL relatif (diawali dengan /), gabungkan dengan rootUrl
    if (avatar != null) {
      if (avatar.startsWith('/')) {
        avatar = '${AppConstants.rootUrl}$avatar';
      } else if (avatar.contains('localhost')) {
        // Ganti localhost dengan IP emulator (10.0.2.2) jika dari web
        avatar = avatar.replaceAll('localhost', '10.0.2.2');
      }
    }

    return UserModel(
      id:        json['id'],
      name:      json['name'],
      email:     json['email'],
      avatarUrl: avatar,
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'email': email, 'avatar_url': avatarUrl};
}
