import 'package:hive_flutter/hive_flutter.dart';

class User {
  final String id;
  final String email;
  final String imageUrl;
  String accessToken;

  User({
    required this.id,
    required this.email,
    required this.imageUrl,
    required this.accessToken,
  });

  // Constructor alternativo para crear un User desde JSON
  // recibido de la request de los datos de usuario getProfileInfo
  factory User.fromJson(Map<String, dynamic> json, String token) {
    return User(
      id: json['id'],
      email: json['email'],
      imageUrl: json['images'][1]['url'],
      accessToken: token,
    );
  }

  @override
  String toString() {
    return 'User{id: $id, email: $email, imageUrl: $imageUrl, accessToken: $accessToken}';
  }
}

class UserAdapter extends TypeAdapter<User> {
  @override
  final int typeId = 0; // Identificador único para la clase User

  @override
  User read(BinaryReader reader) {
    // Lee los campos del usuario desde la caja
    final id = reader.readString();
    final email = reader.readString();
    final imageUrl = reader.readString();
    final accessToken = reader.readString();

    // Crea y devuelve un objeto User
    return User(
        id: id, email: email, imageUrl: imageUrl, accessToken: accessToken);
  }

  @override
  void write(BinaryWriter writer, User obj) {
    // Escribe los campos del usuario en la caja
    writer.writeString(obj.id);
    writer.writeString(obj.email);
    writer.writeString(obj.imageUrl);
    writer.writeString(obj.accessToken);
  }
}
