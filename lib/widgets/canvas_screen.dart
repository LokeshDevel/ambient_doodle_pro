import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_drawing_board/flutter_drawing_board.dart';
import 'dart:async';
import 'package:flutter_drawing_board/paint_contents.dart';
import 'package:gal/gal.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/drawing_tool.dart';
import '../services/firebase_sync_service.dart';
import '../themes/app_theme.dart';
import '../widgets/floating_toolbar.dart';

class CanvasScreen extends StatefulWidget {
  const CanvasScreen({super.key});

  @override
  State<CanvasScreen> createState() => _CanvasScreenState();
}

class _CanvasScreenState extends State<CanvasScreen>
    with SingleTickerProviderStateMixin {
  final DrawingController _drawingController =
      DrawingController(maxHistorySteps: 2147483647);
  DrawingTool _activeTool = const DrawingTool(
    type: DrawingToolType.pen,
    color: Colors.white,
    strokeWidth: 2.5,
  );
  bool _isDarkCanvas = true;

  // Ambient mode hint fade
  late AnimationController _hintController;
  late Animation<double> _hintAnim;
  Timer? _hintReverseTimer;
  
  // Realtime Cloud Synchronization
  FirebaseSyncService? _syncService;
  bool _deferredInitDone = false;

  @override
  void initState() {
    super.initState();
    _hintController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _hintAnim = CurvedAnimation(parent: _hintController, curve: Curves.easeOut);
    // Show hint briefly then fade
    _hintController.forward().then((_) {
      _hintReverseTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) {
          _hintController.reverse();
        }
      });
    });
    _applyTool(_activeTool);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _deferredInitDone) return;
      _deferredInitDone = true;

      _syncService = FirebaseSyncService(_drawingController);

      try {
        WakelockPlus.enable();
      } catch (e) {
        debugPrint('Wakelock enable failed: $e');
      }
    });
  }

  @override
  void dispose() {
    _hintReverseTimer?.cancel();
    try {
      WakelockPlus.disable();
    } catch (e) {
      debugPrint('Wakelock disable failed: $e');
    }
    _drawingController.dispose();
    _hintController.dispose();
    super.dispose();
  }

  void _applyTool(DrawingTool tool) {
    switch (tool.type) {
      case DrawingToolType.pen:
        // Pen: crisp SimpleLine (precise Bézier smoothing standard)
        _drawingController.setStyle(
          color: tool.color.withAlpha((tool.opacity * 255).round()),
          strokeWidth: tool.strokeWidth,
          strokeCap: StrokeCap.round,
          blendMode: BlendMode.srcOver,
        );
        _drawingController.setPaintContent(SimpleLine());
        break;
      case DrawingToolType.sketch:
        // Sketch: graphite-like textured line using low-opacity SimpleLine layered overdrawing
        _drawingController.setStyle(
          color: tool.color.withAlpha((tool.opacity * 255).round()),
          strokeWidth: tool.strokeWidth,
          strokeCap: StrokeCap.square,
          blendMode: BlendMode.plus, 
        );
        _drawingController.setPaintContent(SimpleLine());
        break;
      case DrawingToolType.marker:
        // Marker: SmoothLine (Catmull-Rom spline interpolation for ink aesthetic)
        _drawingController.setStyle(
          color: tool.color.withAlpha((tool.opacity * 255).round()),
          strokeWidth: tool.strokeWidth,
          strokeCap: StrokeCap.round,
          blendMode: BlendMode.srcOver,
        );
        _drawingController.setPaintContent(SmoothLine());
        break;
      case DrawingToolType.eraser:
        // Eraser: vector path removal using BlendMode.clear
        _drawingController.setStyle(
          strokeWidth: tool.strokeWidth,
          strokeCap: StrokeCap.round,
          blendMode: BlendMode.clear,
        );
        _drawingController.setPaintContent(Eraser());
        break;
    }
  }

  void _onToolChanged(DrawingTool tool) {
    setState(() => _activeTool = tool);
    _applyTool(tool);
  }

  void _openColorPicker() {
    Color pickedColor = _activeTool.color;
    showDialog(
      context: context,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: const Color(0xFF111111),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 16),
          contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 20),
          title: const Text('Pick a colour',
              style: TextStyle(color: Colors.white70, fontSize: 14)),
          content: SingleChildScrollView(
            child: HueRingPicker(
              pickerColor: pickedColor,
              onColorChanged: (c) => pickedColor = c,
              enableAlpha: true,
              displayThumbColor: true,
              colorPickerHeight: 180.0, // Reduced from 250px default
              hueRingStrokeWidth: 15.0, // Reduced from 20px default
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                final updated =
                    _activeTool.copyWith(color: pickedColor);
                _onToolChanged(updated);
                Navigator.pop(ctx);
              },
              child: const Text('Apply',
                  style: TextStyle(color: Color(0xFF00FFCC))),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveToGallery() async {
    try {
      // getImageData returns the Future<ByteData?> for the current canvas
      final imageBytes = await _drawingController.getImageData();
      if (imageBytes != null) {
        final uint8List = imageBytes.buffer.asUint8List();
        
        bool hasAccess = await Gal.hasAccess();
        if (!hasAccess) {
          hasAccess = await Gal.requestAccess();
        }

        if (hasAccess) {
          final fileName = 'ambient_doodle_${DateTime.now().millisecondsSinceEpoch}';
          await Gal.putImageBytes(uint8List, name: fileName);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Doodle saved to Gallery! 🎨'),
                backgroundColor: Color(0xFF00FFCC),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isDarkCanvas ? AppTheme.canvasBackground : Colors.white,
      body: Stack(
        children: [
          // ── Borderless Drawing Canvas ──────────────────────────────────
          Positioned.fill(
            child: DrawingBoard(
              controller: _drawingController,
              background: SizedBox(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                child: Container(color: Colors.transparent),
              ),
              boardPanEnabled: false,
              boardScaleEnabled: false,
              enablePalmRejection: true, // Filters out large erratic touches
            ),
          ),

          // ── System Gesture Interceptor ─────────────────────────────────
          // Immersive mode sets SafeArea bottom to 0, so Android edge swipes
          // directly hit the canvas and cause PointerCancel straight-line bugs.
          // This transparent barrier eats touches in the bottom 40px so the 
          // DrawingBoard never receives the fatal swipe-up gestures.
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 40,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanStart: (_) {}, // Swallows the drag gesture natively
              child: const SizedBox.expand(),
            ),
          ),

          // ── Ambient hint overlay ───────────────────────────────────────
          Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _hintAnim,
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withAlpha(30), width: 1),
                      ),
                      child: const Text(
                        'Ambient Doodle Pro - just start drawing',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                          letterSpacing: 1.1,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Floating Toolbar ───────────────────────────────────────────
          FloatingToolbar(
            activeTool: _activeTool,
            onToolChanged: _onToolChanged,
            onClear: _drawingController.clear,
            onUndo: _drawingController.undo,
            onColorPick: _openColorPicker,
            onSave: _saveToGallery,
            isDarkCanvas: _isDarkCanvas,
            onToggleCanvas: () => setState(() => _isDarkCanvas = !_isDarkCanvas),
          ),
        ],
      ),
    );
  }
}
