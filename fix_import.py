import io
p = "lib/widgets/pip_cursor_tracker.dart"
raw = io.open(p, "r", encoding="utf-8", newline="").read()
crlf = "\r\n" in raw
s = raw.replace("\r\n", "\n")
old = "import 'package:flutter/material.dart';\n"
if s.count(old) != 1 or "flutter/gestures.dart" in s:
    raise SystemExit("STOPPED, nothing changed.")
s = s.replace(old, "import 'package:flutter/gestures.dart';\n" + old)
if crlf:
    s = s.replace("\n", "\r\n")
io.open(p, "w", encoding="utf-8", newline="").write(s)
print("Import added OK")
