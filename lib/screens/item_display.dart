import 'package:combined_playlist_maker/models/artist.dart';
import 'package:combined_playlist_maker/models/track.dart';
import 'package:flutter/material.dart';

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
