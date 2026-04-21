import 'package:flutter/material.dart';
import 'package:alive_shot/screens/widgets/challenges_widgets/challenges_tab_views/challenge_card.dart';
import 'package:alive_shot/services/api_services/c_api_services/c_api_service.dart';
import 'package:alive_shot/screens/widgets/challenges_widgets/challenges_tab_views/join_challenge_modal.dart';

class AllChallengesListView extends StatefulWidget {
  final String firebaseUid;
  const AllChallengesListView({super.key, required this.firebaseUid});

  @override
  State<AllChallengesListView> createState() => _AllChallengesListViewState();
}

class _AllChallengesListViewState extends State<AllChallengesListView> {
  late Future<List<Map<String, dynamic>>> _allChallengesFuture;

  @override
  void initState() {
    super.initState();
    _allChallengesFuture = CApiService.getAvailableChallenges(widget.firebaseUid);
  }

  Future<void> _refreshChallenges() async {
    setState(() {
      _allChallengesFuture = CApiService.getAvailableChallenges(widget.firebaseUid);
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refreshChallenges,
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _allChallengesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No hay desafíos disponibles.'));
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
                final isMyChallenge = challenge['firebase_uid'] == widget.firebaseUid;
                final isWaiting = challenge['state'] == 'waiting' && challenge['competitor_user_id'] == null;

                return ChallengeCard(
                  videoUrl: challenge['content_url'] ?? '',
                  views: challenge['views'] ?? 0, 
                  state: challenge['state'] ?? 'Disponible',
                  unirmeMode: !isMyChallenge && isWaiting,
                  challengeId: challenge['challenge_id'],
                  onJoin: () {
                    JoinChallengeModal.show(
                      context,
                      challengeId: challenge['challenge_id'],
                      description: challenge['description'] ?? '',
                    ).then((_) {
                      // Refrescar después de cerrar modal 
                      _refreshChallenges();
                    });
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