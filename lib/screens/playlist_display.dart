import 'package:combined_playlist_maker/screens/save_playlist.dart';
import 'package:combined_playlist_maker/widgets/track_tile.dart';
import 'package:flutter/material.dart';

class PlaylistDisplay extends StatelessWidget {
  final List items;
  final String title;
  final String? userId;

  const PlaylistDisplay(
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
                child: TrackTile(track: items[index]),
              );
            },
            itemCount: items.length,
          ),
        ),
        floatingActionButton: FloatingActionButton(
          tooltip: 'Save playlist to Spotify',
          onPressed: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SavePlaylist(items: items),
                ));
          },
          child: const Icon(Icons.save_alt_rounded),
        ));
  }
}
