import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'themes/app_theme.dart';
import 'widgets/canvas_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AmbientDoodleApp());
}

class AmbientDoodleApp extends StatelessWidget {
  const AmbientDoodleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ambient Doodle Pro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const _AppBootstrapScreen(),
    );
  }
}

class _AppBootstrapScreen extends StatefulWidget {
  const _AppBootstrapScreen();

  @override
  State<_AppBootstrapScreen> createState() => _AppBootstrapScreenState();
}

class _AppBootstrapScreenState extends State<_AppBootstrapScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loadingController;
  late final Future<void> _startupFuture;

  @override
  void initState() {
    super.initState();
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _startupFuture = _initializeApp();
  }

  Future<void> _initializeApp() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ));

    try {
      await Firebase.initializeApp();
    } catch (e) {
      debugPrint("Firebase init failed (likely missing google-services.json): $e");
    }
  }

  @override
  void dispose() {
    _loadingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _startupFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return const CanvasScreen();
        }

        return Scaffold(
          backgroundColor: const Color(0xFF070A10),
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _loadingController,
                  builder: (_, __) {
                    final spin = _loadingController.value * 6.283185307179586;
                    final pulse = 0.90 + (_loadingController.value * 0.20);

                    return Transform.scale(
                      scale: pulse,
                      child: SizedBox(
                        height: 92,
                        width: 92,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Transform.rotate(
                              angle: spin,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const SweepGradient(
                                    colors: [
                                      Color(0xFF5A31C7),
                                      Color(0xFF2C8EEA),
                                      Color(0xFF14D8D5),
                                      Color(0xFF5A31C7),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF070A10),
                              ),
                            ),
                            const Icon(
                              Icons.auto_awesome,
                              color: Color(0xFF84E7FF),
                              size: 30,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                const Text(
                  'Preparing your canvas',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    letterSpacing: 0.6,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ambient Doodle Pro',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
