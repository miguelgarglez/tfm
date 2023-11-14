import 'package:combined_playlist_maker/main.dart';
import 'package:combined_playlist_maker/utils/work_in_progress.dart';
import 'package:flutter/material.dart';

class Track {
  List<Map<String, String>> artists;
  int durationMs;
  String isrc;
  String href;
  String id;
  String name;
  String imageUrl;
  int popularity;
  int trackNumber;

  Track({
    required this.artists,
    required this.durationMs,
    required this.isrc,
    required this.href,
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.popularity,
    required this.trackNumber,
  });

  factory Track.fromJson(Map<String, dynamic> json) {
    var imageUrl;
    if ((json['album']['images'] as List).isNotEmpty) {
      // La lista de imágenes no está vacía y puedes acceder a json['album']['images'][0]
      imageUrl = json['album']['images'][0]
          ['url']; // hay tres imágenes, cogemos la de mayor tamaño
    } else {
      // La lista de imágenes está vacía o no existe la clave 'images' en el JSON
      imageUrl = '';
    }

    return Track(
      artists: List<Map<String, String>>.from(json['artists'].map((artist) =>
          <String, String>{'id': artist['id'], 'name': artist['name']})),
      durationMs: json['duration_ms'],
      isrc: json['external_ids']['isrc'],
      href: json['href'],
      id: json['id'],
      name: json['name'],
      imageUrl: imageUrl,
      popularity: json['popularity'],
      trackNumber: json['track_number'],
    );
  }

  @override
  String toString() {
    return 'Track{name: $name, id: $id, artists: $artists, popularity: $popularity}';
  }
}

class TrackTile extends StatelessWidget {
  final Track item;

  TrackTile({super.key, required this.item});
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: FadeInImage.assetNetwork(
        placeholder: 'images/unknown_cover.png',
        image: item.imageUrl,
        imageErrorBuilder: (context, error, stackTrace) {
          return Image.asset('images/unknown_cover.png');
        },
      ),
      title: Text(item.name),
      subtitle: Text(
          item.artists.map((artist) => artist['name'].toString()).join(', ')),
      trailing: Icon(Icons.music_note_sharp),
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WorkInProgressScreen(),
            ));
      },
    );
  }
}
