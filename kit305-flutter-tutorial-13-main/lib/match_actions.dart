import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MatchActionsPage extends StatelessWidget {
  final String matchId;
  final String team1;
  final String team2;

  const MatchActionsPage({
    Key? key,
    required this.matchId,
    required this.team1,
    required this.team2,
  }) : super(key: key);

  String formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Match Actions')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('match_actions')
            .doc(matchId)
            .collection('actions')
            .orderBy('matchTime')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final actions = snapshot.data!.docs;

          if (actions.isEmpty) {
            return const Center(child: Text('No actions recorded for this match.'));
          }

          return ListView.builder(
            itemCount: actions.length,
            itemBuilder: (context, index) {
              final data = actions[index].data() as Map<String, dynamic>;
              final player = data['player'] ?? 'Unknown';
              final actionType = data['action'] ?? 'Unknown';
              final team = data['team'] ?? 'Unknown';
              final matchTime = data['matchTime'] ?? 0;

              return ListTile(
                leading: const Icon(Icons.sports_soccer),
                title: Text('$player - $actionType'),
                subtitle: Text('Team: $team | Time: ${formatTime(matchTime)}'),
              );
            },
          );
        },
      ),
    );
  }
}
