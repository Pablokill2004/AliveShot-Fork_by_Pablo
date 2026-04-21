import 'package:flutter/material.dart';
import 'package:alive_shot/screens/widgets/challenges_widgets/challenges_tab_views/challenge_card.dart';
import 'package:alive_shot/services/api_services/c_api_services/c_api_service.dart';

class RequestedChallengesListView extends StatefulWidget {
  final String firebaseUid;
  const RequestedChallengesListView({super.key, required this.firebaseUid});

  @override
  State<RequestedChallengesListView> createState() => _RequestedChallengesListViewState();
}

class _RequestedChallengesListViewState extends State<RequestedChallengesListView> {
  late Future<List<Map<String, dynamic>>> _challengesFuture;

  @override
  void initState() {
    super.initState();
    _challengesFuture = CApiService.getRequestedChallenges(widget.firebaseUid);
  }

  Future<void> _refresh() async {
    setState(() {
      _challengesFuture = CApiService.getRequestedChallenges(widget.firebaseUid);
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
            return const Center(child: Text('No hay solicitudes pendientes.'));
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
                  state: 'requested',
                  unirmeMode: false,
                  challengeId: challenge['challenge_id'],
                );
              },
            ),
          );
        },
      ),
    );
  }
}