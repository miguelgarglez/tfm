import 'dart:convert';
import 'package:combined_playlist_maker/screens/playlist_detail.dart';
import 'package:image_picker/image_picker.dart';
import 'package:combined_playlist_maker/models/user.dart';
import 'package:combined_playlist_maker/return_codes.dart';
import 'package:combined_playlist_maker/services/error_handling.dart';
import 'package:combined_playlist_maker/services/requests.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class SavePlaylist extends StatefulWidget {
  final List items;
  final String? userId;

  const SavePlaylist({super.key, required this.userId, required this.items});

  @override
  // ignore: library_private_types_in_public_api
  _SavePlaylistState createState() => _SavePlaylistState();
}

class _SavePlaylistState extends State<SavePlaylist> {
  String selectedUser = 'dummy';
  String playlistTitle = 'Título por defecto';
  String playlistDescription = 'Descripción por defecto';
  bool playlistVisibility = false;
  bool playlistCollaborative = false;
  List<User> users = [];

  bool _loading = false;

  // * Para seleccionar una imagen de la galería
  String playlistCover = '';
  String base64Cover = '';

  Future<void> initializeData() async {
    try {
      var usersBox = Hive.box<User>('users');
      users = usersBox.values.toList();
      users.insert(0, User.dummy());
    } catch (error) {
      throw Exception('Error initializing users on SavePlaylist');
    }

    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    initializeData();
  }

  Future<void> _pickImage() async {
    final pickedImage =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    final bytes = await pickedImage!.readAsBytes();

    setState(() {
      base64Cover = base64Encode(bytes);
      playlistCover = pickedImage.path;
    });
  }

  bool validatePlaylistData() {
    if (selectedUser == 'dummy' || selectedUser == '') {
      return false;
    }
    if (playlistTitle.isEmpty) {
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Save Playlist'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: Column(
              children: [
                DropdownButton<String>(
                  value: selectedUser,
                  onChanged: (String? newValue) {
                    setState(() {
                      print('Selected user: $newValue');
                      selectedUser = newValue!;
                    });
                  },
                  items: users.map<DropdownMenuItem<String>>((user) {
                    return DropdownMenuItem<String>(
                      value: user.id,
                      child: Row(
                        children: [
                          FadeInImage.assetNetwork(
                              placeholder: 'images/unknown_cover.png',
                              image: user.imageUrl,
                              imageErrorBuilder: (context, error, stackTrace) {
                                return Image.asset('images/unknown_cover.png');
                              }),
                          Container(
                              margin: EdgeInsets.only(left: 10),
                              child: Text(user.displayName)),
                        ],
                      ),
                    );
                  }).toList(),
                  hint: Text('Select a user to save the playlist'),
                ),
                SizedBox(height: 16.0),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Playlist\'s title',
                  ),
                  initialValue: playlistTitle,
                  onChanged: (value) {
                    setState(() {
                      if (value.isNotEmpty) {
                        playlistTitle = value;
                      }
                    });
                  },
                ),
                SizedBox(height: 16.0),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Playlist\'s description',
                  ),
                  initialValue: playlistDescription,
                  onChanged: (value) {
                    setState(() {
                      if (value.isNotEmpty) {
                        playlistDescription = value;
                      }
                    });
                  },
                ),
                SizedBox(height: 16.0),
                Padding(
                    padding: EdgeInsets.all(10),
                    child: Text(
                      'Will the playlist be collaborative?',
                      style: Theme.of(context).textTheme.labelLarge,
                    )),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Radio<bool>(
                      value: true,
                      groupValue: playlistCollaborative,
                      onChanged: (bool? value) {
                        setState(() {
                          playlistCollaborative = value!;
                        });
                      },
                    ),
                    Text('Yes'),
                    SizedBox(width: 16.0),
                    Radio<bool>(
                      value: false,
                      groupValue: playlistCollaborative,
                      onChanged: (bool? value) {
                        setState(() {
                          playlistCollaborative = value!;
                        });
                      },
                    ),
                    Text('No'),
                  ],
                ),
                SizedBox(height: 16.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: playlistCollaborative
                      ? [Text('Your playlist will be collaborative')]
                      : [
                          Radio<bool>(
                            value: true,
                            groupValue: playlistVisibility,
                            onChanged: (bool? value) {
                              setState(() {
                                playlistVisibility = value!;
                              });
                            },
                          ),
                          Text('Public'),
                          SizedBox(width: 16.0),
                          Radio<bool>(
                            value: false,
                            groupValue: playlistVisibility,
                            onChanged: (bool? value) {
                              setState(() {
                                playlistVisibility = value!;
                              });
                            },
                          ),
                          Text('Private'),
                        ],
                ),
                SizedBox(height: 16.0),
                Padding(
                    padding: EdgeInsets.all(10),
                    child: Text(
                      'Upload a cover for your playlist:',
                      style: Theme.of(context).textTheme.labelLarge,
                    )),
                IconButton(
                  onPressed: _pickImage,
                  icon: playlistCover != ''
                      ? Image.network(
                          playlistCover,
                          width: 60,
                          height: 60,
                        )
                      : Icon(Icons.image, size: 60),
                ),
                SizedBox(height: 16.0),
                ElevatedButton(
                  onPressed: () {
                    // Lógica para guardar la playlist

                    if (validatePlaylistData()) {
                      setState(() {
                        _loading = true;
                      });
                      savePlaylistToSpotify(
                              widget.items,
                              selectedUser,
                              playlistTitle,
                              playlistDescription,
                              playlistVisibility,
                              playlistCollaborative,
                              base64Cover)
                          .then((playlistResponse) {
                        setState(() {
                          _loading = false;
                        });
                        if (handleResponseUI(
                                playlistResponse, selectedUser, context) ==
                            ReturnCodes.SUCCESS) {
                          // TODO: Navigate to created playlist screen
                          // ! Debugging
                          print('Playlist created');
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PlaylistDetail(
                                  userId: selectedUser,
                                  playlistId: playlistResponse.content['id'],
                                  playlistCoverUrl: playlistCover,
                                ),
                              ));
                        }
                      });
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Please fill all the fields'),
                        ),
                      );
                    }
                  },
                  child: Text('Save playlist'),
                ),
                if (_loading)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
