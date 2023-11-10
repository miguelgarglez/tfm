import 'package:combined_playlist_maker/main.dart';
import 'package:flutter/material.dart';

class Artist {
  List<String> genres;
  String id;
  String imageUrl;
  String name;
  int popularity;
  String href;

  Artist({
    required this.genres,
    required this.id,
    required this.imageUrl,
    required this.name,
    required this.popularity,
    required this.href,
  });

  factory Artist.fromJson(Map<String, dynamic> json) {
    return Artist(
      genres: List<String>.from(json['genres']),
      id: json['id'],
      imageUrl: json['images'][0]
          ['url'], // hay tres imágenes, cogemos la de mayor tamaño
      name: json['name'],
      popularity: json['popularity'],
      href: json['href'],
    );
  }

  @override
  String toString() {
    return 'Artist{name: $name, id: $id, popularity: $popularity, genres: $genres}';
  }
}

class ArtistTile extends StatelessWidget {
  final Artist item;

  ArtistTile({super.key, required this.item});
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: FadeInImage.assetNetwork(
          placeholder: 'images/unknown_cover.png',
          image: item.imageUrl,
          imageErrorBuilder: (context, error, stackTrace) {
            return Image.asset('images/unknown_cover.png');
          }),
      title: Text(item.name),
      subtitle: Text(item.genres.map((genre) => genre.toString()).join(', ')),
      trailing: Icon(Icons.portrait_rounded),
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
