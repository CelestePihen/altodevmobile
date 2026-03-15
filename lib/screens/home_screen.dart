import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/common/primary_button.dart';
import '../widgets/common/secondary_button.dart';

// HomeScreen class:
// StatefulWidget means it reacts to an user's taps/inputs
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key}); // Constructor

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// _HomeScreenState class:
// It holds the state of the HomeScreen
class _HomeScreenState extends State<HomeScreen> {
  // Constructor
  @override
  void initState() {
    super.initState();
  }

  // Destructor
  @override
  void dispose() {
    super.dispose();
  }

  // Build method:
  // It renders the HomeScreen
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Material(
        child: Container(
          // -- Background --
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            // -- Background gradient --
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomCenter,
              colors: <Color>[
                Color(0xff0d47a1),
                Color(0xff1976d2),
                Color(0xff42a5f5),
              ],
              tileMode: TileMode.clamp, // Repeat gradient colors
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // -- Header --
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      Center(
                        // -- Icon --
                        child: Padding(
                          padding: const EdgeInsets.only(top: 60),
                          child: SizedBox(
                            width: 200,
                            height: 200,
                            child: Image.asset('assets/icon/icon.png', fit: BoxFit.contain)
                          ),
                        ),
                      ),
                      Padding(
                        // -- Application name --
                        padding: const EdgeInsets.only(top: 24),
                        child: Text(
                          'Alto',
                          style: TextStyle(color: Colors.white, fontSize: 42),
                        ),
                      ),
                    ],
                  ),
                ),
                // -- Buttons --
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // -- Button 1 --
                      PrimaryButton(
                        text: 'Scan a QR code',
                        onPressed: () {
                          _onScanButtonPressed();
                        },
                        icon: Icons.qr_code_scanner,
                        size: ButtonSize.L,
                      ),
                      const SizedBox(height: 20),
                      // -- Button 2 --
                      SecondaryButton(
                        text: 'Create a connection',
                        onPressed: () {
                          _onConnectionButtonPressed();
                        },
                        icon: Icons.plus_one,
                        size: ButtonSize.L,
                      ),
                      const SizedBox(height: 20),
                      // -- Button 3 --
                      SecondaryButton(
                        text: 'Relations',
                        onPressed: () {
                          _onRelationsButtonPressed();
                        },
                        icon: Icons.people,
                        size: ButtonSize.L,
                      )
                    ],
                  ),
                ),
                // -- Footer --
                const Padding(
                  padding: EdgeInsets.only(bottom: 20),
                  child: Text(
                    'Version',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Navigation methods:
  /// These methods navigate the user to the corresponding screen.
  ///
  /// _onScanButtonPressed() is called when the user taps the "Scan a QR code" button.
  /// _onConnectionButtonPressed() is called when the user taps the "Create a connection" button.
  /// _onRelationsButtonPressed() is called when the user taps the "Relations" button.
  void _onScanButtonPressed() {
    context.push('/scan');
  }

  void _onConnectionButtonPressed() {
    context.push('/pairing');
  }

  void _onRelationsButtonPressed() {
    context.push('/relation');
  }
}
