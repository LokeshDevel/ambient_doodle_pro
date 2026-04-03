import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'themes/app_theme.dart';
import 'widgets/canvas_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Firebase init failed (likely missing google-services.json): $e");
  }

  // Force full immersive mode — hide status/nav bars for pure canvas feel
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
  ));

  runApp(const AmbientDoodleApp());
}

class AmbientDoodleApp extends StatelessWidget {
  const AmbientDoodleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ambient Doodle',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const CanvasScreen(),
    );
  }
}
