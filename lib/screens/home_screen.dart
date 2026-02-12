import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/common/primary_button.dart';
import '../widgets/common/secondary_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Material(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomCenter,
              colors: <Color>[
                Color(0xff0d47a1),
                Color(0xff1976d2),
                Color(0xff42a5f5),
              ],
              tileMode: TileMode.clamp,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 60),
                          child: SizedBox(
                            width: 200,
                            height: 200,
                            child: const Placeholder(color: Colors.white),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 24),
                        child: Text(
                          'AppName',
                          style: TextStyle(color: Colors.white, fontSize: 42),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      PrimaryButton(
                        text: 'Scan a QR code',
                        onPressed: () {},
                        icon: Icons.qr_code_scanner,
                        size: ButtonSize.L,
                      ),
                      const SizedBox(height: 20),
                      SecondaryButton(
                        text: 'Create a connection',
                        onPressed: () {
                          _onScanButtonPressed();
                        },
                        icon: Icons.people,
                        size: ButtonSize.L,
                      ),
                    ],
                  ),
                ),
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

  void _onScanButtonPressed() {
    context.push('/pairing');
  }
}
