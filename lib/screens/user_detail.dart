import 'package:combined_playlist_maker/models/user.dart';
import 'package:combined_playlist_maker/services/requests.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

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
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey,
                        offset: Offset(0, 5),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(50.0),
                    child: Image.network(
                      user.imageUrl,
                      width: 250,
                      height: 250,
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  user.id,
                  style: TextStyle(fontSize: 18),
                ),
                Text(
                  user.email,
                  style: TextStyle(fontSize: 18),
                ),
                Text(
                  'Country: ${user.country}',
                  style: TextStyle(fontSize: 18),
                ),
                Text(
                  'Followers: ${user.followers}',
                  style: TextStyle(fontSize: 18),
                ),
                SizedBox(height: 16),
                Text(
                  'Want to know your most listened artists and tracks?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context.go('/users/${user.id}/get-top-items');
                  },
                  child: Text('Let\'s go!'),
                ),
                SizedBox(height: 16),
                Text(
                  'Want new songs to listen to?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context.go('/users/${user.id}/get-recommendations');
                  },
                  child: Text('Get Recommendations'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}