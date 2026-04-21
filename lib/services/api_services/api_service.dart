import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:alive_shot/screens/models/models.dart';
import 'package:alive_shot/services/api_config.dart';

class ApiService {
  static const String baseUrl = ApiConfig.baseUrl;

  static Future<void> createOrUpdateUser(
    String firebaseUid, {
    String? email,
    String? name,
    String? lastname,
    String? birthday,
    String? gender,
    String? address,
    String? phone,
    String? title,
    String? bio,
    String? username,
  }) async {
    final url = Uri.parse('$baseUrl/api/users');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'firebase_uid': firebaseUid,
        'email': email,
        'name': name,
        'last_name': lastname,
        'birthday': birthday,
        'gender': gender,
        'is_active': true,
        'is_admin': false,
        'streak': 0,
        'image': '',
        'image_header': '',
        'followers': 0,
        'following': 0,
        'likes': '[]',
        'address': address,
        'phone': phone,
        'title': title,
        'bio': bio,
        'username': username,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Error al guardar el usuario: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> getUser(String firebaseUid) async {
    final url = Uri.parse('$baseUrl/api/users/$firebaseUid');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 404) {
      return {};
    } else {
      throw Exception('Error al buscar el usuario: ${response.body}');
    }
  }

  static Future<void> updateUser(
    String firebaseUid,
    Map<String, dynamic> updatedData,
  ) async {
    final url = Uri.parse('$baseUrl/api/users/$firebaseUid');

    // Eliminar las claves con valores nulos
    updatedData.removeWhere((key, value) => value == null);

    // Enviar la solicitud
    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(updatedData),
    );

    if (response.statusCode != 200) {
      throw Exception('Error al actualizar el usuario: ${response.body}');
    }
  }

  //historias
  static Future<void> createStory(
    String firebaseUid,
    int? categoryId,
    String contentType,
    String contentUrl,
    String? caption,
  ) async {
    final url = Uri.parse('$baseUrl/api/stories');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'firebase_uid': firebaseUid,
        'category_id': categoryId,
        'content_type': contentType,
        'content_url': contentUrl,
        'caption': caption ?? '',
      }),
    );
    if (response.statusCode != 201) {
      throw Exception('Error al crear historia: ${response.body}');
    }
  }

  static Future<List<Map<String, dynamic>>> getStories(
    String firebaseUid,
  ) async {
    final url = Uri.parse('$baseUrl/api/stories/$firebaseUid');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final dynamic data = jsonDecode(
        response.body,
      ); // Usa dynamic para inspeccionar
      debugPrint('Tipo de data recibido: ${data.runtimeType}'); // Depuración
      debugPrint('Datos crudos: $data'); // Verifica la estructura exacta
      if (data is List) {
        return data.cast<Map<String, dynamic>>(); // Convierte seguro
      } else {
        debugPrint('Error: data no es una lista, es $data');
        return []; // Devuelve vacía si no es lista
      }
    } else {
      throw Exception('Error al obtener historias: ${response.body}');
    }
  }

  //obtener historias de un usuario específico
  static Future<List<Map<String, dynamic>>> getUserStories(
    String firebaseUid,
  ) async {
    final url = Uri.parse('$baseUrl/api/stories/user/$firebaseUid');
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
      throw Exception(
        'Error al obtener historias del usuario: ${response.body}',
      );
    }
  }

  // obtener historias de usuarios seguidos

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
      throw Exception(
        'Error al obtener historias de usuarios seguidos: ${response.body}',
      );
    }
  }

  // Crear publicación
  static Future<void> createPost(
    String firebaseUid,
    int? categoryId,
    String title,
    String? description,
    String contentType,
    String? contentUrl,
  ) async {
    final url = Uri.parse('$baseUrl/api/posts');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'firebase_uid': firebaseUid,
        'category_id': categoryId,
        'title': title,
        'description': description,
        'content_type': contentType,
        'content_url': contentUrl,
      }),
    );

    if (response.statusCode != 201) {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['error'] ?? 'Error al crear post');
    }
  }

  //eliminar un post
  static Future<void> deletePost(int postId) async {
    final url = Uri.parse('$baseUrl/api/posts/$postId');
    final response = await http.delete(url);

    if (response.statusCode != 200) {
      throw Exception('Error al eliminar el post: ${response.body}');
    }
  }

  static Future<List<Map<String, dynamic>>> getUserPosts(
    String firebaseUid,
  ) async {
    final url = Uri.parse('$baseUrl/api/posts/user/$firebaseUid');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception('Error al obtener posts del usuario: ${response.body}');
    }
  }

  // Obtener posts que el usuario ha dado like
  static Future<List<Map<String, dynamic>>> getUserLikedPosts(
    String firebaseUid,
  ) async {
    final url = Uri.parse('$baseUrl/api/users/$firebaseUid/liked-posts');
    final response = await http.get(
      url,
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Error al obtener posts con likes: ${response.body}');
    }
  }

  /*obtener todos los usuarios que le dieron like a un post*/
  static Future<List<Map<String, dynamic>>> getPostLikingUsers(
    int postId,
  ) async {
    final url = Uri.parse('$baseUrl/api/likes/post/$postId/users');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception(
        'Error al obtener usuarios que dieron like: ${response.body}',
      );
    }
  }

  //Buscar usuarios por username
  static Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    final url = Uri.parse('$baseUrl/api/users/search/$query');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception('Error al buscar usuarios: ${response.body}');
    }
  }

  static Future<void> followUser(
    String followerFirebaseUid,
    String followingFirebaseUid,
  ) async {
    final url = Uri.parse('$baseUrl/api/follow');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'follower_firebase_uid': followerFirebaseUid,
        'following_firebase_uid': followingFirebaseUid,
      }),
    );

    if (response.statusCode != 201) {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['error'] ?? 'Error al seguir usuario');
    }
  }

  static Future<void> unfollowUser(
    String followerFirebaseUid,
    String followingFirebaseUid,
  ) async {
    final url = Uri.parse('$baseUrl/api/unfollow');
    final response = await http.delete(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'follower_firebase_uid': followerFirebaseUid,
        'following_firebase_uid': followingFirebaseUid,
      }),
    );

    if (response.statusCode != 200) {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['error'] ?? 'Error al dejar de seguir usuario');
    }
  }

  //verificar si sigue al user
  static Future<bool> isFollowing(
    String followerFirebaseUid,
    String followingFirebaseUid,
  ) async {
    final url = Uri.parse(
      '$baseUrl/api/follow/check?follower=$followerFirebaseUid&following=$followingFirebaseUid',
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['following'] as bool;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Obtener seguidores y seguidos
  static Future<List<Map<String, dynamic>>> getFollowers(
    String firebaseUid,
  ) async {
    final url = Uri.parse('$baseUrl/api/users/$firebaseUid/followers');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception('Error al obtener seguidores: ${response.body}');
    }
  }

  static Future<List<Map<String, dynamic>>> getFollowing(
    String firebaseUid,
  ) async {
    final url = Uri.parse('$baseUrl/api/users/$firebaseUid/following');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception('Error al obtener seguidos: ${response.body}');
    }
  }

  /* publicar comentario en un post
  considerando el siguiente endpoint en el backend:
  app.post('/api/comments', async (req, res) => {
    const { firebase_uid, post_id, content } = req.body;
    if (!firebase_uid || !post_id || !content) {
      return res.status(400).json({ error: 'Faltan campos requeridos: firebase_uid, post_id, content' });
    }
    try {
      const query = `
        INSERT INTO User_Does_Comment_IsSetTo_Post (firebase_uid, post_id, content)
        VALUES ($1, $2, $3)
        RETURNING *;
      `;
      const values = [firebase_uid, post_id, content];
      const result = await pool.query(query, values);
      res.status(201).json(result.rows[0]);
    } catch (err) {
      console.error(err.stack);
      res.status(500).json({ error: 'Error al crear comentario' });
    }
  });*/

  // lib/services/api_service.dart
  static Future<void> createComment(
    String firebaseUid,
    int postId,
    String content,
  ) async {
    if (postId <= 0) throw Exception('postId inválido');
    final url = Uri.parse('$baseUrl/api/comments');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'firebase_uid': firebaseUid,
        'post_id': postId,
        'content': content,
      }),
    );

    if (response.statusCode != 201) {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['error'] ?? 'Error al crear comentario');
    }
  }

  static Future<List<Comment>> getPostComments(int postId) async {
    if (postId <= 0) throw Exception('postId inválido');
    final url = Uri.parse('$baseUrl/api/comments/post/$postId');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final dynamic data = jsonDecode(response.body);
      if (data is List) {
        return data.map<Comment>((item) {
          final Map<String, dynamic> row = Map<String, dynamic>.from(
            item as Map,
          );

          final Map<String, dynamic> userMap = {
            'firebase_uid': row['firebase_uid'] ?? '',
            'image': row['user_image'] ?? row['image'] ?? '',
            'username': row['username'] ?? '',
            'name': row['name'] ?? '',
            'last_name': row['last_name'] ?? '',
            'email': row['email'] ?? '',
            'image_header': row['image_header'] ?? '',
            'followers': row['followers'] ?? 0,
            'following': row['following'] ?? 0,
            'bio': row['bio'] ?? '',
          };

          final owner = User.fromMap(userMap);
          final body = row['content'] ?? row['body'] ?? '';
          final likeCount = (row['like_count'] ?? row['likes'] ?? 0) is int
              ? row['like_count'] ?? row['likes'] ?? 0
              : int.tryParse(
                      (row['like_count'] ?? row['likes'] ?? '0').toString(),
                    ) ??
                    0;

          return Comment(owner: owner, body: body, likeCount: likeCount);
        }).toList();
      }
      return [];
    } else {
      throw Exception(
        'Error al obtener comentarios del post: ${response.body}',
      );
    }
  }

  static Future<void> addLike(String firebaseUid, int postId) async {
    final url = Uri.parse('$baseUrl/api/likes');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'firebaseUid': firebaseUid, 'postId': postId}),
    );

    if (response.statusCode != 201) {
      throw Exception('Error al agregar like: ${response.body}');
    }
  }

  static Future<void> removeLike(String firebaseUid, int postId) async {
    final url = Uri.parse('$baseUrl/api/likes');
    final response = await http.delete(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'firebaseUid': firebaseUid, 'postId': postId}),
    );

    if (response.statusCode != 200) {
      throw Exception('Error al quitar like: ${response.body}');
    }
  }

  static Future<int> getLikeCount(int postId) async {
    final url = Uri.parse('$baseUrl/api/likes/count?postId=$postId');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['count'];
    }
    throw Exception('Error al obtener conteo de likes');
  }

  static Future<bool> checkUserLiked(int postId, String firebaseUid) async {
    final url = Uri.parse(
      '$baseUrl/api/likes/check?postId=$postId&firebaseUid=$firebaseUid',
    );
    final response = await http.get(url);
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['liked'];
    }
    throw Exception('Error al verificar like');
  }

  static Future<void> updateUserToken(String firebaseUid, String? token) async {
    //ADD to users table fcm_token column
    final url = Uri.parse('$baseUrl/api/users/$firebaseUid/token');
    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'fcm_token': token}),
    );
    if (response.statusCode != 200) {
      throw Exception('Error al actualizar token: ${response.body}');
    }
  }

  static Future<void> sendFollowNotification(
    String followerUid,
    String followingUid,
  ) async {
    final url = Uri.parse('$baseUrl/api/notifications/follow');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'follower_uid': followerUid,
        'following_uid': followingUid,
      }),
    );
    if (response.statusCode != 201) {
      debugPrint(response.body);
      throw Exception(
        'Error al enviar notificación de seguimiento: ${response.body}',
      );
    }
  }

  // Obtener notificaciones
  static Future<List<UserNotification>> getUserNotifications(
    String firebaseUid,
  ) async {
    final url = Uri.parse('$baseUrl/api/notifications/$firebaseUid');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((n) => UserNotification.fromJson(n)).toList();
    } else {
      throw Exception('Error al obtener notificaciones');
    }
  }

  static Future<void> markNotificationAsRead(int id) async {
    await http.put(Uri.parse('$baseUrl/api/notifications/$id/read'));
  }

  static Future<void> markAllAsRead(String uid) async {
    await http.put(Uri.parse('$baseUrl/api/notifications/read-all/$uid'));
  }

  static Future<void> deleteNotification(int id) async {
    await http.delete(Uri.parse('$baseUrl/api/notifications/$id'));
  }

  // obtener id de la notificacion
  static Future<List<int>> getNotificationIds(String firebaseUid) async {
    final url = Uri.parse('$baseUrl/api/notifications/id/$firebaseUid');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((n) => n['notification_id'] as int).toList();
    }
    throw Exception('Error al obtener IDs de notificaciones');
  }

  static Future<void> deleteChallengeRequestNotification(
    int challengeId,
  ) async {
    final url = Uri.parse(
      '$baseUrl/api/notifications/challenge_request/$challengeId',
    );
    final response = await http.delete(url);

    if (response.statusCode != 200) {
      throw Exception('Error al eliminar notificación: ${response.body}');
    }
  }

  static Future<void> sendChallengeRequestNotification({
    required String receiverUid,
    required String senderUid,
    required int challengeId,
    required String message,
  }) async {
    final url = Uri.parse('$baseUrl/api/notifications/challenge_request');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'receiver_uid': receiverUid,
        'sender_uid': senderUid,
        'challenge_id': challengeId,
        'message': message,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Error al enviar notificación: ${response.body}');
    }
  }

  /*enviar notificación de reto aceptado*/
  static Future<void> sendChallengeAcceptedNotification({
    required String receiverUid,
    required String senderUid,
    required int challengeId,
    required String message,
  }) async {
    final url = Uri.parse('$baseUrl/api/notifications/challenge_accepted');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'receiver_uid': receiverUid,
        'sender_uid': senderUid,
        'challenge_id': challengeId,
        'message': message,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Error al enviar notificación: ${response.body}');
    }
  }

  static Future<FeedResponse> getUserFeed(String firebaseUid) async {
    int page = 0;
    final url = Uri.parse(
      '$baseUrl/api/allPosts/users/feed?firebase_uid=$firebaseUid&page=$page',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      return FeedResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Error al obtener el feed: ${response.body}');
    }
  }

  static Future<String?> getCurrentUserUid() async {
    // Aquí deberías implementar la lógica para obtener el UID del usuario actual
    // Por ejemplo, si usas Firebase Auth, podrías hacer algo como:
    return FirebaseAuth.instance.currentUser?.uid;
  }
}
