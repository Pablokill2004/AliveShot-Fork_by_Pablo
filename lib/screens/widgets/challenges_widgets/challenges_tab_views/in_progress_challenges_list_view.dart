import 'package:flutter/material.dart';
import 'package:alive_shot/screens/widgets/challenges_widgets/challenges_tab_views/challenge_card.dart';
import 'package:alive_shot/services/api_services/c_api_services/c_api_service.dart';
import 'package:alive_shot/screens/pages/pages.dart';
import 'package:alive_shot/services/api_services/c_api_services/on_challenge_api_service.dart';

class InProgressChallengesListView extends StatefulWidget {
  final String firebaseUid;
  const InProgressChallengesListView({super.key, required this.firebaseUid});

  @override
  State<InProgressChallengesListView> createState() =>
      _InProgressChallengesListViewState();
}

class _InProgressChallengesListViewState
    extends State<InProgressChallengesListView> {
  late Future<List<Map<String, dynamic>>> _challengesFuture;

  @override
  void initState() {
    super.initState();
    _challengesFuture = CApiService.getInProgressChallenges(widget.firebaseUid);
  }

  Future<void> _refresh() async {
    setState(() {
      _challengesFuture = CApiService.getInProgressChallenges(
        widget.firebaseUid,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _challengesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No se está en ningún reto activo.'),
            );
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
                final rawStatus = challenge['state'];

                if (rawStatus == 'in progress') {
                  return ChallengeCard(
                    videoUrl: challenge['content_url'] ?? '',
                    views: challenge['views'] ?? 0,
                    state: challenge['state'],
                    unirmeMode: false,
                    challengeId: challenge['challenge_id'],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OnChallenge(
                            challengeId: challenge['challenge_id'],
                            firebaseUid: widget.firebaseUid,
                          ),
                        ),
                      );
                    },
                  );
                } else if (rawStatus == 'finished') {
                  final String? winnerRole = challenge['winner_role']
                      ?.toString();
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
                      String displayName = 'Cargando...';

                      if (snapshot.hasData) {
                        displayName = snapshot.data!;
                      } else if (snapshot.hasError) {
                        displayName = 'Ganador';
                      }

                      return ChallengeCard(
                        videoUrl: challenge['content_url'] ?? '',
                        views: challenge['views'] ?? 0,
                        state: challenge['state'] ?? 'finished',
                        unirmeMode: false,
                        challengeId: challenge['challenge_id'],
                        competitorUid: challenge['competitor_user_id'],
                        winnerRole: winnerRole,
                        winnerName: displayName,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => OnChallenge(
                                challengeId: challenge['challenge_id'],
                                firebaseUid: widget.firebaseUid,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                }

                // Fallback para estados inesperados: devolver un widget vacío
                return const SizedBox.shrink();
              },
            ),
          );
        },
      ),
    );
  }
}
