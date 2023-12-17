import 'dart:math';

List mergeRecommendedTracksBasic(
    Map<String, List> recommendations, Duration totalDuration) {
  List mergedTracks = [];
  double currentDuration = 0;

  double probOfUsage = totalDuration.inMilliseconds /
      calculateTotalDuration(recommendations).inMilliseconds;

  double meanDuration = calculateTotalDuration(recommendations).inMilliseconds /
      recommendations.length;

  for (var tracks in recommendations.values) {
    for (var track in tracks) {
      if (currentDuration + track.durationMs <= totalDuration.inMilliseconds) {
        if (Random().nextDouble() <= probOfUsage) {
          mergedTracks.add(track);
          currentDuration += track.durationMs;
        }
      } else {
        break;
      }
    }
  }

  // ! Debugging
  print('Duracion que se pidio: ${totalDuration.inMilliseconds}');
  print('Duracion que se obtuvo: $currentDuration');
  print('Duracion promedio de las canciones: $meanDuration');
  print('Numero de tracks: ${mergedTracks.length}');

  // mergedTracks.shuffle();

  return mergedTracks;
}

Duration calculateTotalDuration(Map<String, List> recommendations) {
  double totalDuration = 0;

  for (var tracks in recommendations.values) {
    for (var track in tracks) {
      totalDuration += track.durationMs;
    }
  }

  return Duration(milliseconds: totalDuration.toInt());
}
