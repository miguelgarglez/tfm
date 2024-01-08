import 'dart:math';

import 'package:combined_playlist_maker/models/track.dart';

Map<String, Function> strategies = {
  'average': averageGroupRatings,
  'multiplicative': multiplicativeGroupRatings,
  'most_pleasure': mostPleasureGroupRatings,
  'least_pleasure': leastPleasureGroupRatings,
};

Map<String, List<dynamic>> generateRecommendedPlaylist(
    Map<String, List> recommendations,
    Duration playlistDuration,
    List<int> seedProp,
    String? type) {
  Map<String, Map<Track, dynamic>> groupRatings = {};
  Map<String, List<dynamic>> sortedTracks = {};
  Map<String, List<dynamic>> recommendation = {};
  if (strategies.containsKey(type)) {
    groupRatings[type!] =
        strategies[type]!(recommendations, playlistDuration, seedProp);
  } else {
    strategies.forEach((name, strategy) {
      groupRatings[name] =
          strategy(recommendations, playlistDuration, seedProp);
      sortedTracks[name] = sortedRecommendation(groupRatings[name]!);
      recommendation[name] =
          cutOrderedRecommendations(sortedTracks[name]!, playlistDuration);
    });
    return recommendation;
  }
  sortedTracks[type!] = sortedRecommendation(groupRatings[type]!);

  recommendation[type] =
      cutOrderedRecommendations(sortedTracks[type]!, playlistDuration);

  // ! Debugging
  print('Duracion que se pidio: ${playlistDuration}');
  print(
      'Duracion que se obtuvo: ${calculateTotalDuration(recommendation[type]!)}');
  print('Numero de tracks: ${recommendation.length}');

  return recommendation;
}

List cutOrderedRecommendations(
    List orderedRecommendations, Duration playlistDuration) {
  // * Here the key points to consider are:
  // * 1. The desired duration of the playlist
  // * 2. The duration of the songs being added
  // * 3. Not exceeding the duration by more than a 0.2 proportion
  // * Taking into account the duration of each song to be added, we will see by how much
  // * it exceeds the desired duration, and based on that, we will select the next one, because
  // * we also don't want the playlist to fall short by too much
  List cutRecommendations = [];
  int currentDuration = 0;
  int desiredDuration = playlistDuration
      .inMilliseconds; // because we have the track duration in Milliseconds

  for (Track track in orderedRecommendations) {
    if (currentDuration + track.durationMs <= desiredDuration) {
      cutRecommendations.add(track);
      currentDuration += track.durationMs;
    } else if (currentDuration + track.durationMs <
        desiredDuration + (desiredDuration * 0.2)) {
      // if the playlist duration IS NOT exceeded by more than 20% of the desired duration
      cutRecommendations.add(track);
      currentDuration += track.durationMs;
      break;
    } else if (currentDuration + track.durationMs >=
        desiredDuration + (desiredDuration * 0.2)) {
      // if the playlist duration IS exceeded by more than 20% of the desired duration
      // we don't add the track and continue with the next one
      continue;
    } else {
      break;
    }
  }

  return cutRecommendations;
}

/// Calculates the average ratings for each track in the recommendations based on the individual ratings.
///
/// The [recommendations] parameter is a map containing the recommendations for each track.
/// The [totalDuration] parameter is the total duration of the playlist.
/// The [seedProp] parameter is a list of integers representing the proportion of each seed type in the recommendations.
///
/// Returns a map containing the average ratings for each track.
Map<Track, dynamic> averageGroupRatings(Map<String, List> recommendations,
    Duration totalDuration, List<int> seedProp) {
  Map ratings = obtainIndividualRatings(recommendations, seedProp);

  Map<Track, dynamic> avgGroupRatings = ratings.map((track, ratingsList) {
    double averageRating =
        ratingsList.reduce((int a, int b) => a + b) / ratingsList.length;
    return MapEntry(track, averageRating);
  });

  return avgGroupRatings;
}

/// Calculates the multiplicative group ratings for a given set of recommendations.
///
/// The [recommendations] parameter is a map that contains the recommendations for each track.
/// The [totalDuration] parameter is the total duration of the playlist.
/// The [seedProp] parameter is a list of integers representing the proportion of each seed type in the recommendations.
///
/// Returns a map that contains the multiplicative group ratings for each track.
Map<Track, dynamic> multiplicativeGroupRatings(
    Map<String, List> recommendations,
    Duration totalDuration,
    List<int> seedProp) {
  Map ratings = obtainIndividualRatings(recommendations, seedProp);

  Map<Track, dynamic> multGroupRatings = ratings.map((track, ratingsList) {
    double multiplicationRating = ratingsList.reduce((int a, int b) => a * b);
    return MapEntry(track, multiplicationRating);
  });

  return multGroupRatings;
}

/// Calculates the most pleasure group ratings for a given set of recommendations.
///
/// The [recommendations] parameter is a map containing the recommendations for each track.
/// The [totalDuration] parameter is the total duration of the playlist.
/// The [seedProp] parameter is a list of integers representing the proportion of each seed type in the recommendations.
///
/// Returns a map containing the track and its corresponding maximum rating.
Map<Track, dynamic> mostPleasureGroupRatings(Map<String, List> recommendations,
    Duration totalDuration, List<int> seedProp) {
  Map ratings = obtainIndividualRatings(recommendations, seedProp);
  Map<Track, dynamic> mostGroupRatings = ratings.map((track, ratingsList) {
    double maxRating = ratingsList.reduce((int a, int b) => a > b ? a : b);
    return MapEntry(track, maxRating);
  });

  return mostGroupRatings;
}

/// Calculates the least pleasure group ratings for a given set of recommendations.
/// The [recommendations] parameter is a map containing the recommendations for each track.
/// The [totalDuration] parameter is the total duration of the playlist.
/// The [seedProp] parameter is a list of integers representing the proportion of each seed type in the recommendations.
/// Returns a map containing the track and its corresponding minimum rating.
Map<Track, dynamic> leastPleasureGroupRatings(Map<String, List> recommendations,
    Duration totalDuration, List<int> seedProp) {
  Map ratings = obtainIndividualRatings(recommendations, seedProp);
  Map<Track, dynamic> leastGroupRatings = ratings.map((track, ratingsList) {
    double minRating = ratingsList.reduce((int a, int b) => a < b ? a : b);
    return MapEntry(track, minRating);
  });

  return leastGroupRatings;
}

/// Sorts the tracks in the [groupRatings] map based on their ratings in descending order.
///
/// The [groupRatings] map should have the tracks as keys and their ratings as values.
/// Returns a list of tracks sorted in descending order based on their ratings.
List<Track> sortedRecommendation(Map<Track, dynamic> groupRatings) {
  List<Track> sortedTracks = groupRatings.keys.toList();
  sortedTracks.sort((a, b) => groupRatings[b].compareTo(groupRatings[a]));
  return sortedTracks;
}

/// Obtains individual ratings for each track in the recommendations.
///
/// Takes a map of recommendations, where the keys are user IDs and the values
/// are lists of tracks. Each track list represents a set of 100 recommended tracks
/// based on a specific seeds (artist, genre, or track), as 5 seeds are used, 20
/// tracks are generated from each seed. The ratings map will have
/// the Track object as the key and a list of ratings for each user as the value.
/// The rating is determined by the ranking at which the track was recommended.
///
/// - [recommendations]: A map of recommendations for each user.
/// - [seedProp]: A list of seed proportions for each seed type (artists, genres, tracks).
///
/// Returns a map of individual ratings for each track.
Map obtainIndividualRatings(
    Map<String, List> recommendations, List<int> seedProp) {
  Map ratings = {};
  // * habrá una lista de 100 canciones por cada usuario, las cuales se dividen
  // * en sets de 20 canciones (cada uno en base a una semilla)
  // * El mapa de ratings tendrá como clave el objeto Track de la canción
  // * y como valor tendrá una lista con el rating de la canción para cada usuario
  // * el rating será el ranking en que se ha recomendado
  // * la lista tendrá tantos ratings como usuarios, teniendo un valor de 1 si
  // * no se ha recomendado a ese usuario
  int userNum = 0;
  int totalUsers = recommendations.length;
  for (List trackList in recommendations.values) {
    int subtract = 0; // valor que se sustrae al valor de ranking invertido
    int setNumber = 0; // un factor para sustraer un extra en funcion de si son
    // recomendaciones basadas en un item top 1, 2, 3, 4 o 5
    int seedTypeIdx = 0; // 0 = artist, 1 = genre, 2 = track
    for (var trackPos = 0; trackPos < trackList.length; trackPos++) {
      Track track = trackList[trackPos];

      // ! reset when reaching a new set of 20 recommendations
      // ! calculation of the subtraction factor in case of multiple sets of recommendations
      // ! based on the same seed type (artist, genre, or track).
      if (trackPos % 20 == 0) {
        // cuando el set no es del tipo que se está examinando
        if (seedProp[seedTypeIdx] == 0) {
          seedTypeIdx += 1;
          setNumber = 0;
          // ya se ha pasado al tipo que corresponde y
          if (seedProp[seedTypeIdx] > 1 &&
              setNumber < seedProp[seedTypeIdx] - 1) {
            setNumber += 1;
          }
          // cuando se pasa al siguiente set de un mismo tipo que tiene más de 1 set
        } else if (seedProp[seedTypeIdx] > 1 &&
            setNumber < seedProp[seedTypeIdx] - 1) {
          setNumber += 1;
          // cuando el tipo solamente cuenta con un set
        } else {
          seedTypeIdx += 1;
          setNumber = 0;
        }
        subtract = 0;
      }
      // ! Cálculo del rating de la canción
      int trackRating = trackList.length - subtract - (5 * setNumber);
      // ! Añadir rating al Map de ratings
      if (ratings.containsKey(track)) {
        // el track ya se había recomendado a otro usuario
        // se añade el rating del usuario que corresponda
        ratings[track][userNum] = trackRating;
      } else {
        // el track ha sido analizado por primera vez entre las recomendaciones
        // todas las listas de ratings de cada track tendrán un rating de 1
        // de todos los usuarios
        ratings[track] = List.filled(totalUsers, 1);
        // se pone el valor correspondiente para el usuario pertinente
        ratings[track][userNum] = trackRating;
      }
      subtract += 1;
    }
    userNum += 1;
  }
  return ratings;
}

Duration calculateTotalDuration(List recommendations) {
  double totalDuration = 0;

  for (Track track in recommendations) {
    totalDuration += track.durationMs;
  }

  return Duration(milliseconds: totalDuration.toInt());
}
