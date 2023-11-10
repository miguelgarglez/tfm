import 'package:combined_playlist_maker/main.dart';
import 'package:combined_playlist_maker/models/user.dart';
import 'package:combined_playlist_maker/services/requests.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

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
    List<User> currentUsers = Hive.box<User>('users').values.toList();
    widget.users = currentUsers;
  }

  @override
  /*Widget build(BuildContext context) {
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
  }*/
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome!'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // Dos columnas
            crossAxisSpacing: 10.0, // Espacio entre columnas
            mainAxisSpacing: 10.0, // Espacio entre filas
          ),
          itemBuilder: (BuildContext context, int index) {
            return InkWell(
              onTap: () => context.go('/users/${widget.users![index].id}'),
              child: Card(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Imagen del usuario
                    ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: FadeInImage.assetNetwork(
                        placeholder: 'images/unknown_cover.png',
                        image: widget.users![index].imageUrl,
                        imageErrorBuilder: (context, error, stackTrace) {
                          return Image.asset('images/unknown_cover.png');
                        },
                        width: double.infinity,
                        height: 115,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(widget.users![index].displayName),
                        // Menú desplegable con tres puntos para acciones
                        PopupMenuButton<String>(
                          itemBuilder: (context) {
                            return <PopupMenuEntry<String>>[
                              const PopupMenuItem<String>(
                                value: 'delete',
                                child: Text('Delete'),
                              ),
                              const PopupMenuItem<String>(
                                value: 'token',
                                child: Text('Get Token'),
                              ),
                              // Agrega más opciones de menú según tus necesidades
                            ];
                          },
                          onSelected: (String choice) {
                            if (choice == 'delete') {
                              hiveDeleteUser(widget.users![index].id);
                              if (hiveGetUsers().isNotEmpty) {
                                context.go('/users');
                              } else {
                                var authBox = Hive.box('auth');
                                authBox.clear().then((v) => context.go('/'));
                              }
                            } else if (choice == 'token') {
                              var userId = widget.users![index].id;
                              refreshToken(userId).then((tokenResponse) {
                                if (tokenResponse.content.isNotEmpty) {
                                  var usersBox = Hive.box<User>('users');
                                  User? u =
                                      usersBox.get(widget.users![index].id);
                                  print('Token "renovado": $tokenResponse');
                                  u!.accessToken =
                                      tokenResponse.content['access_token'];
                                  u.refreshToken =
                                      tokenResponse.content['refresh_token'];
                                  usersBox.delete(u.id);
                                  usersBox.put(u.id, u);
                                } else {
                                  // error al renovar el token de acceso
                                }
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    // Nombre del usuario
                  ],
                ),
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
    );
  }
}
