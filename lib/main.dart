import 'package:combined_playlist_maker/artist.dart';
import 'package:combined_playlist_maker/forms.dart';
import 'package:combined_playlist_maker/requests.dart';
import 'package:combined_playlist_maker/track.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:combined_playlist_maker/user.dart';
import 'package:combined_playlist_maker/routes.dart';

void main() async {
  await Hive.initFlutter();
  Hive.registerAdapter(UserAdapter());
  await Hive.openBox('auth');
  await Hive.openBox('tokens');
  await Hive.openBox('codeVerifiers');
  await Hive.openBox<User>('users');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    ThemeData lightTheme = ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        bodyLarge: TextStyle(fontSize: 18, color: Colors.black87),
      ),
      appBarTheme: const AppBarTheme(
        color: Colors.green,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      colorScheme:
          ColorScheme.fromSeed(seedColor: Color.fromARGB(255, 39, 214, 19)),
    );
    return MaterialApp.router(
      routerConfig: MyAppRoutes(),
      title: 'Combined Playlist Maker',
      theme: lightTheme,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var children = <Widget>[];

    //aquí realmente tendré que acabar haciendo una funcion que compruebe si el
    //token que haya está en vigor con la API de spotify
    if (!isAuthenticated()) {
      //mostrar botón de login, no mostrar botón comenzar
      children = <Widget>[
        Padding(
          padding: const EdgeInsets.all(15.0),
          child: ElevatedButton(
              onPressed: requestAuthorization,
              child: Text('Login with Spotify')),
        ),
        Padding(
          padding: EdgeInsets.all(15.0),
          child: Text('And start using the app!'),
        ),
      ];
    } else {
      //no mostrar botón de login, y mostrar botón comenzar
      children = <Widget>[
        Padding(
          padding: const EdgeInsets.all(15.0),
          child: Text('You logged in from Spotify'),
        ),
        Padding(
          padding: EdgeInsets.all(15.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 7),
                child: ElevatedButton(
                    onPressed: () {
                      // este bloque de if-else viene dado porque con la primera llamada para coger los datos del usuario
                      // (y guardarlos en Hive), los datos parecia que tardaban en guardarse, y entonces en la vista de
                      // lista de usuarios, no se veía nada, este arreglo hace que con la primera llamada (cuando no hay
                      // usuarios en Hive aún), se coja directamente el usuario creado con los datos cogidos en
                      // retrieveSpotifyProfileInfo
                      retrieveSpotifyProfileInfo().then((user) {
                        context.go('/users/');
                        /*Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => UsersDisplay(user: user)),
                          );*/
                      });
                    },
                    child: Text('See user\'s list')),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 7),
                child: ElevatedButton(
                    onPressed: () {
                      deleteContentFromHive();
                      setState(() {});
                    },
                    child: Text('Delete data')),
              ),
            ],
          ),
        ),
      ];
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome to CPM from Spotify'),
      ),
      body: Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: children,
      )),
    );
  }
}

List hiveGetUsers() {
  return Hive.box<User>('users').values.toList();
}

void deleteContentFromHive() async {
  await Hive.box('auth').clear();
  await Hive.box('tokens').clear();
  await Hive.box<User>('users').clear();
  await Hive.box('codeVerifiers').clear();
}

class ItemDisplay extends StatelessWidget {
  final List items;

  ItemDisplay({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Top Items'),
      ),
      body: Center(
        // Agrega el contenido de tu widget aquí
        child: ListView.builder(
          itemBuilder: (BuildContext context, int index) {
            var child;
            if (items[index].runtimeType == Track) {
              child = TrackTile(item: items[index]);
            } else {
              child = ArtistTile(item: items[index]);
            }
            return Padding(
              padding: const EdgeInsets.all(15.0),
              child: child,
            );
          },
          itemCount: items.length,
        ),
      ),
    );
  }
}

class WorkInProgressScreen extends StatelessWidget {
  const WorkInProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Work in Progress'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Work in Progress',
              style: TextStyle(fontSize: 24.0),
            ),
            SizedBox(height: 20.0),
            Icon(
              Icons.build, // Icono de herramientas
              size: 48.0, // Tamaño del icono
            ),
          ],
        ),
      ),
    );
  }
}

class BasicDataVisualization extends StatelessWidget {
  final String data;

  const BasicDataVisualization({super.key, required this.data});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Data Retrieved'),
      ),
      body: Expanded(
          child: SingleChildScrollView(
              scrollDirection: Axis.vertical, child: Text('${data}'))),
    );
  }
}
