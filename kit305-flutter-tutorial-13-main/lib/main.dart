import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'all_teams_page.dart';
import 'firebase_options.dart';
import 'match.dart'; // contains Match and MatchModel classes
import 'match_details.dart'; // contains MatchDetails screen
import 'match_history.dart';
import 'Player_Team_Stats_Comparison.dart';
import 'leaderboard.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  var app = await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print("\n\nConnected to Firebase App ${app.options.projectId}\n\n");

  runApp(const MatchApp());
}

class MatchApp extends StatelessWidget {
  const MatchApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<MatchModel>(
      create: (context) => MatchModel(),
      child: MaterialApp(
        title: 'Match Manager',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const MatchHomePage(title: 'Match Manager'),
      ),
    );
  }
}

class MatchHomePage extends StatefulWidget {
  const MatchHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MatchHomePage> createState() => _MatchHomePageState();
}

class _MatchHomePageState extends State<MatchHomePage> {
  @override
  Widget build(BuildContext context) {
    return Consumer<MatchModel>(
      builder: (context, matchModel, _) => Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const DrawerHeader(
                decoration: BoxDecoration(color: Colors.blue),
                child: Text('Match Manager Menu',
                    style: TextStyle(color: Colors.white, fontSize: 20)),
              ),
              ListTile(
                leading: Icon(Icons.history),
                title: const Text('Match History'),
                onTap: () {
                  Navigator.pop(context); // Close drawer
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MatchHistoryPage()),
                  );
                },
              ),
              ListTile(
                title: const Text('Player & Team Stats Comparison'),
                leading: const Icon(Icons.bar_chart),
                onTap: () async {
                  Navigator.pop(context); // Close drawer

                  final selectedMatch = await showDialog<String>(
                    context: context,
                    builder: (context) {
                      final matches = Provider.of<MatchModel>(context, listen: false).items;
                      return AlertDialog(
                        title: const Text("Select a Match"),
                        content: SizedBox(
                          width: double.maxFinite,
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: matches.length,
                            itemBuilder: (_, index) {
                              final match = matches[index];
                              return ListTile(
                                title: Text("${match.team1} vs ${match.team2}"),
                                subtitle: Text(match.date),
                                onTap: () => Navigator.pop(context, match.id),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  );

                  if (selectedMatch != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StatsComparisonPage(matchId: selectedMatch),
                      ),
                    );
                  }
                },
              ),
              ListTile(
                leading: Icon(Icons.leaderboard_sharp),
                title: const Text('Leaderboard'),
                onTap: () {
                  Navigator.pop(context); // Close drawer
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LeaderboardPage()),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.group),
                title: const Text('Teams'),
                onTap: () {
                  Navigator.pop(context); // Close drawer
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AllTeamsPage()),
                  );
                },
              ),
              // Add more items if needed
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.add),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => const MatchDetails(),
            );
          },
        ),
        body: matchModel.loading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
          itemCount: matchModel.items.length,
          itemBuilder: (_, index) {
            var match = matchModel.items[index];
            return Dismissible(
              key: Key(match.id),
              direction: DismissDirection.horizontal,
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(left: 20),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              secondaryBackground: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              onDismissed: (_) async {
                await matchModel.delete(match.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Deleted ${match.team1} vs ${match.team2}")),
                );
              },
              child: ListTile(
                title: Text("${match.team1} vs ${match.team2}"),
                subtitle: Text("${match.date} - ${match.location} - ${match.status}"),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => MatchDetails(id: match.id)),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
