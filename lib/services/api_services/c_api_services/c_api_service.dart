import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:alive_shot/services/api_config.dart';
import 'package:alive_shot/services/api_services/api_service.dart';

class CApiService {
  static const String baseUrl = ApiConfig.baseUrl;

  //static const String baseUrl = 'https://aliveshot-nodejs-backend-http-190776415532.europe-west1.run.app';

  // Crear publicación
  static Future<void> createChallengePost(
    int? categoryId,
    String? description,
    String contentType,
    String? contentUrl,
    String firebaseUid,
  ) async {
    final url = Uri.parse('$baseUrl/api/challenge_posts');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        //challenge_id
        'category_id': categoryId,
        'description': description,
        'state': 'waiting',
        'timer': null,
        //Created_at se genera en el backend
        'competitor_user_id': null,
        'joined_at': null,
        'accepted': null,
        //rater_id se asigna en el backend
        'stars': 0,
        'rated_at': null,
        //liked_user_id,
        'liked_at': null,
        //voted_for_user_id
        'voted_at': null,
        'firebase_uid': firebaseUid,
        'content_type': contentType,
        'content_url': contentUrl,
        'role': 'CREATOR',
        'views': 0,
      }),
    );

    if (response.statusCode != 201) {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['error'] ?? 'Error al crear post');
    }
  }

  static Future<List<Map<String, dynamic>>> getUserChallenges(
    String firebaseUid,
  ) async {
    final url = Uri.parse('$baseUrl/api/challenge_posts/user/$firebaseUid');
    final response = await http.get(url);
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Error al obtener los desafíos del usuario');
    }
  }


  //cargar todos los challenges disponibles para un usuario, menos los suyos
  static Future<List<Map<String, dynamic>>> getAvailableChallenges(
    String firebaseUid,
  ) async {
    final url = Uri.parse(
      '$baseUrl/api/challenge_posts/available/$firebaseUid',
    );
    final response = await http.get(url);
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Error al obtener los desafíos disponibles');
    }
  }

  static Future<List<Map<String, dynamic>>> getRequestedChallenges(
    String firebaseUid,
  ) async {
    final url = Uri.parse(
      '$baseUrl/api/challenge_posts/requested/$firebaseUid',
    );
    final response = await http.get(url);
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Error al obtener los desafíos solicitados');
    }
  }

  /*Obtener los challenges que ya están en ejecucion, es decir los que ya tienen 2 competidores */
  static Future<List<Map<String, dynamic>>> getOngoingChallenges(
    String firebaseUid,
  ) async {
    final url = Uri.parse('$baseUrl/api/challenge_posts/ongoing/$firebaseUid');
    final response = await http.get(url);
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Error al obtener los desafíos en competencia');
    }
  }

  //obtener los challenges en progreso para un usuario, es decir, los que ya ha sido aceptado
  static Future<List<Map<String, dynamic>>> getInProgressChallenges(
    String firebaseUid,
  ) async {
    final url = Uri.parse(
      '$baseUrl/api/challenge_posts/in_progress/$firebaseUid',
    );
    final response = await http.get(url);
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Error al obtener los desafíos en progreso');
    }
  }

  static Future<void> requestToJoin(
    int challengeId,
    String competitorUid,
    String competitorContentUrl,
    String competitorUrlType,
  ) async {
    final url = Uri.parse('$baseUrl/api/challenge_posts/$challengeId/request');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'competitor_uid': competitorUid,
        'competitor_content_url': competitorContentUrl,
        'competitor_content_type': competitorUrlType,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Error al enviar solicitud: ${response.body}');
    }

    final challengeData = jsonDecode(response.body)['challenge'];
    final receiverUid = challengeData['firebase_uid'];
    final description = (challengeData['description'] as String?)?.trim();
    final shortDesc = description != null && description.length > 30
        ? '${description.substring(0, 30)}...'
        : description ?? 'Reto';

    final senderProfile = await ApiService.getUser(competitorUid);
    final username = senderProfile['username'] ?? competitorUid;

    await ApiService.sendChallengeRequestNotification(
      receiverUid: receiverUid,
      senderUid: competitorUid,
      challengeId: challengeId,
      message: '@$username quiere unirse a tu reto: $shortDesc',
    );
  }

  static Future<void> acceptRequest(int challengeId) async {
    final url = Uri.parse('$baseUrl/api/challenge_posts/$challengeId/accept');
    final response = await http.patch(url);

    if (response.statusCode != 200) {
      throw Exception('Error al aceptar solicitud: ${response.body}');
    }

    // mandar notificacion al competidor de parte del creador de que su solicitud fue aceptada
    final challengeData = jsonDecode(response.body)['challenge'];
    final competitorUid = challengeData['competitor_user_id'];
    final creatorUid = challengeData['firebase_uid'];
    final description = (challengeData['description'] as String?)?.trim();
    final shortDesc = description != null && description.length > 30
        ? '${description.substring(0, 30)}...'
        : description ?? 'Reto';
    // Obtener username del creador
    final senderProfile = await ApiService.getUser(creatorUid);
    final username = senderProfile['username'] ?? creatorUid;
    // Enviar notificación con @username
    await ApiService.sendChallengeAcceptedNotification(
      receiverUid: competitorUid!,
      senderUid: creatorUid,
      challengeId: challengeId,
      message:
          '@$username ha aceptado tu solicitud para unirte al reto: $shortDesc',
    );

    //por ultimo eliminar la notificacion de solicitud pendiente de tipo 'challenge_request'
    
  }

  static Future<void> rejectRequest(int challengeId) async {
    final url = Uri.parse('$baseUrl/api/challenge_posts/$challengeId/reject');
    final response = await http.patch(url);

    if (response.statusCode != 200) {
      throw Exception('Error al rechazar solicitud: ${response.body}');
    }
  }

  // Obtener detalles de un reto específico
  static Future<Map<String, dynamic>> getChallengeDetail(
    int challengeId,
  ) async {
    final url = Uri.parse('$baseUrl/api/challenge_posts/$challengeId');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 404) {
      throw Exception('Reto no encontrado');
    } else {
      throw Exception('Error al cargar el reto');
    }
  }

  // Get aggregate rating for a user
  static Future<Map<String, dynamic>> getUserRating(String ratedUid) async {
    final url = Uri.parse('$baseUrl/api/challenge_posts/$ratedUid/rating');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Error al obtener rating: ${response.body}');
  }
   // Rate a user (create or update a rating)
static Future<Map<String, dynamic>> rateUser(
  String ratedUid,
  String raterUid,
  double stars,
) async {
  final url = Uri.parse('$baseUrl/api/challenge_posts/$ratedUid/rate');
  
  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
   
      'rater_uid': raterUid,
      'stars': stars,
    }),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  }

  throw Exception('Error al valuar usuario: ${response.body}');
}



}
