import 'package:combined_playlist_maker/screens/save_playlist.dart';
import 'package:combined_playlist_maker/widgets/track_tile.dart';
import 'package:flutter/material.dart';

Map strategyLabels = {
  //'average': 'Average',
  //'most_pleasure': 'Most Pleasure',
  'multiplicative': 'Strategy A',
  'least_misery': 'Strategy B',
  //'borda': 'Borda',
  //'average_custom': 'Average without misery',
};

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
    // * If something happened and there are no playlists to display
    if (items.isEmpty && playlists.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(title),
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: Icon(Icons.error_outline_outlined,
                  size: 100, color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'Something went wrong.\nNo items to display',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
          ],
        ),
      );
      // * If there is only one playlist to display
    } else if (items.isNotEmpty) {
      return Scaffold(
          appBar: AppBar(
            title: Text(title),
          ),
          body: Center(
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
      // * If there are multiple playlists to display and compare
    } else {
      return DefaultTabController(
        length: playlists.length,
        child: Builder(builder: (BuildContext context) {
          final TabController tabController = DefaultTabController.of(context);
          return Scaffold(
            appBar: AppBar(
              bottom: TabBar(
                tabAlignment: TabAlignment.center,
                isScrollable: true,
                tabs: playlists.keys
                    .map((key) => Tab(
                          text: strategyLabels[key],
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
                // ! Tal y como está ahora mostrará solamente para elegir en qué usuario guardarlo
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SavePlaylist.defaultSaving(
                          items:
                              playlists.values.elementAt(tabController.index),
                          strategy: strategyLabels.values
                              .toList()[tabController.index]),
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
