import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'game_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
    DeviceOrientation.portraitUp,
  ]);
  runApp(const BonfireGtaApp());
}

class BonfireGtaApp extends StatelessWidget {
  const BonfireGtaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bonfire GTA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: const GameScreen(),
    );
  }
}
