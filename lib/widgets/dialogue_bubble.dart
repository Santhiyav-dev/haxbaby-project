import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// Pip's speech bubble showing dialogue lines one at a time.
class DialogueBubble extends StatefulWidget {
  final List<String> lines;
  final bool isNight;
  final VoidCallback? onComplete;
  final ValueChanged<int>? onLineChange;

  const DialogueBubble({
    super.key,
    required this.lines,
    required this.isNight,
    this.onComplete,
    this.onLineChange,
  });

  @override
  State<DialogueBubble> createState() => _DialogueBubbleState();
}

class _DialogueBubbleState extends State<DialogueBubble> {
  int _index = 0;

  void _advance() {
    if (_index < widget.lines.length - 1) {
      setState(() => _index++);
      widget.onLineChange?.call(_index);
    } else {
      widget.onComplete?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNight = widget.isNight;
    final bubbleColor = isNight
        ? PipColors.nightCard.withOpacity(0.95)
        : Colors.white.withOpacity(0.95);
    final textColor = isNight ? Colors.white : PipColors.brown;
    final accentColor = isNight ? PipColors.goldenGlow : PipColors.berryPink;

    return GestureDetector(
      onTap: _advance,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Bubble
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                  bottomLeft: Radius.circular(4),
                ),
                border: Border.all(
                  color: accentColor.withOpacity(0.4),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withOpacity(0.15),
                    blurRadius: 20,
                    spreadRadius: 4,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    key: ValueKey(_index),
                    widget.lines[_index],
                    style: GoogleFonts.nunito(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                      height: 1.5,
                    ),
                  ).animate().fadeIn(duration: 400.ms).slideY(
                        begin: 0.2,
                        end: 0,
                        duration: 350.ms,
                        curve: Curves.easeOut,
                      ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          for (int i = 0; i < widget.lines.length; i++)
                            Container(
                              width: i == _index ? 18 : 7,
                              height: 7,
                              margin: const EdgeInsets.only(right: 4),
                              decoration: BoxDecoration(
                                color: i == _index
                                    ? accentColor
                                    : accentColor.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ).animate().scaleX(duration: 300.ms),
                        ],
                      ),
                      Text(
                        _index < widget.lines.length - 1
                            ? 'tap to continue ›'
                            : 'tap to close ✓',
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          color: accentColor.withOpacity(0.7),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
