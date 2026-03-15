import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';

import 'package:altodevmobile/screens/home_screen.dart';
import 'package:altodevmobile/screens/pairing_screen.dart';
import 'package:altodevmobile/screens/relation_screen.dart';
import 'package:altodevmobile/screens/scanning_screen.dart';

// Entry point of the application
void main() async {
  // Ensure orientation is always portrait
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  // Run the application
  runApp(ProviderScope(child: const AltoApp()));
}

// The route configuration
final GoRouter _router = GoRouter(
  routes: <RouteBase>[
    GoRoute(
      // HomeScreen is the default route
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        return const HomeScreen();
      },
    ),
    GoRoute(
      // InitPairingScreen is the pairing screen
      path: '/pairing',
      builder: (BuildContext context, GoRouterState state) {
        return const InitPairingScreen();
      },
    ),
    GoRoute(
      // ScanPairingScreen is the scanning screen
      path: '/scan',
      builder: (BuildContext context, GoRouterState state) {
        return const ScanPairingScreen();
      },
    ),
    GoRoute(
      // RelationScreen is the relation screen
      path: '/relation',
      builder: (BuildContext context, GoRouterState state) {
        return const RelationScreen();
      },
    ),
  ],
);

// Root widget of the application
class AltoApp extends StatelessWidget {
  const AltoApp({super.key}); // Constructor

  // This widget is the root of the application
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false, // Removes the debug banner
      routerConfig: _router,
      title: 'Alto',
      theme: ThemeData(fontFamily: 'Patrick Hand'), // Sets the custom font
    );
  }
}
