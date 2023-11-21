import 'package:combined_playlist_maker/main.dart';
import 'package:combined_playlist_maker/models/user.dart';
import 'package:combined_playlist_maker/services/requests.dart';
import 'package:combined_playlist_maker/utils/work_in_progress.dart';
import 'package:combined_playlist_maker/widgets/expandable_fab.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

// ignore: must_be_immutable
class UsersDisplay extends StatefulWidget {
  List<User>? users = Hive.box<User>('users').values.toList();
  final User? user;

  UsersDisplay({super.key, this.user});
  @override
  // ignore: library_private_types_in_public_api
  _UsersDisplayState createState() => _UsersDisplayState();
}

class _UsersDisplayState extends State<UsersDisplay> {
  @override
  void initState() {
    super.initState();
    List<User> currentUsers = Hive.box<User>('users').values.toList();
    widget.users = currentUsers;
  }

  int calculateCrossAxisCount(BuildContext context) {
    // Puedes ajustar estos valores según tus preferencias
    double screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 1600) {
      return 5;
    } else if (screenWidth > 1000) {
      return 4;
    } else if (screenWidth > 700) {
      return 3;
    } else {
      return 2;
    }
  }

  TextStyle? calculateFontSize(BuildContext context) {
    // Puedes ajustar estos valores según tus preferencias
    double screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth > 1300) {
      return Theme.of(context)
          .textTheme
          .headlineMedium; // Más de 1200, usa 4 columnas
    } else if (screenWidth > 500) {
      return Theme.of(context).textTheme.headlineSmall;
    } else {
      return Theme.of(context)
          .textTheme
          .bodyLarge; // Menos de 800, usa 2 columnas (valor predeterminado)
    }
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
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: calculateCrossAxisCount(context), // Dos columnas
            crossAxisSpacing: 10.0, // Espacio entre columnas
            mainAxisSpacing: 10.0, // Espacio entre filas
          ),
          itemBuilder: (BuildContext context, int index) {
            return InkWell(
              onTap: () {
                widget.users![index].updateToken();
                context.go('/users/${widget.users![index].id}');
              },
              child: Card(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // Imagen del usuario
                    ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: AspectRatio(
                        aspectRatio: 52 / 40,
                        child: FadeInImage.assetNetwork(
                          placeholder: 'images/unknown_cover.png',
                          image: widget.users![index].imageUrl,
                          imageErrorBuilder: (context, error, stackTrace) {
                            return Image.asset('images/unknown_cover.png');
                          },
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(widget.users![index].displayName,
                                overflow: TextOverflow
                                    .ellipsis, // Se agrega esta línea
                                textAlign: TextAlign.center,
                                style: calculateFontSize(context)),
                          ),
                          // Menú desplegable con tres puntos para acciones
                          PopupMenuButton<String>(
                            itemBuilder: (context) {
                              return <PopupMenuEntry<String>>[
                                const PopupMenuItem<String>(
                                  value: 'delete',
                                  child: Text('Delete'),
                                ),
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
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          itemCount: widget.users!.length,
        ),
      ),
      floatingActionButton: ExpandableFab(
        distance: 60,
        children: [
          ActionButton(
            onPressed: () {
              requestAuthorization();
            },
            icon: const Icon(Icons.person_add),
            tooltip: 'Add a new user',
          ),
          ActionButton(
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WorkInProgressScreen(),
                  ));
            },
            icon: const Icon(Icons.playlist_add_rounded),
            tooltip: 'Make a combined playlist',
          ),
        ],
      ),
    );
  }
}
