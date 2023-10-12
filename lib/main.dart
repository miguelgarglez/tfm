import 'package:combined_playlist_maker/requests.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import 'user.dart';

void main() async {
  await Hive.initFlutter();
  Hive.registerAdapter(UserAdapter());
  await Hive.openBox('auth');
  await Hive.openBox('tokens');
  await Hive.openBox('codeVerifiers');
  await Hive.openBox<User>('users');
  //setUrlStrategy(PathUrlStrategy());
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
    return MaterialApp(
      title: 'Combined Playlist Maker',
      theme: lightTheme,
      home: const MyHomePage(),
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
                      retrieveSpotifyProfileInfo();
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => UsersDisplay()),
                      );
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

class UsersDisplay extends StatefulWidget {
  @override
  _UsersDisplayState createState() => _UsersDisplayState();
}

class _UsersDisplayState extends State<UsersDisplay> {
  late List users;

  @override
  void initState() {
    super.initState();
    //Hive.box<User>('users').values.toList()
    users = Hive.box<User>('users').values.toList();
    print('Users: $users');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome!'),
      ),
      body: Center(
        // Agrega el contenido de tu widget aquí
        child: ListView.builder(
          itemBuilder: (BuildContext context, int index) {
            return Padding(
              padding: const EdgeInsets.all(15.0),
              child: ListTile(
                leading: Image(image: NetworkImage(users[index].imageUrl)),
                title: Text(users[index].id),
              ),
            );
          },
          itemCount: users.length,
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

void deleteContentFromHive() async {
  await Hive.box('auth').clear();
  await Hive.box('tokens').clear();
  await Hive.box<User>('users').clear();
  await Hive.box('codeVerifiers').clear();
}
