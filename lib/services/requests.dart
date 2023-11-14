import 'dart:convert';
import 'dart:math';
import 'package:combined_playlist_maker/models/my_response.dart';
import 'package:combined_playlist_maker/models/track.dart';
import 'package:combined_playlist_maker/models/user.dart';
import 'package:combined_playlist_maker/models/artist.dart';
import 'package:crypto/crypto.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart';
import 'package:url_launcher/url_launcher.dart';

const CLIENT_ID = '26cd2b5bfc8a431eb6b343e28ced0b6f';
const REDIRECT_URI = 'http://localhost:5000/'; //default
const SCOPE = 'user-read-private user-read-email user-top-read';

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
      print(json.decode(response.body));
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
  print('accessToken (retrieveSpotifyProfileInfo): $tokenResponse');
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
      print(ret);
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
