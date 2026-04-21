import 'package:alive_shot/screens/widgets/challenges_widgets/challenges_tab_views/challenge_card.dart';
import 'package:flutter/material.dart';
import 'package:alive_shot/services/api_services/c_api_services/c_api_service.dart';
import 'package:alive_shot/services/api_services/c_api_services/on_challenge_api_service.dart';

class UserChallengesListView extends StatefulWidget {
  final String firebaseUid;
  //final int challengeId;
  const UserChallengesListView({super.key, required this.firebaseUid});

  @override
  State<UserChallengesListView> createState() => _UserChallengesListViewState();
}

class _UserChallengesListViewState extends State<UserChallengesListView> {
  late Future<List<Map<String, dynamic>>> _userChallengesFuture;

  @override
  void initState() {
    super.initState();
   // _incrementViewOnce();
    _userChallengesFuture = CApiService.getUserChallenges(widget.firebaseUid);
  }

  /*Future<void> _incrementViewOnce() async {
    try {
      
      await ONChallengeApiService.incrementView(
        );
      // opcional: actualizar UI si muestras el contador en esta pantalla
      
    } catch (e) {
      // ignorar o debugPrint en desarrollo
      debugPrint('Error incrementing view: $e');
    }
  }
  */
  /*Future<Map<String, String?>> _getWinnerInfo(
    Map<String, dynamic> challenge,
  ) async {
    try {
      final onChallengeApiService = ONChallengeApiService();
      final winnerData = await onChallengeApiService.saveWinner(
        challenge['challenge_id'],
      );
      final winnerRole = winnerData["winner_role"] as String?;
      final winnerUid = winnerData["winner_uid"]?.toString();

      String? winnerUsername;
      if (winnerUid != null) {
        try {
          winnerUsername = await onChallengeApiService.getWinnerUsername(
            winnerUid,
          );
        } catch (e) {
          // if username fetch fails, leave null
          winnerUsername = null;
        }
      }
      // Return keys expected by the UI
      return {'winnerUsername': winnerUsername, 'winnerRole': winnerRole};
    } catch (e) {
      return {'winnerUsername': null, 'winnerRole': null};
    }
  }*/

  Future<void> _refreshChallenges() async {
    setState(() {
      _userChallengesFuture = CApiService.getUserChallenges(widget.firebaseUid);
    });
  }

  Future<void> _acceptRequest(int challengeId) async {
    try {
      await CApiService.acceptRequest(challengeId);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Solicitud aceptada')));
      _refreshChallenges();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _rejectRequest(int challengeId) async {
    try {
      await CApiService.rejectRequest(challengeId);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Solicitud rechazada')));
      _refreshChallenges();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refreshChallenges,
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _userChallengesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No hay desafíos creados.'));
          }

          final challenges = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: GridView.builder(
              itemCount: challenges.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemBuilder: (context, index) {
                final challenge = challenges[index];
                final isRequested = challenge['state'] == 'requested';
                final rawState = (challenge['state'] ?? 'waiting')
                    .toString()
                    .trim()
                    .toLowerCase()
                    .replaceAll(' ', '_');

                // If finished, fetch winner info and pass to card

                if (rawState == 'finished') {
                final String? winnerRole = challenge['winner_role']?.toString();
                final String? winnerUid = challenge['winner_uid']?.toString();

                if (winnerUid == null || winnerRole == null) {
                  return ChallengeCard(
                    videoUrl: challenge['content_url'] ?? '',
                    views: challenge['views'] ?? 0,
                    state: challenge['state'] ?? 'finished',
                    unirmeMode: false,
                    challengeId: challenge['challenge_id'],
                    competitorUid: challenge['competitor_user_id'],
                    winnerName: '',
                    winnerRole: winnerRole,
                  );
                }

                return FutureBuilder<String>(
                  future: ONChallengeApiService.getWinnerUsername(winnerUid),
                  builder: (context, snapshot) {

                    if (snapshot.hasData) {
                    } else if (snapshot.hasError) {
                    }

                    return ChallengeCard(
                      videoUrl: challenge['content_url'] ?? '',
                      views: challenge['views'] ?? 0,
                      state: challenge['state'] ?? 'finished',
                      unirmeMode: false,
                      challengeId: challenge['challenge_id'],
                      competitorUid: challenge['competitor_user_id'],
                      winnerRole: winnerRole,
                    );
                  },
                );
              }

                return ChallengeCard(
                  videoUrl: challenge['content_url'] ?? '',
                  views: challenge['views'] ?? 0,
                  state: challenge['state'] ?? 'waiting',
                  unirmeMode: false,
                  challengeId: challenge['challenge_id'],
                  competitorUid: challenge['competitor_user_id'],
                  onAccept: isRequested
                      ? () => _acceptRequest(challenge['challenge_id'])
                      : null,
                  onReject: isRequested
                      ? () => _rejectRequest(challenge['challenge_id'])
                      : null,
                );
              },
            ),
          );
        },
      ),
    );
  }
}
