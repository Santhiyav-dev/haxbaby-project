import 'package:flutter_test/flutter_test.dart';
import 'package:haxbaby_project/main.dart';
import 'package:haxbaby_project/widgets/pip_cursor_tracker.dart';

void main() {
  testWidgets('dream world renders Pip and its main sections', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text("Pip's Dream World"), findsOneWidget);
    expect(
      find.text('I see you! Let’s build sweet dreams together.'),
      findsOneWidget,
    );
    expect(find.byType(PipCursorTracker), findsOneWidget);
    expect(find.text('The nightlight collection'), findsOneWidget);
    expect(find.text('Secret Dream Room'), findsOneWidget);

    await tester.tap(find.byTooltip('Switch to nightdream'));
    await tester.pump();
    expect(find.byTooltip('Switch to daydream'), findsOneWidget);
  });
}
