import 'package:combined_playlist_maker/forms.dart';
import 'package:combined_playlist_maker/requests.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

class User {
  final displayName;
  final String id;
  final String email;
  final String imageUrl;
  final String country;
  final int followers;
  String accessToken;

  User({
    required this.displayName,
    required this.id,
    required this.email,
    required this.imageUrl,
    required this.country,
    required this.followers,
    required this.accessToken,
  });

  // Constructor alternativo para crear un User desde JSON
  // recibido de la request de los datos de usuario getProfileInfo
  factory User.fromJson(Map<String, dynamic> json, String token) {
    return User(
      displayName: json['display_name'],
      id: json['id'],
      email: json['email'],
      imageUrl: json['images'][1]['url'],
      country: json['country'],
      followers: json['followers']['total'],
      accessToken: token,
    );
  }

  factory User.notValid() {
    return User(
        displayName: '',
        id: '',
        email: '',
        imageUrl: '',
        country: '',
        followers: 0,
        accessToken: '');
  }

  @override
  String toString() {
    return 'User{display_name: $displayName, id: $id, email: $email, imageUrl: $imageUrl, country: $country, followers: $followers, accessToken: $accessToken}';
  }
}

class UserAdapter extends TypeAdapter<User> {
  @override
  final int typeId = 0; // Identificador único para la clase User

  @override
  User read(BinaryReader reader) {
    // Lee los campos del usuario desde la caja
    final displayName = reader.readString();
    final id = reader.readString();
    final email = reader.readString();
    final imageUrl = reader.readString();
    final country = reader.readString();
    final followers = reader.readInt();
    final accessToken = reader.readString();

    // Crea y devuelve un objeto User
    return User(
        displayName: displayName,
        id: id,
        email: email,
        imageUrl: imageUrl,
        country: country,
        followers: followers,
        accessToken: accessToken);
  }

  @override
  void write(BinaryWriter writer, User obj) {
    // Escribe los campos del usuario en la caja
    writer.writeString(obj.displayName);
    writer.writeString(obj.id);
    writer.writeString(obj.email);
    writer.writeString(obj.imageUrl);
    writer.writeString(obj.country);
    writer.writeInt(obj.followers);
    writer.writeString(obj.accessToken);
  }
}

class UsersDisplay extends StatefulWidget {
  List<User>? users = Hive.box<User>('users').values.toList();
  final User? user;

  UsersDisplay({super.key, this.user});
  @override
  _UsersDisplayState createState() => _UsersDisplayState();
}

class _UsersDisplayState extends State<UsersDisplay> {
  @override
  void initState() {
    super.initState();
    //Hive.box<User>('users').values.toList()
    List<User> currentUsers = Hive.box<User>('users').values.toList();
    widget.users = currentUsers;

    print('Users: ${widget.users}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome!'),
      ),
      body: Center(
        child: ListView.builder(
          itemBuilder: (BuildContext context, int index) {
            return Padding(
              padding: const EdgeInsets.all(15.0),
              child: ListTile(
                leading: FadeInImage.assetNetwork(
                    placeholder: 'images/unknown_cover.png',
                    image: widget.users![index].imageUrl,
                    imageErrorBuilder: (context, error, stackTrace) {
                      return Image.asset('images/unknown_cover.png');
                    }),
                title: Text(widget.users![index].displayName),
                onTap: () {
                  context.go('/users/${widget.users![index].id}');
                  /*context.go(Uri(
                    path: 'user',
                    queryParameters: {'id': widget.users![index].id},
                  ).toString());*/
                  /*Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            UserDetail(id: widget.users![index].id),
                      ));*/
                },
              ),
            );
          },
          itemCount: widget.users!.length,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          requestAuthorization();
        },
        tooltip: 'Add another spotify user',
        child: Icon(Icons.add),
      ),
      // Agrega otros widgets y elementos de IU aquí
    );
  }
}

class UserDetail extends StatelessWidget {
  final String? id;

  const UserDetail({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    var userBox = Hive.box<User>('users');
    User? user = userBox.get(id);
    return Scaffold(
      appBar: AppBar(
        title: Text(user!.displayName),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(user.id),
            Text(user.email),
            Text('Country: ${user.country}'),
            Text('Followers: ${user.followers}'),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Image(image: NetworkImage(user.imageUrl)),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 15, left: 15, top: 15),
              child:
                  Text('Want to know your most listened artists and tracks?'),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: ElevatedButton(
                  onPressed: () {
                    context.go('/users/${user.id}/get-top-items');
                    /*Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: ((context) => GetTopItems(
                                  user: user,
                                ))));*/
                  },
                  child: Text('Let\'s go!')),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 15, left: 15, top: 15),
              child: Text('Want new songs to listen to?'),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: ElevatedButton(
                  onPressed: () {
                    Map recommendationParams = {};
                    getGenreSeeds(user.id).then((genreSeeds) {
                      recommendationParams['genre_seeds'] = genreSeeds;
                      return getUsersTopItems(
                          user.id, 'tracks', 'short_term', 15);
                    }).then((topTracks) {
                      recommendationParams['track_seeds'] = topTracks;
                      return getUsersTopItems(
                          user.id, 'artists', 'short_term', 15);
                    }).then((topArtists) {
                      recommendationParams['artist_seeds'] = topArtists;
                      context.go('/users/${user.id}/get-recommendations',
                          extra: recommendationParams);
                      /*Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: ((context) => GetRecommendations(
                                    userId: id,
                                    genreOptions:
                                        recommendationParams['genre_seeds'],
                                    trackOptions:
                                        recommendationParams['track_seeds'],
                                    artistOptions:
                                        recommendationParams['artist_seeds'],
                                  ))));*/
                    });
                  },
                  child: Text('Get Recommendations')),
            )
          ],
        ),
      ),
    );
  }
}
