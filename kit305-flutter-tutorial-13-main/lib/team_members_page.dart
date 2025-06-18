import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_team_member_page.dart';

class TeamMembersPage extends StatefulWidget {
  final String teamName;

  const TeamMembersPage({Key? key, required this.teamName}) : super(key: key);

  @override
  State<TeamMembersPage> createState() => _TeamMembersPageState();
}

class _TeamMembersPageState extends State<TeamMembersPage> {
  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';

  Future<bool> _onWillPop() async {
    final playersRef = FirebaseFirestore.instance
        .collection('teams')
        .doc(widget.teamName)
        .collection('players');

    final snapshot = await playersRef.get();
    if (snapshot.docs.length < 2) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Not enough players'),
          content: const Text('Each team must have at least 2 players before continuing.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(), // Close the dialog
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return false; // Prevent back navigation
    }

    return true; // Allow back navigation
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final CollectionReference playersRef = FirebaseFirestore.instance
        .collection('teams')
        .doc(widget.teamName)
        .collection('players');

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Players: ${widget.teamName}'),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Search player by name',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    searchQuery = value.toLowerCase();
                  });
                },
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: playersRef.snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No players found.'));
                  }

                  final allPlayers = snapshot.data!.docs;
                  final filteredPlayers = allPlayers.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final name = data['name']?.toString().toLowerCase() ?? '';
                    return name.contains(searchQuery);
                  }).toList();

                  return ListView.builder(
                    itemCount: filteredPlayers.length,
                    itemBuilder: (context, index) {
                      final doc = filteredPlayers[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final playerName = data['name'] ?? 'Unknown';
                      final position = data['position'] ?? 'Position';
                      final imageUrl = data['imageUrl'];

                      return ListTile(
                        leading: imageUrl != null
                            ? CircleAvatar(backgroundImage: NetworkImage(imageUrl))
                            : const CircleAvatar(child: Icon(Icons.person)),
                        title: Text(playerName),
                        subtitle: Text(position),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            await playersRef.doc(doc.id).delete();
                          },
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddTeamMemberPage(
                                teamName: widget.teamName,
                                playerId: doc.id,
                                initialData: data,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddTeamMemberPage(teamName: widget.teamName),
              ),
            );
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
