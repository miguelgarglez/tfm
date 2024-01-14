import 'package:combined_playlist_maker/return_codes.dart';
import 'package:csv/csv.dart';

import 'package:combined_playlist_maker/models/my_response.dart';
import 'package:combined_playlist_maker/models/track.dart';
import 'package:combined_playlist_maker/services/requests.dart';

Map<String, Function> strategies = {
  'average': averageGroupRatings,
  'multiplicative': multiplicativeGroupRatings,
  'most_pleasure': mostPleasureGroupRatings,
  'least_misery': leastMiseryGroupRatings,
  'borda': bordaGroupRatings,
  'average_custom': averageCustomGroupRatings,
};

/// Generates a recommended playlist based on the given recommendations, playlist duration, seed proportions, and type.
///
/// The [recommendations] parameter is a map containing recommendations for each type of track.
/// The [playlistDuration] parameter specifies the desired duration of the playlist.
/// The [seedProp] parameter is a list of seed proportions for each type of track.
/// The [type] parameter specifies the type of track to generate recommendations for.
///
/// Returns a map containing the generated recommended playlist for each type of track.
Map<String, List<dynamic>> generateRecommendedPlaylist(
    Map<String, List> recommendations,
    Duration playlistDuration,
    List<int> seedProp,
    String? type) {
  Map<String, Map<Track, dynamic>> groupRatings = {};
  Map<String, List<dynamic>> sortedTracks = {};
  Map<String, List<dynamic>> recommendation = {};
  // obtain individual ratings for each track in the recommendations
  Map<Track, List<double>> ratings =
      obtainIndividualRatings(recommendations, seedProp);
  if (strategies.containsKey(type)) {
    groupRatings[type!] = strategies[type]!(recommendations, ratings);
  } else {
    strategies.forEach((name, strategy) {
      groupRatings[name] = strategy(recommendations, ratings);
      // ! Debugging
      /*print('RANKING ${name}:');
      print('${sortedMapRecommendation(groupRatings[name]!)}');*/
      sortedTracks[name] = sortedRecommendation(groupRatings[name]!);
      recommendation[name] =
          cutOrderedRecommendations(sortedTracks[name]!, playlistDuration);
    });
    return recommendation;
  }
  sortedTracks[type] = sortedRecommendation(groupRatings[type]!);

  // ! Debugging
  /*print('RANKING:');
  print('${sortedMapRecommendation(groupRatings[type]!)}');*/

  recommendation[type] =
      cutOrderedRecommendations(sortedTracks[type]!, playlistDuration);

  // ! Debugging
  /*print('Duracion que se pidio: ${playlistDuration}');
  print(
      'Duracion que se obtuvo: ${calculateTotalDuration(recommendation[type]!)}');
  print('Numero de tracks: ${recommendation[type]!.length}');*/

  return recommendation;
}

/// Cuts and orders a list of recommendations based on a desired playlist duration.
///
/// The function takes in a [List] of [Track] objects [orderedRecommendations] and a [Duration]
/// [playlistDuration] representing the desired duration of the playlist.
///
/// The function iterates through the [orderedRecommendations] list and adds tracks to the
/// [cutRecommendations] list based on the following criteria:
/// 1. If adding the track does not exceed the [playlistDuration], it is added to the list.
/// 2. If adding the track exceeds the [playlistDuration] by no more than 20%, it is added to
///    the list and the loop is terminated.
/// 3. If adding the track exceeds the [playlistDuration] by more than 20%, it is skipped and
///    the loop continues with the next track.
///
/// The function returns the [cutRecommendations] list containing the selected tracks.
List cutOrderedRecommendations(
    List orderedRecommendations, Duration playlistDuration) {
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

/// Calculates the average of the ratings that are non-zero for each track in the recommendations.
///
/// The [recommendations] parameter is a map containing the recommendations for each track.
/// The [totalDuration] parameter is the total duration of the playlist.
/// The [seedProp] parameter is a list of integers representing the proportion of each seed type in the recommendations.
///
/// Returns a map containing the average ratings for each track.
Map<Track, double> averageGroupRatings(
    Map<String, List> recommendations, Map<Track, List<double>> ratings) {
  Map<Track, double> avgGroupRatings = ratings.map((track, ratingsList) {
    double averageRating = ratingsList.reduce((double a, double b) => a + b) /
        ratingsList
            .where((rating) => rating != 0)
            .length; // Just taking non-zero ratings

    return MapEntry(track, averageRating);
  });

  return avgGroupRatings;
}

/// Calculates the average of the ratings for each track in the recommendations.
///
/// The [recommendations] parameter is a map containing the recommendations for each track.
/// The [totalDuration] parameter is the total duration of the playlist.
/// The [seedProp] parameter is a list of integers representing the proportion of each seed type in the recommendations.
///
/// Returns a map containing the average ratings for each track.
Map<Track, double> averageCustomGroupRatings(
    Map<String, List> recommendations, Map<Track, List<double>> ratings) {
  Map<Track, double> avgGroupRatings = ratings.map((track, ratingsList) {
    double averageRating =
        ratingsList.reduce((double a, double b) => a + b) / ratingsList.length;

    return MapEntry(track, averageRating);
  });

  return avgGroupRatings;
}

/// Calculates the sum of the ratings ratings for each track in the recommendations based on the individual ratings.
///
/// The [recommendations] parameter is a map containing the recommendations for each track.
/// The [totalDuration] parameter is the total duration of the playlist.
/// The [seedProp] parameter is a list of integers representing the proportion of each seed type in the recommendations.
///
/// Returns a map containing the average ratings for each track.
Map<Track, double> bordaGroupRatings(
    Map<String, List> recommendations, Map<Track, List<double>> ratings) {
  Map<Track, double> avgGroupRatings = ratings.map((track, ratingsList) {
    double averageRating = ratingsList.reduce((double a, double b) => a + b);

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
Map<Track, double> multiplicativeGroupRatings(
    Map<String, List> recommendations, Map<Track, List<double>> ratings) {
  Map<Track, double> multGroupRatings = ratings.map((track, ratingsList) {
    double multiplicationRating = ratingsList
        .where((rating) => rating != 0)
        .reduce((double a, double b) => a * b);
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
Map<Track, double> mostPleasureGroupRatings(
    Map<String, List> recommendations, Map<Track, List<double>> ratings) {
  Map<Track, double> mostGroupRatings = ratings.map((track, ratingsList) {
    double maxRating =
        ratingsList.reduce((double a, double b) => a > b ? a : b);
    return MapEntry(track, maxRating);
  });

  return mostGroupRatings;
}

/// Calculates the least pleasure group ratings for a given set of recommendations.
/// The [recommendations] parameter is a map containing the recommendations for each track.
/// The [totalDuration] parameter is the total duration of the playlist.
/// The [seedProp] parameter is a list of integers representing the proportion of each seed type in the recommendations.
/// Returns a map containing the track and its corresponding minimum rating.
Map<Track, double> leastMiseryGroupRatings(
    Map<String, List> recommendations, Map<Track, List<double>> ratings) {
  Map<Track, double> leastGroupRatings = ratings.map((track, ratingsList) {
    double minRating = ratingsList
        .where((rating) => rating != 0)
        .reduce((double a, double b) => a < b ? a : b);
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
  sortedTracks.sort((a, b) {
    int c = groupRatings[b].compareTo(groupRatings[a]);
    // in case of draw in rating, sort alphabetically
    if (c == 0) {
      return a.name.compareTo(b.name);
    } else {
      return c;
    }
  });
  return sortedTracks;
}

/// Sorts a map of track ratings in descending order based on their values.
///
/// The [groupRatings] parameter is a map where the keys are tracks and the values are ratings.
/// Returns a new map with the entries sorted in descending order based on the ratings.
Map<String, dynamic> sortedMapRecommendation(Map<Track, dynamic> groupRatings) {
  List<MapEntry<String, dynamic>> sortedEntries = groupRatings.entries
      .map((entry) => MapEntry(entry.key.name, entry.value))
      .toList();
  sortedEntries.sort((a, b) => b.value.compareTo(a.value));
  return Map.fromEntries(sortedEntries);
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
Map<Track, List<double>> obtainIndividualRatings(
    Map<String, List> recommendations, List<int> seedProp) {
  Map<Track, List<double>> ratings = {};
  int userNum = 0;
  int totalUsers = recommendations.length;
  List<String> trackIds = [];

  for (List trackList in recommendations.values) {
    double subtract = 0; // valor que se sustrae al valor de ranking invertido
    for (var trackPos = 0; trackPos < trackList.length; trackPos++) {
      Track track = trackList[trackPos];

      // ! Calculate track's rating
      double trackRating = trackList.length - subtract; // - (5 * setNumber);
      // ! Add rating to ratings map
      if (trackIds.contains(track.id)) {
        // el track ya se había recomendado a otro usuario
        // se añade el rating del usuario que corresponda
        ratings[track]![userNum] = trackRating;
      } else {
        // el track ha sido analizado por primera vez entre las recomendaciones
        // todas las listas de ratings de cada track tendrán un rating de 1
        // de todos los usuarios
        ratings[track] = List.filled(totalUsers, 0);
        // se pone el valor correspondiente para el usuario pertinente
        ratings[track]![userNum] = trackRating;
        trackIds.add(track.id);
      }
      subtract += 1;
    }
    userNum += 1;
  }

  // calculate percentage of coincidence between users recommendations
  // if there is no coincidence, the number of entries in the ratings Map
  // will be equal to the number of users times 100, which is the
  // number of recommendations generated for each user (totalUsers * 100)
  // if there is coincidence, the number of entries will be less than that
  // because the same track will be recommended to more than one user
  //double coincidence = (((totalUsers * 100) / ratings.length) - 1.0) * 100;
  // ! Debugging
  // print('Coincidence between users recommendations: ${coincidence}%');
  /*print('RATINGS:');
  for (var track in ratings.entries) {
    print('${track.key.name}: ${track.value}');
  }*/

  return ratings;
}

/// Calculates the total duration of a list of recommendations.
///
/// The function takes a list of recommendations and iterates through each track,
/// summing up their durations in milliseconds. The total duration is then converted
/// to a [Duration] object and returned.
///
/// Parameters:
/// - `recommendations`: A list of tracks to calculate the total duration for.
///
/// Returns:
/// - A [Duration] object representing the total duration of the recommendations.
Duration calculateTotalDuration(List recommendations) {
  double totalDuration = 0;

  for (Track track in recommendations) {
    totalDuration += track.durationMs;
  }

  return Duration(milliseconds: totalDuration.toInt());
}
