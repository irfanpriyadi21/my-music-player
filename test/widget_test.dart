import 'package:flutter_test/flutter_test.dart';
import 'package:my_player_music/main.dart';

void main() {
  testWidgets('Smoke test app initialization', (WidgetTester tester) async {
    await tester.pumpWidget(const MyPlayerMusicApp());
    expect(find.text("Explore & Vibe"), findsOneWidget);
  });
}
