import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tutorial_3/record_actions_page.dart';
import 'package:provider/provider.dart';

import 'match.dart';
import 'team_members_page.dart';

class MatchDetails extends StatefulWidget {
  final String? id;
  const MatchDetails({Key? key, this.id}) : super(key: key);

  @override
  State<MatchDetails> createState() => _MatchDetailsState();
}

class _MatchDetailsState extends State<MatchDetails> {
  final _formKey = GlobalKey<FormState>();
  final dateController = TextEditingController();
  final timeController = TextEditingController();
  final locationController = TextEditingController();
  final statusController = TextEditingController();

  List<String> teamNames = [];            // ← dynamic list now
  String? selectedTeam1;
  String? selectedTeam2;
  bool loadingTeams = true;               // show a loader until teams load

  @override
  void initState() {
    super.initState();
    fetchTeamNames();                        // load teams from “all_teams”
    _loadMatchIfEditing();                // load existing match if editing
  }

  /// Pull team IDs from the `all_teams` collection
  Future<void> fetchTeamNames() async {
    final snap = await FirebaseFirestore.instance.collection('all_teams').get();
    final fetched = snap.docs.map((d) => d.id).toList();

    final matchModel = Provider.of<MatchModel>(context, listen: false);
    final match      = matchModel.get(widget.id);

    // Ensure selected teams exist in the dropdown list
    if (match != null) {
      if (!fetched.contains(match.team1)) fetched.add(match.team1);
      if (!fetched.contains(match.team2)) fetched.add(match.team2);

      selectedTeam1 = match.team1;
      selectedTeam2 = match.team2;
      dateController.text     = match.date;
      timeController.text     = match.time;
      locationController.text = match.location;
      statusController.text   = match.status;
    }

    setState(() {
      teamNames = fetched.toSet().toList(); // deduplicate
      loadingTeams = false;
    });
  }


  /// If editing, populate form fields and dropdowns
  void _loadMatchIfEditing() {
    final matchModel = Provider.of<MatchModel>(context, listen: false);
    final match = matchModel.get(widget.id);
    if (match != null) {
      selectedTeam1 = match.team1;
      selectedTeam2 = match.team2;
      dateController.text = match.date;
      timeController.text = match.time;
      locationController.text = match.location;
      statusController.text = match.status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final matchModel = Provider.of<MatchModel>(context, listen: false);
    final isAdding = widget.id == null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isAdding ? 'Add Match' : 'Edit Match'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: loadingTeams
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // ─── Team 1 Dropdown ────────────────────────────────────
              DropdownButtonFormField<String>(
                value: selectedTeam1,
                decoration: const InputDecoration(labelText: 'Team 1'),
                items: teamNames
                    .map((name) =>
                    DropdownMenuItem(value: name, child: Text(name)))
                    .toList(),
                onChanged: (val) => setState(() => selectedTeam1 = val),
                validator: (val) =>
                val == null ? 'Select team 1' : null,
              ),
              // ─── Team 2 Dropdown ────────────────────────────────────
              DropdownButtonFormField<String>(
                value: selectedTeam2,
                decoration: const InputDecoration(labelText: 'Team 2'),
                items: teamNames
                    .map((name) =>
                    DropdownMenuItem(value: name, child: Text(name)))
                    .toList(),
                onChanged: (val) => setState(() => selectedTeam2 = val),
                validator: (val) =>
                val == null ? 'Select team 2' : null,
              ),
              // ─── Remaining TextFields ───────────────────────────────
              TextFormField(
                controller: dateController,
                decoration: const InputDecoration(labelText: 'Date'),
                validator: (v) =>
                v == null || v.isEmpty ? 'Enter date' : null,
              ),
              TextFormField(
                controller: timeController,
                decoration: const InputDecoration(labelText: 'Time'),
                validator: (v) =>
                v == null || v.isEmpty ? 'Enter time' : null,
              ),
              TextFormField(
                controller: locationController,
                decoration: const InputDecoration(labelText: 'Location'),
                validator: (v) =>
                v == null || v.isEmpty ? 'Enter location' : null,
              ),
              TextFormField(
                controller: statusController,
                decoration: const InputDecoration(labelText: 'Status'),
                validator: (v) =>
                v == null || v.isEmpty ? 'Enter status' : null,
              ),
              const SizedBox(height: 16),
              // ─── View Members & Record Actions (edit-only) ──────────
              if (!isAdding) ...[
                ElevatedButton.icon(
                  icon: const Icon(Icons.group),
                  label: const Text('View Team 1 Members'),
                  onPressed: selectedTeam1 == null
                      ? null
                      : () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TeamMembersPage(
                          teamName: selectedTeam1!),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  icon: const Icon(Icons.group),
                  label: const Text('View Team 2 Members'),
                  onPressed: selectedTeam2 == null
                      ? null
                      : () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TeamMembersPage(
                          teamName: selectedTeam2!),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  child: const Text('Record Actions'),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          RecordActionsPage(matchId: widget.id!),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              // ─── Save - Add / Update ────────────────────────────────
              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: Text(isAdding ? 'Add Match' : 'Update Match'),
                onPressed: () async {
                  if (_formKey.currentState?.validate() ?? false) {
                    if (selectedTeam1 == selectedTeam2) {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Invalid Selection'),
                          content: const Text(
                              'Team 1 and Team 2 cannot be the same.'),
                          actions: [
                            TextButton(
                                onPressed: () =>
                                    Navigator.pop(context),
                                child: const Text('OK')),
                          ],
                        ),
                      );
                      return;
                    }

                    final newMatch = Match(
                      team1: selectedTeam1!,
                      team2: selectedTeam2!,
                      date: dateController.text,
                      time: timeController.text,
                      location: locationController.text,
                      status: statusController.text,
                    );

                    if (isAdding) {
                      await matchModel.add(newMatch);
                    } else {
                      await matchModel.updateItem(widget.id!, newMatch);
                    }

                    if (context.mounted) Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
