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
                  duration: _duration,
                  onChange: (val) {
                    setState(() {
                      _duration = val;
                    });
                  },
                  snapToMins: 5.0,
                )),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: ElevatedButton(
                onPressed: () {
                  if (validateDuration(_duration)) {
                    setState(() {
                      _loading = true;
                    });
                    generatePlaylistBasic(_duration).then((playlistResponse) {
                      setState(() {
                        _loading = false;
                      });
                      if (handleResponseUI(playlistResponse, '', context) ==
                          ReturnCodes.SUCCESS) {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PlaylistDisplay(
                                  items: playlistResponse.content,
                                  title: 'Your combined playlist'),
                            ));
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
