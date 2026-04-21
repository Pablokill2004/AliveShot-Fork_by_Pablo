import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:alive_shot/services/api_config.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ONChallengeApiService {
  static const String baseUrl = ApiConfig.baseUrl;

  // Obtener detalles de un reto en progreso específico
  static Future<Map<String, dynamic>> getChallengeInProgress(
    int challengeId,
  ) async {
    final url = Uri.parse(
      '$baseUrl/api/challenge_posts/in_progress_detail/$challengeId',
    );
    final response = await http.get(url);
    //imprimir created_at del reto
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al cargar reto en curso');
    }
  }

  // Enviar voto para un reto
  static Future<Map<String, dynamic>> sendVote(
    int challengeId,
    String votedForRole, {
    required DateTime createdAt,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    final token = user == null ? null : await user.getIdToken();
    final url = Uri.parse('$baseUrl/api/on_challenge/$challengeId/vote');
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    final body = jsonEncode({
      'voted_for_role': votedForRole,
      'created_at': createdAt.toIso8601String(),
      if (user != null) 'voter_uid': user.uid,
    });

    final response = await http.post(url, headers: headers, body: body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(response.body);
    }

    final decoded = jsonDecode(response.body);
    final votesNode = decoded['votes'] ?? decoded;
    final creatorRaw = votesNode['creator_votes'] ?? votesNode['creatorVotes'];
    final joinerRaw = votesNode['joiner_votes'] ?? votesNode['joinerVotes'];
    final creator = int.tryParse(creatorRaw?.toString() ?? '') ?? 0;
    final joiner = int.tryParse(joinerRaw?.toString() ?? '') ?? 0;
    return {'creator_votes': creator, 'joiner_votes': joiner};
  }

  // Get creator votes
  Future<int> getCreatorVotes(int challengeId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final idToken = await currentUser?.getIdToken();
    final url = Uri.parse(
      '$baseUrl/api/on_challenge/$challengeId/votes/creator',
    );
    final headers = {
      'Content-Type': 'application/json',
      if (idToken != null) 'Authorization': 'Bearer $idToken',
    };

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final raw =
          data['creator_votes'] ??
          data['votes']?['creator_votes'] ??
          data['creatorVotes'] ??
          data['votes']?['creatorVotes'];
      return int.tryParse(raw?.toString() ?? '') ?? 0;
    } else {
      throw Exception('Error al obtener votos del creador: ${response.body}');
    }
  }

  // Get competitor votes
  Future<int> getCompetitorVotes(int challengeId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final idToken = await currentUser?.getIdToken();
    final url = Uri.parse(
      '$baseUrl/api/on_challenge/$challengeId/votes/joiner',
    );
    final headers = {
      'Content-Type': 'application/json',
      if (idToken != null) 'Authorization': 'Bearer $idToken',
    };
    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final raw =
          data['joiner_votes'] ??
          data['votes']?['joiner_votes'] ??
          data['joinerVotes'] ??
          data['votes']?['joinerVotes'];
      return int.tryParse(raw?.toString() ?? '') ?? 0;
    } else {
      throw Exception(
        'Error al obtener votos del competidor: ${response.body}',
      );
    }
  }

  //Endpoint para incrementar las vistas de un reto en curso
  static Future<int> incrementView(int challengeId) async {
    final url = Uri.parse(
      '$baseUrl/api/challenge_posts/in_progress_detail/$challengeId/increment_views',
    );
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final raw = data['views'];
      return int.tryParse(raw?.toString() ?? '') ?? 0;
    } else {
      throw Exception('Error incrementando vistas: ${response.body}');
    }
  }

  // Endpoint para determinar el ganador de un reto
  /*Future<Map<String, dynamic>> saveWinner(int challengeId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/challenges/$challengeId/calculate-winner'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Error al calcular ganador");
    }
  }*/

  //Endpoint para obtener el username del ganador dado el firebase_uid
  static Future<String> getWinnerUsername(String winnerUid) async {
    final uri = Uri.parse('$baseUrl/api/challenges/$winnerUid/username');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      return data['username'] as String;
    } else {
      throw Exception("Error al obtener username del ganador");
    }
  }

  static Future<Map<String, dynamic>> updateStreak(String uid) async {
    final uri = Uri.parse("$baseUrl/api/challenges/user/streak/update");
    final res = await http.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"firebaseUid": uid}),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception("Error al actualizar racha del usuario");
    }
    return jsonDecode(res.body);
  }
}
