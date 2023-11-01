import 'package:combined_playlist_maker/forms.dart';
import 'package:combined_playlist_maker/landing.dart';
import 'package:combined_playlist_maker/main.dart';
import 'package:combined_playlist_maker/user.dart';
import 'package:go_router/go_router.dart';

GoRouter MyAppRoutes() {
  return GoRouter(initialLocation: '/start', routes: [
    GoRoute(
      name: 'home',
      path: '/start',
      builder: (context, state) => MyHomePage(),
      routes: [],
    ),
    /*GoRoute(
        name: 'welcome',
        path: '/welcome',
        builder: (context, state) => WelcomeScreen(),
        routes: []),*/
    GoRoute(
        name: 'users',
        path: '/users',
        builder: (context, state) => UsersDisplay(),
        routes: [
          GoRoute(
              name: 'user detail',
              path: ':id',
              builder: (context, state) {
                String? id = state.pathParameters['id'];
                return UserDetail(id: id);
              },
              routes: [
                // one for recommendations
                GoRoute(
                  name: 'get recommendations',
                  path: 'get-recommendations',
                  builder: (context, state) {
                    String? id = state.pathParameters['id'];
                    var options = state.extra as Map;
                    return GetRecommendations(
                      userId: id,
                      recommendationOptions: options,
                    );
                  },
                ),
                // another for top items
                GoRoute(
                  name: 'get top items',
                  path: 'get-top-items',
                  builder: (context, state) {
                    String? id = state.pathParameters['id'];
                    return GetTopItems(userId: id);
                  },
                ),
              ]),
        ]),
  ]);
}
