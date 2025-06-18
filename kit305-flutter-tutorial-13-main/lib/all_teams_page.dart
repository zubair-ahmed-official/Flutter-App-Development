import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'team_members_page.dart';

class AllTeamsPage extends StatefulWidget {
  @override
  _AllTeamsPageState createState() => _AllTeamsPageState();
}

class _AllTeamsPageState extends State<AllTeamsPage> {
  final CollectionReference teamsRef =
  FirebaseFirestore.instance.collection('all_teams');

  Future<void> _addTeamDialog() async {
    final TextEditingController teamController = TextEditingController();

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Team'),
          content: TextField(
            controller: teamController,
            decoration: const InputDecoration(hintText: 'Enter team name'),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Add'),
              onPressed: () async {
                final teamName = teamController.text.trim();
                if (teamName.isNotEmpty) {
                  await teamsRef.doc(teamName).set({'name': teamName});
                  setState(() {}); // Refresh list
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<List<String>> _fetchTeams() async {
    final snapshot = await teamsRef.get();
    return snapshot.docs.map((doc) => doc.id).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teams'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add Teams'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Theme.of(context).colorScheme.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Theme.of(context).colorScheme.primary),
                ),
              ),
              onPressed: _addTeamDialog,
            ),
          ),
        ],
      ),

      body: FutureBuilder<List<String>>(
        future: _fetchTeams(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final teams = snapshot.data ?? [];

          if (teams.isEmpty) {
            return const Center(child: Text('No teams found'));
          }

          return ListView.builder(
            itemCount: teams.length,
            itemBuilder: (context, index) {
              final teamName = teams[index];
              return ListTile(
                title: Text(teamName),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TeamMembersPage(teamName: teamName),
                    ),
                  );
                },
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Team'),
                        content: Text('Are you sure you want to delete the team "$teamName"?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      await teamsRef.doc(teamName).delete();
                      setState(() {}); // Refresh list
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Deleted team "$teamName"')),
                      );
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
