import 'package:combined_playlist_maker/models/track.dart';
import 'package:combined_playlist_maker/utils/work_in_progress.dart';
import 'package:flutter/material.dart';

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
