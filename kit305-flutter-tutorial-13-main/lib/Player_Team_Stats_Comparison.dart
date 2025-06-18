// This Dart file provides comparison between players of two teams for a specific match.

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StatsComparisonPage extends StatefulWidget {
  final String matchId;

  const StatsComparisonPage({Key? key, required this.matchId}) : super(key: key);

  @override
  State<StatsComparisonPage> createState() => _StatsComparisonPageState();
}

class _StatsComparisonPageState extends State<StatsComparisonPage> {
  Map<String, Map<String, int>> playerStats = {}; // playerName: {action: count}
  Map<String, List<String>> teamPlayers = {}; // teamName: list of player names
  Map<String, int> team1Stats = {};
  Map<String, int> team2Stats = {};
  String? team1;
  String? team2;
  String? selectedPlayer1;
  String? selectedPlayer2;
  String? selectedAction;

  @override
  void initState() {
    super.initState();
    fetchMatchDetails();
  }

  Future<void> fetchMatchDetails() async {
    final matchDoc = await FirebaseFirestore.instance
        .collection('matches')
        .doc(widget.matchId)
        .get();

    final matchData = matchDoc.data();
    if (matchData != null) {
      team1 = matchData['team1'];
      team2 = matchData['team2'];
      await fetchStats();
    }
  }

  Future<void> fetchStats() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('match_actions')
        .doc(widget.matchId)
        .collection('actions')
        .get();

    Map<String, Map<String, int>> tempPlayerStats = {};
    Map<String, List<String>> tempTeamPlayers = {};
    Map<String, int> t1Stats = {};
    Map<String, int> t2Stats = {};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final player = data['player']?.toString() ?? '';
      final action = data['action']?.toString() ?? '';
      final team = data['team']?.toString() ?? '';

      tempTeamPlayers.putIfAbsent(team, () => []);
      if (!tempTeamPlayers[team]!.contains(player)) {
        tempTeamPlayers[team]!.add(player);
      }

      tempPlayerStats[player] ??= {};
      tempPlayerStats[player]![action] = (tempPlayerStats[player]![action] ?? 0) + 1;

      if (team == team1) {
        t1Stats[action] = (t1Stats[action] ?? 0) + 1;
      } else if (team == team2) {
        t2Stats[action] = (t2Stats[action] ?? 0) + 1;
      }
    }

    setState(() {
      playerStats = tempPlayerStats;
      teamPlayers = tempTeamPlayers;
      team1Stats = t1Stats;
      team2Stats = t2Stats;
    });
  }

  Widget buildTeamComparisonTable() {
    List<String> actions = [
      'Goal',
      'Kick',
      'Foul',
      'Penalty',
      'Red Card',
      'Yellow Card',
      'Free Kick',
      'Offside',
    ];

    return Table(
      border: TableBorder.all(),
      columnWidths: const {
        0: FlexColumnWidth(),
        1: FlexColumnWidth(),
        2: FlexColumnWidth(),
      },
      children: [
        TableRow(
          decoration: const BoxDecoration(color: Colors.grey),
          children: [
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Action', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(team1 ?? 'Team 1', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(team2 ?? 'Team 2', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        ...actions.map((action) => TableRow(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(action),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('${team1Stats[action] ?? 0}'),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('${team2Stats[action] ?? 0}'),
            ),
          ],
        ))
      ],
    );
  }

  Widget buildComparisonTable() {
    final count1 = selectedPlayer1 != null && selectedAction != null
        ? (playerStats[selectedPlayer1!]?[selectedAction!] ?? 0)
        : 0;
    final count2 = selectedPlayer2 != null && selectedAction != null
        ? (playerStats[selectedPlayer2!]?[selectedAction!] ?? 0)
        : 0;

    return Table(
      border: TableBorder.all(),
      columnWidths: const {
        0: FlexColumnWidth(),
        1: FlexColumnWidth(),
      },
      children: [
        TableRow(
          decoration: const BoxDecoration(color: Colors.grey),
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(selectedPlayer1 ?? 'Player 1', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(selectedPlayer2 ?? 'Player 2', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        TableRow(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('$count1 ${selectedAction ?? ''}'),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('$count2 ${selectedAction ?? ''}'),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final team1Players = team1 != null ? teamPlayers[team1] ?? [] : [];
    final team2Players = team2 != null ? teamPlayers[team2] ?? [] : [];
    final actionTypes = playerStats.values.expand((m) => m.keys).toSet().toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Compare Teams & Players")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (team1 != null && team2 != null)
                Text("$team1 vs $team2", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              buildTeamComparisonTable(),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: selectedPlayer1,
                hint: Text("Select Player from $team1"),
                onChanged: (String? value) => setState(() => selectedPlayer1 = value),
                items: team1Players
                    .map((name) => DropdownMenuItem<String>(value: name, child: Text(name)))
                    .toList(),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedPlayer2,
                hint: Text("Select Player from $team2"),
                onChanged: (String? value) => setState(() => selectedPlayer2 = value),
                items: team2Players
                    .map((name) => DropdownMenuItem<String>(value: name, child: Text(name)))
                    .toList(),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedAction,
                hint: const Text("Select Action"),
                onChanged: (String? value) => setState(() => selectedAction = value),
                items: actionTypes
                    .map((action) => DropdownMenuItem<String>(value: action, child: Text(action)))
                    .toList(),
              ),
              const SizedBox(height: 20),
              if (selectedPlayer1 != null && selectedPlayer2 != null && selectedAction != null)
                buildComparisonTable(),
            ],
          ),
        ),
      ),
    );
  }
}
