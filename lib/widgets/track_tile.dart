import 'package:combined_playlist_maker/models/track.dart';
import 'package:combined_playlist_maker/screens/track_detail.dart';
import 'package:flutter/material.dart';

class TrackTile extends StatelessWidget {
  final Track track;
  String? userId;

  TrackTile({super.key, required this.track, this.userId});
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: FadeInImage.assetNetwork(
        placeholder: 'images/unknown_cover.png',
        image: track.imageUrl,
        imageErrorBuilder: (context, error, stackTrace) {
          return Image.asset('images/unknown_cover.png');
        },
      ),
      title: Text(track.name),
      subtitle: Text(
          track.artists.map((artist) => artist['name'].toString()).join(', ')),
      trailing: Icon(Icons.music_note_sharp),
      onTap: () {
        String currentPath = Uri.base.path;
        if (currentPath.startsWith('/users/$userId/get-top-items/top-tracks')) {
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TrackDetail(track: track),
              ));
        } else if (currentPath
            .startsWith('/users/$userId/get-recommendations/recommendations')) {
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TrackDetail(track: track),
              ));
        } else if (currentPath
            .startsWith('/users/generate-playlist-basic/playlist')) {
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TrackDetail(track: track),
              ));
        } else {
          // show snackbar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('You can\'t see this track\'s details here'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
    );
  }
}
