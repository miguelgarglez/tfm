import 'package:combined_playlist_maker/models/track.dart';
import 'package:combined_playlist_maker/widgets/artist_tile.dart';
import 'package:combined_playlist_maker/widgets/track_tile.dart';
import 'package:flutter/material.dart';

class PlaylistDisplay extends StatelessWidget {
  final List items;
  final String title;
  String? userId;

  PlaylistDisplay(
      {super.key, required this.items, required this.title, this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        // Agrega el contenido de tu widget aquí
        child: ListView.builder(
          itemBuilder: (BuildContext context, int index) {
            return Padding(
              padding: const EdgeInsets.all(15.0),
              child: TrackTile(userId: userId, track: items[index]),
            );
          },
          itemCount: items.length,
        ),
      ),
    );
  }
}
