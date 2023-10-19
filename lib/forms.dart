import 'package:combined_playlist_maker/main.dart';
import 'package:combined_playlist_maker/requests.dart';
import 'package:combined_playlist_maker/track.dart';
import 'package:combined_playlist_maker/user.dart';
import 'package:flutter/material.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';

class GetTopItems extends StatefulWidget {
  late User? user;

  GetTopItems({super.key, this.user});
  @override
  _GetTopItemsState createState() => _GetTopItemsState();
}

class _GetTopItemsState extends State<GetTopItems> {
  // Variables para los valores del formulario
  String type = 'Tracks';
  double limit = 25;
  String timeRange = 'medium_term';

  // Controladores para los campos de entrada
  final controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

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

  Row buildRadioTopType() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Radio(
          value: 'tracks',
          groupValue: type,
          onChanged: (value) {
            setState(() {
              type = value.toString();
            });
          },
        ),
        Text('Tracks'),
        Radio(
          value: 'artists',
          groupValue: type,
          onChanged: (value) {
            setState(() {
              type = value.toString();
            });
          },
        ),
        Text('Artists'),
      ],
    );
  }

  DropdownButtonFormField buildTimeFrameDropdown() {
    return DropdownButtonFormField(
      value: timeRange,
      items: ['short_term', 'medium_term', 'long_term'].map((time) {
        return DropdownMenuItem(value: time, child: Text(time));
      }).toList(),
      onChanged: (value) {
        setState(() {
          timeRange = value.toString();
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Adjust request parameters'),
      ),
      body: Form(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 15, right: 15, top: 15),
              child: Text('Top Tracks or Artists?'),
            ),
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: buildRadioTopType(),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 15, right: 15, top: 15),
              child: Text('What time frame?'),
            ),
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: buildTimeFrameDropdown(),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 15, right: 15, top: 15),
              child: Text('Limit the length of the ranking'),
            ),
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: buildLimitField(),
            ),
            ElevatedButton(
              onPressed: () {
                print('Va a ejecutar getUsersTopItems!!');
                getUsersTopItems(widget.user!.id, type, timeRange, limit)
                    .then((rankingList) => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: ((context) => ItemDisplay(
                                  items: rankingList,
                                )))));
              },
              child: Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}

class GetRecommendations extends StatefulWidget {
  late User? user;
  late List? genreOptions;

  GetRecommendations({super.key, this.user, this.genreOptions});
  @override
  _GetRecommendationsState createState() => _GetRecommendationsState();
}

class _GetRecommendationsState extends State<GetRecommendations> {
  // Variables para los valores del formulario
  //List seedArtists = [];
  //List seedTracks = [];
  List seedGenres = [];
  double limit = 25;

  // Controladores para los campos de entrada
  final controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

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
    final _items = widget.genreOptions!
        .map((genre) => MultiSelectItem(genre, genre))
        .toList();
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
                  items: _items,
                  initialValue: [],
                  title: Text('Select up to 5 genres'),
                  selectedColor: Colors.green,
                  buttonIcon: Icon(Icons.arrow_drop_down),
                  buttonText: Text('Choose music genres'),
                  onConfirm: (results) {
                    seedGenres = results;
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
                getRecommendations(widget.user!.id, seedGenres, limit)
                    .then((recommendationsList) => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: ((context) => ItemDisplay(
                                  items: recommendationsList,
                                )))));
              },
              child: Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
