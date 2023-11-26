import 'package:combined_playlist_maker/return_codes.dart';
import 'package:combined_playlist_maker/services/error_handling.dart';
import 'package:combined_playlist_maker/services/requests.dart';
import 'package:flutter/material.dart';
import 'package:duration_picker/duration_picker.dart';
import 'package:go_router/go_router.dart';

class GeneratePlaylistBasic extends StatefulWidget {
  @override
  _GeneratePlaylistBasicState createState() => _GeneratePlaylistBasicState();
}

class _GeneratePlaylistBasicState extends State<GeneratePlaylistBasic> {
  Duration _duration = Duration(hours: 0, minutes: 0);
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
                  generatePlaylistBasic(_duration).then((playlistResponse) {
                    if (handleResponseUI(playlistResponse, '', context) ==
                        ReturnCodes.SUCCESS) {
                      context.go('/users/generate-playlist-basic/playlist',
                          extra: playlistResponse.content);
                    }
                  });
                },
                child: Text('Generate playlist'),
              ),
            ),
          ],
        )))));
  }
}
