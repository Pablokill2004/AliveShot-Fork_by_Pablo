import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'app.dart';
import 'firebase_options.dart';
import 'package:alive_shot/services/api_notification_service.dart';
import 'package:flutter_streak/flutter_streak.dart';
import 'package:alive_shot/services/api_services/streak_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await ApiNotificationService().initNotifications();
  await Streak.init(delegate: StreakService());
  runApp(const MyApp());
}
