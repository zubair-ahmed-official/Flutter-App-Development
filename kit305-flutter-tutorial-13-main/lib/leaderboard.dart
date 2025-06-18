import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({Key? key}) : super(key: key);

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  String? selectedMatchId;
  List<Map<String, dynamic>> matches = [];
  List<Map<String, dynamic>> topScorers = [];
  List<Map<String, dynamic>> topFoulers = [];
  String? winner;
  double avgGoals = 0;
  double avgFouls = 0;
  List<String> goalTimes = [];
  List<String> foulTimes = [];

  @override
  void initState() {
    super.initState();
    fetchMatches();
  }

  Future<void> fetchMatches() async {
    final snapshot = await FirebaseFirestore.instance.collection('matches').get();
    setState(() {
      matches = snapshot.docs
          .map((doc) => {
        'id': doc.id,
        'team1': doc['team1'] ?? '',
        'team2': doc['team2'] ?? '',
      })
          .toList();
    });
  }

  Future<void> fetchLeaderboard(String matchId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('match_actions')
        .doc(matchId)
        .collection('actions')
        .get();

    Map<String, Map<String, dynamic>> stats = {};
    Map<String, int> teamGoals = {};
    goalTimes.clear();
    foulTimes.clear();

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final player = data['player'] ?? '';
      final team = data['team'] ?? '';
      final action = data['action'] ?? '';
      final timestamp = (data['timestamp'] as Timestamp?)?.toDate();

      stats[player] ??= {'player': player, 'team': team, 'Goal': 0, 'Foul': 0};

      if (action == 'Goal') {
        stats[player]!['Goal'] = (stats[player]!['Goal'] ?? 0) + 1;
        teamGoals[team] = (teamGoals[team] ?? 0) + 1;
        if (timestamp != null) {
          goalTimes.add(DateFormat.Hm().format(timestamp));
        }
      }

      if (action == 'Foul') {
        stats[player]!['Foul'] = (stats[player]!['Foul'] ?? 0) + 1;
        if (timestamp != null) {
          foulTimes.add(DateFormat.Hm().format(timestamp));
        }
      }
    }

    final sortedByGoals = stats.values.toList()
      ..sort((a, b) => (b['Goal'] as int).compareTo(a['Goal'] as int));
    final sortedByFouls = stats.values.toList()
      ..sort((a, b) => (b['Foul'] as int).compareTo(a['Foul'] as int));

    String? calculatedWinner;
    if (teamGoals.isNotEmpty) {
      var sortedTeams = teamGoals.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      if (sortedTeams.length > 1 && sortedTeams[0].value != sortedTeams[1].value) {
        calculatedWinner = sortedTeams[0].key;
      } else {
        calculatedWinner = 'Draw';
      }
    }

    int totalGoals = teamGoals.values.fold(0, (sum, g) => sum + g);
    int totalFouls = stats.values.fold(0, (sum, p) => sum + ((p['Foul'] ?? 0) as int));


    setState(() {
      topScorers = sortedByGoals.take(3).toList();
      topFoulers = sortedByFouls.take(3).toList();
      winner = calculatedWinner;
      avgGoals = totalGoals / (teamGoals.isNotEmpty ? teamGoals.length : 1);
      avgFouls = totalFouls / (teamGoals.isNotEmpty ? teamGoals.length : 1);
    });
  }

  Widget buildLeaderboardSection(String title, List<Map<String, dynamic>> data, String key) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...data.map((e) => ListTile(
          title: Text(e['player'] ?? ''),
          subtitle: Text("Team: ${e['team'] ?? ''}"),
          trailing: Text("${e[key]} $key", style: const TextStyle(fontWeight: FontWeight.bold)),
        )),
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Leaderboard")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              value: selectedMatchId,
              hint: const Text("Select Match"),
              onChanged: (String? value) {
                setState(() => selectedMatchId = value);
                if (value != null) fetchLeaderboard(value);
              },
              items: matches
                  .map((match) => DropdownMenuItem<String>(
                value: match['id'] as String,
                child: Text("${match['team1']} vs ${match['team2']}"),
              ))
                  .toList(),
            ),
            const SizedBox(height: 20),
            if (winner != null)
              Text("Winner: $winner", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            if (goalTimes.isNotEmpty)
              Text("Goal Times: ${goalTimes.join(', ')}"),
            if (foulTimes.isNotEmpty)
              Text("Foul Times: ${foulTimes.join(', ')}"),
            const SizedBox(height: 10),
            Text("Average Goals per Team: ${avgGoals.toStringAsFixed(2)}"),
            Text("Average Fouls per Team: ${avgFouls.toStringAsFixed(2)}"),
            const SizedBox(height: 20),
            if (topScorers.isNotEmpty) buildLeaderboardSection("Top 3 Scorers", topScorers, 'Goal'),
            if (topFoulers.isNotEmpty) buildLeaderboardSection("Top 3 Foul Makers", topFoulers, 'Foul'),
          ],
        ),
      ),
    );
  }
}
