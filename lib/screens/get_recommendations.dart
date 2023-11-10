import 'package:combined_playlist_maker/services/requests.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:multi_select_flutter/dialog/multi_select_dialog_field.dart';
import 'package:multi_select_flutter/util/multi_select_item.dart';

class GetRecommendations extends StatefulWidget {
  final String? userId;

  GetRecommendations({super.key, this.userId});
  @override
  _GetRecommendationsState createState() => _GetRecommendationsState();
}

class _GetRecommendationsState extends State<GetRecommendations> {
  // Variables para los valores del formulario
  List<MultiSelectItem> _seed_genres = <MultiSelectItem>[];
  List<MultiSelectItem> _seed_tracks = <MultiSelectItem>[];
  List<MultiSelectItem> _seed_artists = <MultiSelectItem>[];
  double limit = 25;

  List seedGenres = [];
  List seedTracks = [];
  List seedArtists = [];

  // Controladores para los campos de entrada
  final controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    initializeData();
  }

  Future<void> initializeData() async {
    try {
      List seedGenres = await getGenreSeeds(widget.userId!);
      List seedTracks =
          (await getUsersTopItems(widget.userId!, 'tracks', 'short_term', 15))
              .content;
      List seedArtists =
          (await getUsersTopItems(widget.userId!, 'artists', 'short_term', 15))
              .content;
      _seed_genres = seedGenres
          .map<MultiSelectItem>((genre) => MultiSelectItem(genre, genre))
          .toList();
      _seed_artists = seedArtists
          .map<MultiSelectItem>(
              (artist) => MultiSelectItem(artist.id, artist.name))
          .toList();
      _seed_tracks = seedTracks
          .map<MultiSelectItem>(
              (track) => MultiSelectItem(track.id, track.name))
          .toList();
    } catch (error) {
      // Manejar errores si es necesario
      print('Error during initialization: $error');
    }
    setState(() {});
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Slider buildLimitField() {
    return Slider(
      value: limit,
      onChanged: (newValue) {
        setState(() {
          _seed_artists = _seed_artists;
          _seed_genres = _seed_genres;
          _seed_tracks = _seed_tracks;
          limit = newValue;
        });
      },
      min: 1.0, // Valor mínimo
      max: 50.0, // Valor máximo
      divisions: 49, // Número de divisiones (de 1 a 50)
      label: limit.round().toString(), // Etiqueta con el valor
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Adjust recommendation parameters'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 15, right: 15, top: 15),
              child: Text('Select up to 5 music genres'),
            ),
            Padding(
                padding: const EdgeInsets.all(15.0),
                child: MultiSelectDialogField(
                  items: _seed_genres, //_items['seed_genres'],
                  initialValue: [],
                  title: Text('Select genres'),
                  selectedColor: Theme.of(context).highlightColor,
                  buttonIcon: Icon(Icons.arrow_drop_down),
                  buttonText: Text('Choose music genres'),
                  selectedItemsTextStyle: Theme.of(context).textTheme.bodyLarge,
                  itemsTextStyle: Theme.of(context).textTheme.bodyLarge,
                  unselectedColor: Theme.of(context).highlightColor,
                  searchable: true,
                  onConfirm: (results) {
                    seedGenres = results;
                  },
                )),
            Padding(
              padding: const EdgeInsets.only(left: 15, right: 15, top: 15),
              child: Text('Select artists'),
            ),
            Padding(
                padding: const EdgeInsets.all(15.0),
                child: MultiSelectDialogField(
                  items: _seed_artists, //_items['seed_artists'],
                  initialValue: [],
                  title: Text('Select up to 5 artists'),
                  selectedColor: Theme.of(context).highlightColor,
                  buttonIcon: Icon(Icons.arrow_drop_down),
                  buttonText: Text('Choose artists'),
                  selectedItemsTextStyle: Theme.of(context).textTheme.bodyLarge,
                  itemsTextStyle: Theme.of(context).textTheme.bodyLarge,
                  unselectedColor: Theme.of(context).highlightColor,
                  onConfirm: (results) {
                    seedArtists = results;
                  },
                )),
            Padding(
              padding: const EdgeInsets.only(left: 15, right: 15, top: 15),
              child: Text('Select tracks'),
            ),
            Padding(
                padding: const EdgeInsets.all(15.0),
                child: MultiSelectDialogField(
                  items: _seed_tracks, //_items['seed_tracks'],
                  initialValue: [],
                  title: Text('Select up to 5 tracks'),
                  selectedColor: Theme.of(context).highlightColor,
                  buttonIcon: Icon(Icons.arrow_drop_down),
                  buttonText: Text('Choose tracks'),
                  selectedItemsTextStyle: Theme.of(context).textTheme.bodyLarge,
                  itemsTextStyle: Theme.of(context).textTheme.bodyLarge,
                  unselectedColor: Theme.of(context).highlightColor,
                  onConfirm: (results) {
                    seedArtists = results;
                  },
                )),
            Padding(
              padding: const EdgeInsets.only(left: 15, right: 15, top: 15),
              child: Text('Limit the length of the recommendation'),
            ),
            Padding(
                padding: const EdgeInsets.all(15.0), child: buildLimitField()),
            ElevatedButton(
              onPressed: () {
                print('Va a ejecutar getRecommendations!!');
                getRecommendations(widget.userId!, seedGenres, seedArtists,
                        seedTracks, limit)
                    .then((recommendationsResponse) {
                  context.go(
                      '/users/${widget.userId}/get-recommendations/recommendations',
                      extra: recommendationsResponse.content);
                });
              },
              child: Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
