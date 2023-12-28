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

// seedProp --> 1º artists [0], 2º genres [1], 3º tracks [2]
Map obtainRatings(Map<String, List> recommendations, List<int> seedProp) {
  Map ratings = {};
  // * habrá una lista de 100 canciones por cada usuario, las cuales se dividen
  // * en sets de 20 canciones (cada uno en base a una semilla)
  // * El mapa de ratings tendrá como clave el id de la canción
  // * y como valor tendrá una lista con el rating de la canción para cada usuario
  // * el rating será el ranking en que se ha recomendado
  // * la lista tendrá uno o más ratings, dependiendo de si se ha repetido en la
  // * recomendación de otros usuarios
  for (var trackList in recommendations.values) {
    // ! IDEA: dividir las recomendaciones directamente en sets de 20
    // ! IDEA: o dividir en sets del tamaño dependiendo de la proporcion de semillas
    int subtract = 0; // valor que se sustrae al valor de ranking invertido
    int setNumber = 0; // un factor para sustraer un extra en funcion de si son
    // recomendaciones basadas en un item top 1, 2, 3, 4 o 5
    int seedTypeIdx = 0; // 0 = artist, 1 = genre, 2 = track
    for (var trackPos = 0; trackPos < trackList.length; trackPos++) {
      String track = trackList[trackPos];

      // ! reinicio cuando se llega a un nuevo set de 20 recomendaciones
      // ! calculo del factor de resta en caso de varios sets de recomendaciones
      // ! a partir del mismo tipo de semilla.
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
      if (ratings.containsKey(track)) {
        // track was present on other user's recommendations
        ratings[track].add(trackRating);
      } else {
        // track was not present on other user's recommendations yet
        ratings[track] = [trackRating];
      }
      subtract += 1;
    }
  }
  return ratings;
}
