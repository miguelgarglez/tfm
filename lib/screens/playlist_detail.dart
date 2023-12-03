import 'package:combined_playlist_maker/models/my_response.dart';
import 'package:combined_playlist_maker/models/playlist.dart';
import 'package:combined_playlist_maker/services/requests.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PlaylistDetail extends StatefulWidget {
  final String playlistId;
  final String userId;

  const PlaylistDetail(
      {Key? key, required this.playlistId, required this.userId})
      : super(key: key);

  @override
  _PlaylistDetailState createState() => _PlaylistDetailState();
}

class _PlaylistDetailState extends State<PlaylistDetail> {
  late Future<MyResponse> playlist;

  void initState() {
    super.initState();
    initializeData();
  }

  Future<void> initializeData() async {
    try {
      playlist = getPlaylist(widget.playlistId, widget.userId);
      /*playlist =
          Playlist.fromJson(playlistResponse.content) as Future<Playlist>;*/
    } catch (error) {
      throw Exception('Error initializing playlist on PlaylistDetail');
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Created playlist'),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: FutureBuilder(
            future: playlist,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text('Playlist saved!',
                          style: Theme.of(context).textTheme.displaySmall),
                    ),
                    SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(50.0),
                      child: Image.network(
                        snapshot.data!.content['images'][0]['url'],
                        width: 250,
                        height: 250,
                      ),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        Uri u = Uri.https('open.spotify.com',
                            '/playlist/${snapshot.data!.content['id']}');
                        canLaunchUrl(u).then((value) {
                          launchUrl(u);
                        }).onError((error, stackTrace) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Could not open playlist on Spotify'),
                            ),
                          );
                        });
                      },
                      child: Text('Play on Spotify'),
                    ),
                  ],
                );
              } else if (snapshot.hasError) {
                Navigator.pop(context);
                return Center(
                  child: Text('$snapshot.error'),
                );
              } else {
                return CircularProgressIndicator();
              }
            },
          ),
        ),
      ),
    );
  }
}
