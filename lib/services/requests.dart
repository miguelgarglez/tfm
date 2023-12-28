import 'dart:convert';
import 'dart:math';
import 'package:combined_playlist_maker/models/my_response.dart';
import 'package:combined_playlist_maker/models/playlist.dart';
import 'package:combined_playlist_maker/models/track.dart';
import 'package:combined_playlist_maker/models/user.dart';
import 'package:combined_playlist_maker/models/artist.dart';
import 'package:combined_playlist_maker/services/basic_recommendator.dart';
import 'package:crypto/crypto.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart';
import 'package:url_launcher/url_launcher.dart';

const CLIENT_ID = '26cd2b5bfc8a431eb6b343e28ced0b6f';
const REDIRECT_URI = 'http://localhost:5000/'; //default
const SCOPE =
    'user-read-private user-read-email user-top-read playlist-modify-public playlist-modify-private ugc-image-upload';

/*
 * Función que genera una cadena aleatoria
 */
String generateRandomString(int length) {
  final random = Random();
  const possible =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  String text = '';

  for (int i = 0; i < length; i++) {
    text += possible[random.nextInt(possible.length)];
  }

  return text;
}

/**
 * Función que genera 
 */
String generateCodeChallenge(String codeVerifier) {
  var data = ascii.encode(codeVerifier);
  // Calcula el hash SHA-256 de la secuencia de bytes del código de verificación
  var hash = sha256.convert(data);

  // Convierte el hash en una cadena Base64 URL-encoded
  String base64UrlEncoded = base64Url
      .encode(hash.bytes)
      .replaceAll("=", "")
      .replaceAll("+", "-")
      .replaceAll("/", "_");

  return base64UrlEncoded;
}

dynamic obtainCurrentURLCode() async {
  String? code = '';
  Uri uri;

  uri = Uri.base;

  code = uri.queryParameters['code'];

  return code;
}

Future<void> requestAuthorization() async {
  var codeVerifier = generateRandomString(128);

  // guardamos el codeVerifier para el proceso de autenticación
  // después lo guardaré con el usuario
  var cvBox = Hive.box('codeVerifiers');
  var n = cvBox.length;
  await cvBox.put('cv$n', codeVerifier);

  String codeChallenge = generateCodeChallenge(codeVerifier);

  String state = generateRandomString(16);

  final args = {
    'response_type': 'code',
    'client_id': CLIENT_ID,
    'scope': SCOPE,
    'redirect_uri': REDIRECT_URI,
    'state': state,
    'code_challenge_method': 'S256',
    'code_challenge': codeChallenge,
  };

  final authorizationUrl =
      Uri.https('accounts.spotify.com', '/authorize', args);

  if (await canLaunchUrl(authorizationUrl)) {
    await launchUrl(authorizationUrl, webOnlyWindowName: '_self');
  } else {
    throw 'Could not launch $authorizationUrl';
  }
}

bool isAuthenticated() {
  //auth es una caja de Hive que simplemente guarda un booleano
  var auth = Hive.box('auth').toMap();
  var users = Hive.box<User>('users').toMap();
  if (auth.isEmpty && users.isEmpty) {
    return false;
  } else {
    return true;
  }
}

Future<MyResponse> getAccessToken() async {
  String? code;

  MyResponse ret = MyResponse();

  //obtengo el codigo de la url y lo guardo
  code = await obtainCurrentURLCode();

  var cvBox = Hive.box('codeVerifiers');
  var codeVerifier = await cvBox.get('cv${cvBox.length - 1}');
  cvBox.clear();
  if (codeVerifier == null) {
    // no hay un codeVerifier, asi que va a dar error, cortamos ejecución
    ret.content = {};
    return ret;
  }
  final body = {
    'grant_type': 'authorization_code',
    'code': code,
    'redirect_uri': REDIRECT_URI,
    'client_id': CLIENT_ID,
    'code_verifier': codeVerifier,
  };

  try {
    final response = await post(
      Uri.parse('https://accounts.spotify.com/api/token'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: body,
    );

    ret.statusCode = response.statusCode;
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      ret.content = data;
      return ret;
    } else {
      ret.content = {};
      throw Exception('HTTP status ${response.statusCode} in getAccessToken');
    }
  } catch (error) {
    print('Error $error (getAccessToken)');
    return ret;
  }
}

//funcion que se llama la primera vez que el usuario acepta la autorización de spotify
Future<MyResponse> retrieveSpotifyProfileInfo() async {
  MyResponse ret = MyResponse();
  MyResponse tokenResponse = await getAccessToken();
  if (tokenResponse.statusCode != 200) {
    //no se ha llegado a hacer la petición porque el token
    //no se ha obtenido correctamente
    ret.content = User.notValid();
    return ret;
  }

  final Uri uri = Uri.parse('https://api.spotify.com/v1/me');
  User newUser;

  try {
    final response = await get(
      uri,
      headers: {
        'Authorization': 'Bearer ${tokenResponse.content['access_token']}'
      },
    );
    ret.statusCode = response.statusCode;
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      newUser = User.fromJson(data, tokenResponse.content['access_token'],
          tokenResponse.content['refresh_token']);
      var usersBox = Hive.box<User>('users');
      await usersBox.put(newUser.id, newUser);
      ret.content = newUser;
      return ret;
    } else {
      print(json.decode(response.body));
      ret.content = User.notValid();
      throw Exception(
          'HTTP status ${response.statusCode} en retrieveSpotifyProfileInfo');
    }
  } catch (error) {
    print('Error: $error');
    return ret;
  }
}

Future<MyResponse> getUsersTopItems(
    String userId, String type, String timeRange, double limit) async {
  var usersBox = Hive.box<User>('Users');
  User? user = usersBox.get(userId);
  var accessToken = user!.accessToken;

  MyResponse ret = MyResponse();

  final args = {
    'time_range': timeRange,
    'limit': limit.round().toString(),
  };

  final Uri uri = Uri.https('api.spotify.com', '/v1/me/top/$type', args);
  try {
    final response = await get(
      uri,
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    ret.statusCode = response.statusCode;
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      ret.content = parseItemData(data, type);
      return ret;
    } else {
      ret.content = [];
      throw Exception('HTTP status ${response.statusCode} en getUsersTopItems');
    }
  } catch (error) {
    print(ret);
    print('Error: $error');
    return ret;
  }
}

List parseItemData(data, type) {
  List topItems = [];
  if (type == 'artists') {
    for (var item in data['items']) {
      Artist a = Artist.fromJson(item);
      topItems.add(a);
    }
  } else {
    for (var item in data['items']) {
      Track a = Track.fromJson(item);
      topItems.add(a);
    }
  }
  return topItems;
}

Future<MyResponse> getRecommendations(String userId, List? genreSeeds,
    List? artistSeeds, List? trackSeeds, double limit) async {
  var usersBox = Hive.box<User>('Users');
  User? user = usersBox.get(userId);
  var accessToken = user!.accessToken;

  MyResponse ret = MyResponse();
  List recommendations = [];

  final args = {
    'market': 'ES',
    'limit': limit.round().toString(),
    'seed_artists': artistSeeds,
    'seed_genres': genreSeeds,
    'seed_tracks': trackSeeds,
  };

  final Uri uri = Uri.https('api.spotify.com', '/v1/recommendations', args);
  try {
    final response = await get(
      uri,
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    ret.statusCode = response.statusCode;
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      for (var item in data['tracks']) {
        Track t = Track.fromJson(item);
        recommendations.add(t);
      }
      ret.content = recommendations;
      return ret;
    } else {
      ret.content = [];
      print(json.decode(response.body));
      throw Exception(
          'HTTP status ${response.statusCode} in getRecommendations');
    }
  } catch (error) {
    print('Error: $error');
    return ret;
  }
}

Future<MyResponse> getGenreSeeds(String userId) async {
  var usersBox = Hive.box<User>('Users');
  User? user = usersBox.get(userId);
  var accessToken = user!.accessToken;

  MyResponse ret = MyResponse();

  final Uri uri =
      Uri.https('api.spotify.com', '/v1/recommendations/available-genre-seeds');

  try {
    final response = await get(
      uri,
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    ret.statusCode = response.statusCode;
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      ret.content = data['genres'];
      return ret;
    } else {
      print(json.decode(response.body));
      throw Exception('HTTP status ${response.statusCode} in getGenreSeeds');
    }
  } catch (error) {
    ret.content = [];
    print('Error: $error');
  }
  return ret;
}

Future<MyResponse> refreshToken(userId) async {
  MyResponse ret = MyResponse();

  //obtengo el codigo de la url y lo guardo
  var usersBox = Hive.box<User>('users');
  User? u = usersBox.get(userId);

  final body = {
    'grant_type': 'refresh_token',
    'refresh_token': u!.refreshToken,
    'client_id': CLIENT_ID,
  };

  try {
    final response = await post(
      Uri.parse('https://accounts.spotify.com/api/token'),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: body,
    );

    ret.statusCode = response.statusCode;
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      ret.content = data;
      return ret;
    } else {
      print(json.decode(response.body));
      ret.content = {};
      throw Exception('HTTP status ${response.statusCode} in refreshToken');
    }
  } catch (error) {
    print('Error $error');
    print(ret);
    return ret;
  }
}

Future<MyResponse> generatePlaylistBasic(Duration duration) async {
  MyResponse ret = MyResponse();

  var usersBox = Hive.box<User>('users').toMap();

  Map<String, List> recommendations = {};

  for (var user in usersBox.values) {
    user.updateToken(); // actualizo el token del usuario
    var userId = user.id;

    // obtengo los items top del usuario
    MyResponse topTracks =
        await getUsersTopItems(userId, 'tracks', 'short_term', 3);
    if (topTracks.statusCode != 200) {
      ret.content = {'error': 'error retrieving top tracks'};
      ret.statusCode = topTracks.statusCode;
      return ret;
    }
    List? trackSeeds = topTracks.content.map((track) => track.id).toList();

    MyResponse topArtists =
        await getUsersTopItems(userId, 'artists', 'short_term', 2);
    if (topArtists.statusCode != 200) {
      ret.content = {'error': 'error retrieving top artists'};
      ret.statusCode = topArtists.statusCode;
      return ret;
    }
    List? artistSeeds = topArtists.content.map((artist) => artist.id).toList();

    MyResponse userRecommendations =
        await getRecommendations(userId, [], artistSeeds, trackSeeds, 100);
    if (userRecommendations.statusCode != 200) {
      ret.content = {'error': 'error retrieving recommendations'};
      ret.statusCode = userRecommendations.statusCode;
      return ret;
    }
    ret.statusCode = userRecommendations.statusCode;

    recommendations[userId] = userRecommendations.content;
  }

  List playlist = mergeRecommendedTracksBasic(recommendations, duration);

  ret.content = playlist;

  return ret;
}

Future<MyResponse> savePlaylistToSpotify(
    List items,
    String userId,
    String name,
    String description,
    bool isPublic,
    bool isCollaborative,
    String coverImage) async {
  MyResponse ret = MyResponse();

  String playlistId = '';

  MyResponse creationResponse = await createPlaylistOnSpotify(
      userId, name, description, isPublic, isCollaborative);
  if (creationResponse.statusCode == 201) {
    // playlist created successfully

    playlistId = creationResponse.content['id'];
    if (coverImage != '') {
      await uploadCoverImage(userId, playlistId, coverImage);
    }
    MyResponse addTracksResponse = await addTracksToPlaylist(
        userId, creationResponse.content['id'], items);
    if (addTracksResponse.statusCode == 201) {
      // tracks added successfully
      ret.statusCode = 201;
      ret.content = creationResponse.content;
      // ! Debugging
      print(ret.content);
    } else {
      // error adding tracks
      ret.statusCode = addTracksResponse.statusCode;
      ret.content = addTracksResponse.content;
    }
  } else {
    // error creating playlist
    ret.statusCode = creationResponse.statusCode;
    ret.content = creationResponse.content;
  }

  return ret;
}

Future<MyResponse> uploadCoverImage(
    String userId, String playlistId, String coverImage) async {
  var usersBox = Hive.box<User>('Users');
  User? user = usersBox.get(userId);
  var accessToken = user!.accessToken;

  MyResponse ret = MyResponse();

  try {
    final response = await put(
      Uri.parse('https://api.spotify.com/v1/playlists/$playlistId/images'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'image/jpeg',
      },
      body: coverImage,
    );
    ret.statusCode = response.statusCode;
    if (response.statusCode == 202) {
      ret.content = 'Cover Uploaded Successfully'; // * No content
      // ! Debugging
      print(ret);
      return ret;
    } else {
      print(json.decode(response.body));
      ret.content = {};
      throw Exception('HTTP status ${response.statusCode} in uploadCoverImage');
    }
  } catch (error) {
    print('Error $error');
    print(ret);
    return ret;
  }
}

/*
RESPUESTA DE LA API AL CREAR UNA PLAYLIST
{
  collaborative: false,
  description: Descripción por defecto,
  external_urls: {
    spotify: https://open.spotify.com/playlist/49lLX3rKW2GM7tgIb876ze
  },
  followers: {
    href: null,
    total: 0
  },
  href: https://api.spotify.com/v1/playlists/49lLX3rKW2GM7tgIb876ze,
  id: 49lLX3rKW2GM7tgIb876ze,
  images: [],
  name: Título por defecto,
  owner: {
    display_name: Miguel García,
    external_urls: {
      spotify: https://open.spotify.com/user/miguuels
    },
    href: https://api.spotify.com/v1/users/miguuels,
    id: miguuels,
    type: user,
    uri: spotify:user:miguuels
  },
  primary_color: null,
  public: false,
  snapshot_id: MSwxNjZkZTRmODlkYzVhY2M5NTU2OWU5YjMxMGM0NjZiMDkzN2VkZWRm,
  tracks: {
    href: https://api.spotify.com/v1/playlists/49lLX3rKW2GM7tgIb876ze/tracks,
    items: [],
    limit: 100,
    next: null,
    offset: 0,
    previous: null,
    total: 0
  },
  type: playlist,
  uri: spotify:playlist:49lLX3rKW2GM7tgIb876ze
}
 */

Future<MyResponse> createPlaylistOnSpotify(String userId, String name,
    String description, bool isPublic, bool isCollaborative) async {
  MyResponse ret = MyResponse();
  var usersBox = Hive.box<User>('Users');
  User? user = usersBox.get(userId);
  var accessToken = user!.accessToken;

  // * importante hacer json.encode para que el body sea un string
  final body = json.encode({
    "name": name,
    "description": description,
    "public": isCollaborative ? false : isPublic,
    "collaborative": isCollaborative,
  });

  try {
    final response = await post(
      Uri.parse('https://api.spotify.com/v1/users/$userId/playlists'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: body,
    );
    ret.statusCode = response.statusCode;
    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      ret.content = data;
      print(ret.statusCode);
      return ret;
    } else {
      print(json.decode(response.body));
      ret.content = {};
      throw Exception(
          'HTTP status ${response.statusCode} in createPlaylistOnSpotify');
    }
  } catch (error) {
    print('Error $error');
    print(ret);
    return ret;
  }
}

Future<MyResponse> addTracksToPlaylist(
    String userId, String playlistId, List tracks) async {
  MyResponse ret = MyResponse();
  var usersBox = Hive.box<User>('Users');
  User? user = usersBox.get(userId);
  var accessToken = user!.accessToken;

  // * importante hacer json.encode para que el body sea un string
  final body = json.encode({
    "uris": tracks.map((e) => 'spotify:track:${e.id}').toList(),
  });

  try {
    final response = await post(
      Uri.parse('https://api.spotify.com/v1/playlists/$playlistId/tracks'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    ret.statusCode = response.statusCode;
    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      ret.content = data;
      return ret;
    } else {
      print(json.decode(response.body));
      ret.content = {};
      throw Exception(
          'HTTP status ${response.statusCode} in addTracksToPlaylist');
    }
  } catch (error) {
    print('Error $error');
    return ret;
  }
}

Future<MyResponse> getPlaylist(String playlistId, String userId) async {
  MyResponse ret = MyResponse();
  var usersBox = Hive.box<User>('Users');
  User? user = usersBox.get(userId);
  var accessToken = user!.accessToken;

  try {
    final response = await get(
      Uri.parse('https://api.spotify.com/v1/playlists/$playlistId'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    ret.statusCode = response.statusCode;
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      ret.content = Playlist.fromJson(data);
      return ret;
    } else {
      print(json.decode(response.body));
      ret.content = {};
      throw Exception('HTTP status ${response.statusCode} in getPlaylist');
    }
  } catch (error) {
    print('Error $error');
    return ret;
  }
}
