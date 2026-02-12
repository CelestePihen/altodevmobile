import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:altodevmobile/screens/home_screen.dart';
import 'package:altodevmobile/screens/pairing_screen.dart';

void main() {
  runApp(ProviderScope(child: const AltoApp()));
}

// The route configuration
final GoRouter _router = GoRouter(
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        return const HomeScreen();
      },
    ),
    GoRoute(
      path: '/pairing',
      builder: (BuildContext context, GoRouterState state) {
        return const InitPairingScreen();
      },
    ),
  ],
);

class AltoApp extends StatelessWidget {
  const AltoApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
        debugShowCheckedModeBanner: false,
        routerConfig: _router
    );
  }
}
