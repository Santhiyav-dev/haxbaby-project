import io
p = "lib/widgets/pip_cursor_tracker.dart"
raw = io.open(p, "r", encoding="utf-8", newline="").read()
crlf = "\r\n" in raw
s = raw.replace("\r\n", "\n")

edits = [
 ("  double _idleTime = 0.0;\n",
  "  double _idleTime = 0.0;\n\n  final GlobalKey _pipKey = GlobalKey();\n"),
 ("    _ticker.start();\n  }\n",
  "    _ticker.start();\n    GestureBinding.instance.pointerRouter.addGlobalRoute(_onGlobalPointer);\n  }\n"),
 ("  void dispose() {\n    _ticker.dispose();\n",
  "  void dispose() {\n    GestureBinding.instance.pointerRouter.removeGlobalRoute(_onGlobalPointer);\n    _ticker.dispose();\n"),
 ("  void _onPointerHover(PointerHoverEvent event, Size size) {",
  "  void _onGlobalPointer(PointerEvent event) {\n    if (event is! PointerHoverEvent) return;\n    final box = _pipKey.currentContext?.findRenderObject() as RenderBox?;\n    if (box == null || !box.attached || !box.hasSize) return;\n    _cursorPos = box.globalToLocal(event.position);\n    _updateTargetFromPosition(_cursorPos, box.size);\n  }\n\n  void _onPointerHover(PointerHoverEvent event, Size size) {"),
 ("    _targetDeadzoneFactor = 1.0; // Return to direct eye contact\n",
  "    // Whole-window tracking is handled by _onGlobalPointer, so no snap-back here.\n"),
 ("Offset(size.width * 0.50, size.height * 0.41)",
  "Offset(size.width * 0.534, size.height * 0.377)"),
 ("                child: Container(\n                  width: renderWidth,",
  "                child: Container(\n                  key: _pipKey,\n                  width: renderWidth,"),
]
for old, new in edits:
    if s.count(old) != 1:
        raise SystemExit("STOPPED, nothing changed. Not found exactly once: " + old.strip()[:50])
    s = s.replace(old, new)
if crlf:
    s = s.replace("\n", "\r\n")
io.open(p, "w", encoding="utf-8", newline="").write(s)
print("Patched OK")
