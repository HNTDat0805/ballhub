import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/tournament/data/api_tournament_repository.dart';
import 'features/tournament/data/tournament_repository.dart';
import 'features/tournament/presentation/controllers/tournament_controller.dart';
import 'features/tournament/presentation/screens/tournament_list_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool isFirebaseInitialized = false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    isFirebaseInitialized = true;
  } catch (e) {
    debugPrint('Firebase initialization notice: $e');
  }

  // API-First architecture: initialize REST API repository
  final TournamentRepository repository = ApiTournamentRepository();
  final controller = TournamentController(repository: repository);

  runApp(BallhubApp(
    controller: controller,
    repository: repository,
    isFirebaseInitialized: isFirebaseInitialized,
  ));
}

class BallhubApp extends StatelessWidget {
  final TournamentController controller;
  final TournamentRepository repository;
  final bool isFirebaseInitialized;

  const BallhubApp({
    super.key,
    required this.controller,
    required this.repository,
    required this.isFirebaseInitialized,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ballhub - Tournament & Football Management',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: TournamentListScreen(
        controller: controller,
        repository: repository,
      ),
    );
  }
}
