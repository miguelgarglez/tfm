import 'package:combined_playlist_maker/models/my_response.dart';
import 'package:combined_playlist_maker/models/user.dart';
import 'package:combined_playlist_maker/return_codes.dart';
import 'package:combined_playlist_maker/services/error_handling.dart';
import 'package:combined_playlist_maker/services/requests.dart';
import 'package:combined_playlist_maker/utils/error_dialog.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
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

  List errorStatus = [];

  double limit = 25;
  late List genresResult;
  late List tracksResult;
  late List artistsResult;

  final formKey = new GlobalKey<FormState>();

  // Controladores para los campos de entrada
  final controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    genresResult = [];
    tracksResult = [];
    artistsResult = [];
    initializeData();
  }

  Future<void> initializeData() async {
    try {
      MyResponse g = await getGenreSeeds(widget.userId!);
      errorStatus.add(g.statusCode);

      MyResponse t =
          await getUsersTopItems(widget.userId!, 'tracks', 'short_term', 15);
      errorStatus.add(t.statusCode);
      MyResponse a =
          await getUsersTopItems(widget.userId!, 'artists', 'short_term', 15);
      errorStatus.add(a.statusCode);
      _seed_genres = g.content
          .map<MultiSelectItem>((genre) => MultiSelectItem(genre, genre))
          .toList();
      _seed_artists = a.content
          .map<MultiSelectItem>(
              (artist) => MultiSelectItem(artist.id, artist.name))
          .toList();
      _seed_tracks = t.content
          .map<MultiSelectItem>(
              (track) => MultiSelectItem(track.id, track.name))
          .toList();
    } catch (error) {
      // Manejar errores si es necesario
      print('Error during initialization in getRecommendations: $error');
    }
    // necesario para que termine de cargar las listas en los campos de opciones
    // del formulario
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
        child: Center(
          child: Form(
            key: formKey,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 15, right: 15, top: 15),
                  child: Text('Limit the length of the recommendation'),
                ),
                Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: buildLimitField()),
                Padding(
                  padding: const EdgeInsets.only(left: 15, right: 15, top: 15),
                  child: Text('Select up to 5 music genres'),
                ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: MultiSelectDialogField(
                    items: _seed_genres,
                    initialValue: genresResult,
                    title: Text('Select genres'),
                    selectedColor: Theme.of(context).highlightColor,
                    buttonIcon: Icon(Icons.arrow_drop_down),
                    buttonText: Text('Choose music genres'),
                    selectedItemsTextStyle:
                        Theme.of(context).textTheme.bodyLarge,
                    itemsTextStyle: Theme.of(context).textTheme.bodyLarge,
                    unselectedColor: Theme.of(context).highlightColor,
                    searchable: true,
                    separateSelectedItems: true,
                    onConfirm: (results) {
                      genresResult = results;
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 15, right: 15, top: 15),
                  child: Text('Select artists'),
                ),
                Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: MultiSelectDialogField(
                      items: _seed_artists,
                      initialValue: artistsResult,
                      title: Text('Select up to 5 artists'),
                      selectedColor: Theme.of(context).highlightColor,
                      buttonIcon: Icon(Icons.arrow_drop_down),
                      buttonText: Text('Choose artists'),
                      selectedItemsTextStyle:
                          Theme.of(context).textTheme.bodyLarge,
                      itemsTextStyle: Theme.of(context).textTheme.bodyLarge,
                      unselectedColor: Theme.of(context).highlightColor,
                      searchable: true,
                      separateSelectedItems: true,
                      onConfirm: (results) {
                        artistsResult = results;
                      },
                    )),
                Padding(
                  padding: const EdgeInsets.only(left: 15, right: 15, top: 15),
                  child: Text('Select tracks'),
                ),
                Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: MultiSelectDialogField(
                      items: _seed_tracks,
                      initialValue: tracksResult,
                      title: Text('Select up to 5 tracks'),
                      selectedColor: Theme.of(context).highlightColor,
                      buttonIcon: Icon(Icons.arrow_drop_down),
                      buttonText: Text('Choose tracks'),
                      selectedItemsTextStyle:
                          Theme.of(context).textTheme.bodyLarge,
                      itemsTextStyle: Theme.of(context).textTheme.bodyLarge,
                      unselectedColor: Theme.of(context).highlightColor,
                      searchable: true,
                      separateSelectedItems: true,
                      onConfirm: (results) {
                        tracksResult = results;
                      },
                    )),
                ElevatedButton(
                  onPressed: () {
                    print('Va a ejecutar getRecommendations!!');
                    getRecommendations(widget.userId!, genresResult,
                            artistsResult, tracksResult, limit)
                        .then((recommendationsResponse) {
                      if (handleResponse(recommendationsResponse,
                              widget.userId!, context) ==
                          ReturnCodes.SUCCESS) {
                        context.go(
                            '/users/${widget.userId}/get-recommendations/recommendations',
                            extra: recommendationsResponse.content);
                      }
                    });
                  },
                  child: Text('Submit'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
