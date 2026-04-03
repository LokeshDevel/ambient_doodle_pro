import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/drawing_tool.dart';

class FloatingToolbar extends StatefulWidget {
  final DrawingTool activeTool;
  final ValueChanged<DrawingTool> onToolChanged;
  final VoidCallback onClear;
  final VoidCallback onUndo;
  final VoidCallback onColorPick;
  final VoidCallback onSave;
  final VoidCallback onToggleCanvas;
  final bool isDarkCanvas;

  const FloatingToolbar({
    super.key,
    required this.activeTool,
    required this.onToolChanged,
    required this.onClear,
    required this.onUndo,
    required this.onColorPick,
    required this.onSave,
    required this.onToggleCanvas,
    required this.isDarkCanvas,
  });

  @override
  State<FloatingToolbar> createState() => _FloatingToolbarState();
}

class _FloatingToolbarState extends State<FloatingToolbar>
    with SingleTickerProviderStateMixin {
  bool _visible = true;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: 1.0,
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _visible = !_visible);
    _visible ? _fadeController.forward() : _fadeController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 48,
      left: 0,
      right: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle / toggle button
          GestureDetector(
            onTap: _toggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48,
              height: 6,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(100),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),

          // Glassmorphic toolbar
          FadeTransition(
            opacity: _fadeAnim,
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 300),
              offset: _visible ? Offset.zero : const Offset(0, 1.5),
              curve: Curves.easeInOutCubic,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(28),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(
                          color: Colors.white.withAlpha(50),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Stroke width slider
                          Row(
                            children: [
                              const Icon(Icons.circle, size: 8, color: Colors.white54),
                              Expanded(
                                child: SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    trackHeight: 2,
                                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                                    activeTrackColor: const Color(0xFF00FFCC),
                                    inactiveTrackColor: Colors.white24,
                                    thumbColor: Colors.white,
                                  ),
                                  child: Slider(
                                    value: widget.activeTool.strokeWidth,
                                    min: 1.0,
                                    max: 40.0,
                                    onChanged: (val) {
                                      widget.onToolChanged(
                                          widget.activeTool.copyWith(strokeWidth: val));
                                    },
                                  ),
                                ),
                              ),
                              const Icon(Icons.circle, size: 16, color: Colors.white54),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Tool buttons row
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _ToolButton(
                                  icon: Icons.edit,
                                  label: 'Pen',
                                  isActive: widget.activeTool.type ==
                                      DrawingToolType.pen,
                                  isDarkCanvas: widget.isDarkCanvas,
                                  onTap: () => widget.onToolChanged(
                                    widget.activeTool.copyWith(
                                        type: DrawingToolType.pen, strokeWidth: 2.5),
                                  ),
                                ),
                                _ToolButton(
                                  icon: Icons.gesture,
                                  label: 'Sketch',
                                  isActive: widget.activeTool.type ==
                                      DrawingToolType.sketch,
                                  isDarkCanvas: widget.isDarkCanvas,
                                  onTap: () => widget.onToolChanged(
                                    widget.activeTool.copyWith(
                                        type: DrawingToolType.sketch,
                                        strokeWidth: 4.0,
                                        opacity: 0.55),
                                  ),
                                ),
                                _ToolButton(
                                  icon: Icons.brush,
                                  label: 'Marker',
                                  isActive: widget.activeTool.type ==
                                      DrawingToolType.marker,
                                  isDarkCanvas: widget.isDarkCanvas,
                                  onTap: () => widget.onToolChanged(
                                    widget.activeTool.copyWith(
                                        type: DrawingToolType.marker,
                                        strokeWidth: 8.0,
                                        opacity: 0.75),
                                  ),
                                ),
                                _ToolButton(
                                  icon: Icons.auto_fix_high,
                                  label: 'Eraser',
                                  isActive: widget.activeTool.type ==
                                      DrawingToolType.eraser,
                                  isDarkCanvas: widget.isDarkCanvas,
                                  onTap: () => widget.onToolChanged(
                                    widget.activeTool.copyWith(
                                        type: DrawingToolType.eraser,
                                        strokeWidth: 20.0),
                                  ),
                                ),
                                _Divider(isDarkCanvas: widget.isDarkCanvas),
                                // Color swatch
                                GestureDetector(
                                  onTap: widget.onColorPick,
                                  child: Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: widget.activeTool.color,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: widget.isDarkCanvas ? Colors.white.withAlpha(120) : Colors.black.withAlpha(120),
                                          width: 2),
                                    ),
                                  ),
                                ),
                                _Divider(isDarkCanvas: widget.isDarkCanvas),
                                // Undo
                                _IconBtn(
                                    icon: Icons.undo_rounded, isDarkCanvas: widget.isDarkCanvas, onTap: widget.onUndo),
                                // Clear
                                _IconBtn(
                                    icon: Icons.delete_sweep_rounded,
                                    isDarkCanvas: widget.isDarkCanvas,
                                    onTap: widget.onClear),
                                // Save
                                _IconBtn(
                                    icon: Icons.save_alt_rounded,
                                    isDarkCanvas: widget.isDarkCanvas,
                                    onTap: widget.onSave),
                                _Divider(isDarkCanvas: widget.isDarkCanvas),
                                // Background Toggle
                                _IconBtn(
                                    icon: widget.isDarkCanvas 
                                        ? Icons.light_mode_rounded 
                                        : Icons.dark_mode_rounded,
                                    isDarkCanvas: widget.isDarkCanvas,
                                    onTap: widget.onToggleCanvas),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final bool isDarkCanvas;
  final VoidCallback onTap;

  const _ToolButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.isDarkCanvas,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF00FFCC).withAlpha(40)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: isActive
              ? Border.all(color: const Color(0xFF00FFCC).withAlpha(160), width: 1.2)
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? const Color(0xFF00FFCC) : (isDarkCanvas ? Colors.white70 : Colors.black87),
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? const Color(0xFF00FFCC) : (isDarkCanvas ? Colors.white54 : Colors.black54),
                fontSize: 9,
                fontWeight:
                    isActive ? FontWeight.w700 : FontWeight.w400,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final bool isDarkCanvas;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.isDarkCanvas, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Icon(icon, color: isDarkCanvas ? Colors.white70 : Colors.black87, size: 22),
        ),
      );
}

class _Divider extends StatelessWidget {
  final bool isDarkCanvas;
  const _Divider({required this.isDarkCanvas});
  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 32,
        color: isDarkCanvas ? Colors.white.withAlpha(40) : Colors.black.withAlpha(40),
        margin: const EdgeInsets.symmetric(horizontal: 4),
      );
}
