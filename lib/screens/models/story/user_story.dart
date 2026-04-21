import 'package:alive_shot/screens/models/models.dart';
import 'package:alive_shot/services/api_services/api_service.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/material.dart';
class UserStory {
  final User owner;
  final List<Story> stories;

  const UserStory({required this.owner, required this.stories});

  factory UserStory.fromMap(
    Map<String, dynamic> userData,
    List<Map<String, dynamic>> storiesData,
  ) {
    final user = User.fromMap(userData);
    final stories = storiesData.map((data) => Story.fromMap(data)).toList();
    return UserStory(owner: user, stories: stories, );
  }

  static Future<List<UserStory>> loadUserStories() async {
    try {
      final firebaseUid = auth.FirebaseAuth.instance.currentUser?.uid;
      if (firebaseUid == null) {
        throw Exception('Usuario no autenticado');
      }

      final userData = await ApiService.getUser(firebaseUid);
      if (userData.isEmpty) {
        throw Exception('Usuario no encontrado');
      }

      final storiesData = await ApiService.getStories(firebaseUid);

      if (storiesData.isEmpty) {
        return [UserStory(owner: User.fromMap(userData), stories: [])];
      }

      return [UserStory.fromMap(userData, storiesData)];
    } catch (e) {
      debugPrint('Error cargando historias: $e');
      return dummyUserStories; // Fallback a datos ficticios
    }
  }

  //obtener historias de usuarios que sigo
  /*basarse de lo siguiente: 
  static Future<List<Map<String, dynamic>>> getFollowingStories(
    String firebaseUid,
  ) async {
    final url = Uri.parse('$baseUrl/api/stories/following/$firebaseUid');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final dynamic data = jsonDecode(response.body);
      if (data is List) {
        return data.cast<Map<String, dynamic>>();
      } else {
        debugPrint('Error: data no es una lista, es $data');
        return [];
      }
    } else {
      throw Exception('Error al obtener historias de usuarios seguidos: ${response.body}');
    }
  }*/

  static Future<List<UserStory>> loadFollowingUserStories() async {
    try {
      final firebaseUid = auth.FirebaseAuth.instance.currentUser?.uid;
      if (firebaseUid == null) {
        throw Exception('Usuario no autenticado');
      }

      final followingStoriesData = await ApiService.getFollowingStories(
        firebaseUid,
      );
      if (followingStoriesData.isEmpty) {
        return [];
      }

      // Agrupar historias por usuario
      final Map<String, List<Map<String, dynamic>>> storiesByUser = {};
      for (var storyData in followingStoriesData) {
        final userId = storyData['firebase_uid'] as String;
        if (!storiesByUser.containsKey(userId)) {
          storiesByUser[userId] = [];
        }
        storiesByUser[userId]!.add(storyData);
      }

      // Construir UserStory para cada usuario
      final List<UserStory> userStories = [];
      for (var entry in storiesByUser.entries) {
        final userId = entry.key;
        final storiesData = entry.value;

        final userData = await ApiService.getUser(userId);
        if (userData.isNotEmpty) {
          userStories.add(UserStory.fromMap(userData, storiesData));
        }
      }

      return userStories;
    } catch (e) {
      debugPrint('Error cargando historias de usuarios seguidos: $e');
      return []; // Fallback a lista vacía
    }
  }

  static List<UserStory> dummyUserStories = List.generate(
    User.dummyUsers.length,
    (index) {
      return UserStory(
        owner: User.dummyUsers[index],
        stories: Story.generateDummyStories(),
      );
    },
  );
}
