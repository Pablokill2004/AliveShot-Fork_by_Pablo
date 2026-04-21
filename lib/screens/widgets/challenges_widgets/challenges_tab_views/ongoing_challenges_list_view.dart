// lib/screens/widgets/challenges_widgets/ongoing_challenges_list_view.dart
import 'package:flutter/material.dart';
import 'package:alive_shot/screens/widgets/challenges_widgets/challenges_tab_views/challenge_card.dart';
import 'package:alive_shot/services/api_services/c_api_services/c_api_service.dart';
import 'package:alive_shot/screens/pages/pages.dart';

class OngoingChallengesListView extends StatefulWidget {
  final String firebaseUid;
  const OngoingChallengesListView({super.key, required this.firebaseUid});

  @override
  State<OngoingChallengesListView> createState() =>
      _OngoingChallengesListViewState();
}

class _OngoingChallengesListViewState extends State<OngoingChallengesListView> {
  late Future<List<Map<String, dynamic>>> _challengesFuture;

  @override
  void initState() {
    super.initState();
    _challengesFuture = CApiService.getOngoingChallenges(widget.firebaseUid);
  }

  Future<void> _refresh() async {
    setState(() {
      _challengesFuture = CApiService.getOngoingChallenges(widget.firebaseUid);
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
            return const Center(child: Text('No hay retos en juego.'));
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
                return ChallengeCard(
                  videoUrl: challenge['content_url'] ?? '',
                  views: challenge['views'] ?? 0,
                  state: 'En progreso',
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
              },
            ),
          );
        },
      ),
    );
  }
}
