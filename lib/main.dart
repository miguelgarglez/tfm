import 'package:combined_playlist_maker/artist.dart';
import 'package:combined_playlist_maker/track.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:combined_playlist_maker/user.dart';
import 'package:combined_playlist_maker/routes.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

void main() async {
  await Hive.initFlutter();
  Hive.registerAdapter(UserAdapter());
  await Hive.openBox('auth');
  await Hive.openBox('tokens');
  await Hive.openBox('codeVerifiers');
  await Hive.openBox<User>('users');
  usePathUrlStrategy();
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

List hiveGetUsers() {
  return Hive.box<User>('users').values.toList();
}

bool hiveDeleteUser(String userId) {
  var userBox = Hive.box<User>('users');
  if (userBox.containsKey(userId)) {
    userBox.delete(userId);
    return true;
  }
  return false;
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
