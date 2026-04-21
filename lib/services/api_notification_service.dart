import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:alive_shot/app.dart';
import 'package:alive_shot/screens/pages/home_page.dart';
import 'package:alive_shot/services/api_services/api_service.dart';

class ApiNotificationService {
  //Create an instance of Firebase Messaging
  final _firebaseMessaging = FirebaseMessaging.instance;
  // Variable para guardar el contexto de navegación

  // Function to initialize notifications
  Future<void> initNotifications() async {
    try {
      // Request permission from user (will promts user)
      await _firebaseMessaging.requestPermission();
      // Fetch the FCM token for this device
      final fcmToken = await _firebaseMessaging.getToken();
      // Fetch the Firebase UID of the current user
      final firebaseUid = await ApiService.getCurrentUserUid();
      // Send to Backend and Save
      if (firebaseUid != null && fcmToken != null) {
        // #NO QUITAR PRINT, ES PARA VERIFICAR QUE SE ENVIA EL TOKEN Y HAY CONEXION A LA BD
        await ApiService.updateUserToken(firebaseUid, fcmToken);
      }
      // Initialize push notifications
      initPushNotifications();
    } catch (e) {
      debugPrint("Error en iniciar las notificaciones y nuevo token $e");
    }
  }

  //Function to handle received messages
  void handleMessages(RemoteMessage? message) {
    // if the message is null, do nothing
    if (message == null) return;
    // else, navigate to NotificationsPage

    navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (context) => const HomePage(initialIndex: 2)),
    );
  }

  // Function to initialize foreground and background settings
  Future initPushNotifications() async {
    // Handle notification if the app was terminated and now opened
    FirebaseMessaging.instance.getInitialMessage().then(handleMessages);
    // attach listeners for when a notification opens the app
    FirebaseMessaging.onMessageOpenedApp.listen(handleMessages);
  }
}
