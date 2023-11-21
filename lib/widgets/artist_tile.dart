import 'package:combined_playlist_maker/models/artist.dart';
import 'package:combined_playlist_maker/utils/work_in_progress.dart';
import 'package:flutter/material.dart';

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
