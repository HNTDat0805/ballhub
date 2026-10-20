import 'package:flutter_test/flutter_test.dart';
import 'package:ballhub/features/tournament/data/firebase_tournament_repository.dart';
import 'package:ballhub/features/tournament/presentation/controllers/tournament_controller.dart';
import 'package:ballhub/main.dart';

void main() {
  testWidgets('BallhubApp smoke test displays Tournament Screen header', (WidgetTester tester) async {
    final repository = FirebaseTournamentRepository();
    final controller = TournamentController(repository: repository);

    await tester.pumpWidget(BallhubApp(
      controller: controller,
      repository: repository,
      isFirebaseInitialized: false,
    ));

    // Wait for streams
    await tester.pumpAndSettle();

    // Verify AppBar title is present
    expect(find.text('BALLHUB TOURNAMENT'), findsOneWidget);
  });
}
