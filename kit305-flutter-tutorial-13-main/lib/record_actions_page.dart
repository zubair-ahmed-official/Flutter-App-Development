import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_tutorial_3/worm_graph_page.dart';
import 'package:share_plus/share_plus.dart';

class RecordActionsPage extends StatefulWidget {
  final String matchId;

  const RecordActionsPage({Key? key, required this.matchId}) : super(key: key);

  @override
  State<RecordActionsPage> createState() => _RecordActionsPageState();
}

class _RecordActionsPageState extends State<RecordActionsPage> {
  String? selectedTeam;
  String? selectedPlayer;
  String selectedAction = 'Kick';

  List<String> actions = [
    'Kick',
    'Foul',
    'Penalty',
    'Free Kick',
    'Offside',
    'Yellow Card',
    'Red Card',
    'Goal',
    'Behind'
  ];

  List<String> teamNames = [];
  List<String> playerNames = [];
  bool matchStarted = false;
  Timer? matchTimer;
  int secondsElapsed = 0;
  int team1Goals = 0;
  int team2Goals = 0;

  @override
  void initState() {
    super.initState();
    fetchTeams();
    fetchGoals();
  }

  Future<void> fetchTeams() async {
    final doc = await FirebaseFirestore.instance
        .collection('matches')
        .doc(widget.matchId)
        .get();

    final data = doc.data();
    if (data != null) {
      setState(() {
        teamNames = [data['team1'], data['team2']];
      });
    }
  }

  Future<void> updateMatchStatusToDone() async {
    await FirebaseFirestore.instance
        .collection('matches')
        .doc(widget.matchId)
        .update({'status': 'Match Done'});
  }


  Future<void> fetchGoals() async {
    final actions = await FirebaseFirestore.instance
        .collection('match_actions')
        .doc(widget.matchId)
        .collection('actions')
        .get();

    int t1 = 0;
    int t2 = 0;

    for (var doc in actions.docs) {
      final data = doc.data();
      if (data['action'] == 'Goal') {
        if (data['team'] == teamNames[0]) {
          t1++;
        } else if (data['team'] == teamNames[1]) {
          t2++;
        }
      }
    }

    setState(() {
      team1Goals = t1;
      team2Goals = t2;
    });
  }

  Future<void> fetchPlayers(String teamName) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('teams')
        .doc(teamName)
        .collection('players')
        .get();

    setState(() {
      playerNames =
          snapshot.docs.map((doc) => doc.data()['name'].toString()).toList();
      selectedPlayer = null;
    });
  }

  void startTimer() {
    matchTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        secondsElapsed++;

        if (secondsElapsed == 30) {
          matchTimer?.cancel();
          matchStarted = false;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('First Half Over. Tap Start Match to begin Second Half')),
          );
        } else if (secondsElapsed == 60) {
          endMatch();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Match Ended Automatically')),
          );
        }
      });
    });
  }

  void startMatch() {
    if (!matchStarted) {
      setState(() {
        matchStarted = true;
      });
      startTimer();
    }
  }

  void endMatch() {
    matchTimer?.cancel();
    setState(() {
      matchStarted = false;
    });
    updateMatchStatusToDone();
  }

  void stopTimer() {
    matchTimer?.cancel();
  }

  String formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Future<void> recordAction() async {
    if (!matchStarted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Start the match first')),
      );
      return;
    }

    if (selectedTeam == null || selectedPlayer == null) return;

    final actionsRef = FirebaseFirestore.instance
        .collection('match_actions')
        .doc(widget.matchId)
        .collection('actions');

    final existingActions = await actionsRef.orderBy('timestamp').get();

    if (existingActions.docs.isEmpty && selectedAction != 'Kick') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Match must start with a Kick.')),
      );
      return;
    }

    if (["Penalty","Free Kick","Offside", "Yellow Card", "Red Card"].contains(selectedAction)) {
      final fouls = existingActions.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return data['player'] == selectedPlayer && data['action'] == 'Foul';
      });

      if (fouls.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$selectedAction requires a prior Foul.')),
        );
        return;
      }
    }

    if (selectedAction == 'Goal') {
      final kicks = existingActions.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return data['player'] == selectedPlayer && data['action'] == 'Kick';
      });

      if (kicks.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('A Goal must be preceded by a Kick from the same player.')),
        );
        return;
      }
    }

    await actionsRef.add({
      'team': selectedTeam,
      'player': selectedPlayer,
      'action': selectedAction,
      'timestamp': Timestamp.now(),
      'matchTime': secondsElapsed,
    });

    if (selectedAction == 'Goal') {
      fetchGoals();
    }
  }

  Future<void> shareActionsAsJson() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('match_actions')
        .doc(widget.matchId)
        .collection('actions')
        .orderBy('timestamp')
        .get();

    final jsonList = snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'team': data['team'],
        'player': data['player'],
        'action': data['action'],
        'matchTime': formatTime(data['matchTime'] ?? 0),
        'timestamp': (data['timestamp'] as Timestamp).toDate().toIso8601String(),
      };
    }).toList();

    final jsonText = const JsonEncoder.withIndent('  ').convert(jsonList);
    await Share.share(jsonText);
  }

  @override
  void dispose() {
    matchTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Actions'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: ElevatedButton.icon(
              onPressed: shareActionsAsJson,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.blue,
                side: const BorderSide(color: Colors.blue, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.share),
              label: const Text('Share'),
            ),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Match Time: ${formatTime(secondsElapsed)}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 6),
            if (teamNames.length == 2)
              Text('${teamNames[0]} $team1Goals : $team2Goals ${teamNames[1]}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(onPressed: startMatch, child: const Text('Start Match')),
                ElevatedButton(onPressed: endMatch, child: const Text('End Match')),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedTeam,
              hint: const Text('Select Team'),
              onChanged: (value) {
                if (value != null) {
                  setState(() => selectedTeam = value);
                  fetchPlayers(value);
                }
              },
              items: teamNames.map((team) => DropdownMenuItem(value: team, child: Text(team))).toList(),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedPlayer,
              hint: const Text('Select Player'),
              onChanged: (value) => setState(() => selectedPlayer = value),
              items: playerNames.map((player) => DropdownMenuItem(value: player, child: Text(player))).toList(),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedAction,
              onChanged: (value) {
                if (value != null) setState(() => selectedAction = value);
              },
              items: actions.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
              decoration: const InputDecoration(labelText: 'Select Action'),
            ),
            // const SizedBox(height: 16),
            // ElevatedButton.icon(
            //   onPressed: recordAction,
            //   icon: const Icon(Icons.check),
            //   label: const Text('Record'),
            // ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: recordAction,
                  icon: const Icon(Icons.check),
                  label: const Text('Record'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    if (teamNames.length < 2) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WormGraphPage(
                          matchId: widget.matchId,
                          teamA: teamNames[0],
                          teamB: teamNames[1],
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.show_chart),
                  label: const Text('View Worm Graph'),
                ),
              ],
            ),


            const SizedBox(height: 16),
            const Divider(),
            const Text('Recorded Actions', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('match_actions')
                    .doc(widget.matchId)
                    .collection('actions')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final actions = snapshot.data!.docs;

                  if (actions.isEmpty) {
                    return const Text('No actions recorded yet.');
                  }

                  return ListView.builder(
                    itemCount: actions.length,
                    itemBuilder: (context, index) {
                      final action = actions[index].data() as Map<String, dynamic>;
                      final team = action['team'];
                      final player = action['player'];
                      final act = action['action'];
                      return ListTile(
                        leading: const Icon(Icons.sports_soccer),
                        title: Text('$player - $act'),
                        subtitle: Text('Team: $team | Time: ${formatTime(action['matchTime'] ?? 0)}'),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
