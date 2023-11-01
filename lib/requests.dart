import 'dart:convert';
import 'dart:math';
import 'package:combined_playlist_maker/track.dart';
import 'package:combined_playlist_maker/user.dart';
import 'package:combined_playlist_maker/artist.dart';
import 'package:crypto/crypto.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart';
import 'package:url_launcher/url_launcher.dart';

const CLIENT_ID = '26cd2b5bfc8a431eb6b343e28ced0b6f';
const REDIRECT_URI =
    'https://miguelgarglez.github.io/start'; //'http://localhost:5000/start'; //default
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
Future<String> generateCodeChallenge(String codeVerifier) async {
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
  String? code;
  Uri uri;

  uri = Uri.base;

  code = uri.queryParameters['code'];

  return code;
}

Future<void> requestAuthorization() async {
  var codeVerifier = generateRandomString(128);

  var cvBox = Hive.box('codeVerifiers');
  var n = cvBox.length;
  await cvBox.put('cv$n', codeVerifier);

  String codeChallenge = await generateCodeChallenge(codeVerifier);

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
  if (auth.isEmpty) {
    return false;
  } else {
    return true;
  }
}

Future<String> getAccessToken() async {
  String? code;

  code = await obtainCurrentURLCode();

  var cvBox = Hive.box('codeVerifiers');
  var codeVerifier = await cvBox.get('cv${cvBox.length - 1}');

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

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      var atBox = Hive.box('tokens');
      var n = atBox.length;
      await atBox.put('at$n', data['access_token']);
      return data['access_token'];
    } else {
      print(json.decode(response.body));
      throw Exception('HTTP status ${response.statusCode} in getAccessToken');
    }
  } catch (error) {
    print('Error $error');
  }
  return '';
}

//funcion que se llama la primera vez que el usuario acepta la autorización de spotify
Future<User> retrieveSpotifyProfileInfo() async {
  var accessToken = await getAccessToken();
  print('accessToken: $accessToken');
  final Uri uri = Uri.parse('https://api.spotify.com/v1/me');
  User newUser;

  try {
    final response = await get(
      uri,
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      newUser = User.fromJson(data, accessToken);
      var usersBox = Hive.box<User>('users');
      await usersBox.put(data['id'], newUser);
      return newUser;
    } else {
      print(json.decode(response.body));
      throw Exception(
          'HTTP status ${response.statusCode} en retrieveSpotifyProfileInfo');
    }
  } catch (error) {
    print('Error: $error');
  }
  return User.notValid();
}

Future<List> getUsersTopItems(
    String userId, String type, String timeRange, double limit) async {
  var usersBox = Hive.box<User>('Users');
  User? user = usersBox.get(userId);
  var accessToken = user!.accessToken;

  List topItems = [];

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

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
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
    } else {
      print(json.decode(response.body));
      throw Exception('HTTP status ${response.statusCode} en getUsersTopItems');
    }
  } catch (error) {
    print('Error: $error');
  }
  return [];
}

Future<List> getRecommendations(String userId, List genreSeeds,
    List artistSeeds, List trackSeeds, double limit) async {
  var usersBox = Hive.box<User>('Users');
  User? user = usersBox.get(userId);
  var accessToken = user!.accessToken;

  List recommendations = [];

  final args = {
    'market': 'ES',
    'limit': limit.round().toString(),
    'seed_artists': artistSeeds,
    'seed_genres': genreSeeds,
    'seed_tracks': trackSeeds,
  };

  final Uri uri = Uri.https('api.spotify.com', '/v1/recommendations', args);
  print('Uri generada: ${uri}');
  try {
    final response = await get(
      uri,
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      for (var item in data['tracks']) {
        Track t = Track.fromJson(item);
        recommendations.add(t);
      }
      return recommendations;
    } else {
      print(json.decode(response.body));
      throw Exception(
          'HTTP status ${response.statusCode} in getRecommendations');
    }
  } catch (error) {
    print('Error: $error');
  }
  return [];
}

Future<List> getGenreSeeds(String userId) async {
  var usersBox = Hive.box<User>('Users');
  User? user = usersBox.get(userId);
  var accessToken = user!.accessToken;

  final Uri uri =
      Uri.https('api.spotify.com', '/v1/recommendations/available-genre-seeds');
  print('Uri generada: ${uri.path}');
  try {
    final response = await get(
      uri,
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['genres'];
    } else {
      print(json.decode(response.body));
      throw Exception('HTTP status ${response.statusCode} in getGenreSeeds');
    }
  } catch (error) {
    print('Error: $error');
  }
  return [];
}
