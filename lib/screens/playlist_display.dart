import 'package:combined_playlist_maker/screens/save_playlist.dart';
import 'package:combined_playlist_maker/widgets/track_tile.dart';
import 'package:flutter/material.dart';

class PlaylistDisplay extends StatelessWidget {
  final List items;
  final String title;
  final String? userId;
  final Map<String, dynamic> playlists;

  const PlaylistDisplay(
      {super.key, required this.items, required this.title, this.userId})
      : playlists = const {};

  const PlaylistDisplay.multiplePlaylists(
      {super.key, required this.playlists, required this.title, this.userId})
      : items = const [];
  @override
  Widget build(BuildContext context) {
    if (items.isEmpty && playlists.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(title),
        ),
        body: Center(
          // Agrega el contenido de tu widget aquí
          child: Text('Something went wrong.\nNo items to display'),
        ),
      );
    } else if (items.isNotEmpty) {
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
    } else {
      return DefaultTabController(
        length: playlists.length,
        child: Builder(builder: (BuildContext context) {
          final TabController tabController = DefaultTabController.of(context)!;
          return Scaffold(
            appBar: AppBar(
              bottom: TabBar(
                tabAlignment: TabAlignment.center,
                isScrollable: true,
                tabs: playlists.keys
                    .map((key) => Tab(
                          text: key,
                        ))
                    .toList(),
              ),
              title: Text(title),
            ),
            body: TabBarView(children: [
              for (var playlist in playlists.values)
                Center(
                  child: ListView.builder(
                    itemBuilder: (BuildContext context, int index) {
                      return Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: TrackTile(track: playlist[index]),
                      );
                    },
                    itemCount: playlist.length,
                  ),
                ),
            ]),
            floatingActionButton: FloatingActionButton(
              tooltip: 'Save playlist to Spotify',
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SavePlaylist(
                          items:
                              playlists.values.elementAt(tabController.index)),
                    ));
              },
              child: const Icon(Icons.save_alt_rounded),
            ),
          );
        }),
      );
    }
  }
}
