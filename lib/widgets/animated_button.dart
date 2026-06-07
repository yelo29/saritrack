import 'package:flutter/material.dart';

class AnimatedButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String label;
  final Color color;
  final Color? textColor;
  final bool isSmall;

  const AnimatedButton({
    super.key,
    this.onPressed,
    required this.icon,
    required this.label,
    required this.color,
    this.textColor,
    this.isSmall = false,
  });

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.identity()..scale(_isHovered && widget.onPressed != null ? 1.05 : 1.0),
        child: ElevatedButton.icon(
          onPressed: widget.onPressed,
          icon: Icon(widget.icon, size: widget.isSmall ? 16 : 20, color: widget.textColor ?? Colors.white),
          label: Text(
            widget.label,
            style: TextStyle(fontSize: widget.isSmall ? 12 : 14, color: widget.textColor ?? Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.color,
            foregroundColor: widget.textColor ?? Colors.white,
            padding: widget.isSmall
                ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
                : const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(widget.isSmall ? 20 : 12)),
          ),
        ),
      ),
    );
  }
}