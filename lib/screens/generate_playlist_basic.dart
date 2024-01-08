import 'package:combined_playlist_maker/return_codes.dart';
import 'package:combined_playlist_maker/screens/playlist_display.dart';
import 'package:combined_playlist_maker/services/error_handling.dart';
import 'package:combined_playlist_maker/services/requests.dart';
import 'package:flutter/material.dart';
import 'package:duration_picker/duration_picker.dart';

class GeneratePlaylistBasic extends StatefulWidget {
  @override
  _GeneratePlaylistBasicState createState() => _GeneratePlaylistBasicState();
}

class _GeneratePlaylistBasicState extends State<GeneratePlaylistBasic> {
  Duration _duration = Duration(hours: 0, minutes: 0);
  String? _aggregationStrategy;

  bool _loading = false;

  bool validateDuration(Duration duration) {
    if (duration.inMinutes < 5) {
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('Generate Playlist Basic')),
        body: SingleChildScrollView(
            child: Center(
                child: Form(
                    child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 15, right: 15, top: 15),
              child: Text('Indicate the duration of the playlist',
                  style: Theme.of(context).textTheme.bodyLarge),
            ),
            Padding(
                padding: const EdgeInsets.all(20.0),
                child: DurationPicker(
                  baseUnit: BaseUnit.minute,
                  duration: _duration,
                  onChange: (val) {
                    setState(() {
                      _duration = val;
                    });
                  },
                  snapToMins: 5.0,
                )),
            Padding(
              padding: const EdgeInsets.only(
                  left: 60, right: 60, top: 15, bottom: 15),
              child: DropdownButtonFormField(
                hint: Text('Select an aggregation strategy'),
                value: _aggregationStrategy,
                items: {
                  'average': 'Average',
                  'most_pleasure': 'Most Pleasure',
                  'least_pleasure': 'Least Pleasure',
                  'multiplicative': 'Multiplicative',
                  'all': 'Try all strategies and compare'
                }
                    .map((value, label) {
                      return MapEntry(
                          value,
                          DropdownMenuItem(
                              value: value, child: Center(child: Text(label))));
                    })
                    .values
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _aggregationStrategy = value.toString();
                  });
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: ElevatedButton(
                onPressed: () {
                  if (validateDuration(_duration)) {
                    setState(() {
                      _loading = true;
                    });
                    generateCombinedPlaylist(_duration, _aggregationStrategy)
                        .then((playlistResponse) {
                      setState(() {
                        _loading = false;
                      });
                      if (handleResponseUI(playlistResponse, '', context) ==
                          ReturnCodes.SUCCESS) {
                        if (playlistResponse.content.length == 1) {
                          // si solamente se ha generado playlist con una estrategia
                          // de agregación, se muestra directamente la playlist
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PlaylistDisplay(
                                    items: playlistResponse
                                        .content[_aggregationStrategy],
                                    title: 'Your combined playlist'),
                              ));
                        } else {
                          // si se han generado varias playlist, se muestrará además
                          // una barra de pestañas para mostrar las distintas playlist
                          // generadas con las diferentes estrategias de agregación
                          // TODO: implementar barra de pestañas dentro de PlaylistDisplay
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    PlaylistDisplay.multiplePlaylists(
                                        playlists: playlistResponse.content,
                                        title: 'See your playlists'),
                              ));
                        }
                      }
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text('The duration must be at least 5 minutes.'),
                      ),
                    );
                  }
                },
                child: Text('Generate playlist'),
              ),
            ),
            if (_loading)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircularProgressIndicator(),
              ),
          ],
        )))));
  }
}
