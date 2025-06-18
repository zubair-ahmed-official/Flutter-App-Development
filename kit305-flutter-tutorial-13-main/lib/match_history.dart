import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Import your WormGraphPage and MatchActionsPage (you need to implement MatchActionsPage)
import 'match_actions.dart';
import 'worm_graph_page.dart';

class MatchHistoryPage extends StatelessWidget {
  const MatchHistoryPage({Key? key}) : super(key: key);

  String formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Match History')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('matches').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final matches = snapshot.data!.docs;

          return ListView.builder(
            itemCount: matches.length,
            itemBuilder: (context, index) {
              final match = matches[index];
              final matchId = match.id;
              final team1 = match['team1'];
              final team2 = match['team2'];
              final date = match['date'];
              final location = match['location'];

              return FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance
                    .collection('match_actions')
                    .doc(matchId)
                    .collection('actions')
                    .get(),
                builder: (context, actionSnapshot) {
                  if (!actionSnapshot.hasData) {
                    return const ListTile(title: Text('Loading match data...'));
                  }

                  final actions = actionSnapshot.data!.docs;
                  int team1Score = 0;
                  int team2Score = 0;

                  for (var doc in actions) {
                    final data = doc.data() as Map<String, dynamic>;
                    if (data['action'] == 'Goal') {
                      if (data['team'] == team1) {
                        team1Score++;
                      } else if (data['team'] == team2) {
                        team2Score++;
                      }
                    }
                  }

                  final winner = team1Score > team2Score
                      ? team1
                      : team2Score > team1Score
                      ? team2
                      : 'Draw';

                  return Card(
                    margin: const EdgeInsets.all(10),
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('$team1 vs $team2', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              Text(
                                '$team1Score : $team2Score',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: winner == 'Draw'
                                      ? Colors.grey
                                      : (winner == team1 ? Colors.blue : Colors.green),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('$date - $location\nWinner: $winner'),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  // Navigate to MatchActionsPage - you need to implement this page
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => MatchActionsPage(matchId: matchId, team1: team1, team2: team2),
                                    ),
                                  );
                                },
                                child: const Text('Match Actions'),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton(
                                onPressed: () {
                                  // Navigate to WormGraphPage
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => WormGraphPage(matchId: matchId, teamA: team1, teamB: team2),
                                    ),
                                  );
                                },
                                child: const Text('Worm Graph'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
