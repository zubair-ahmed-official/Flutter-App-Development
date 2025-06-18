import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Match {
  late String id;
  String team1;
  String team2;
  String date;
  String location;
  String time;
  String status;

  Match({
    required this.team1,
    required this.team2,
    required this.date,
    required this.location,
    required this.time,
    required this.status,
  });

  Match.fromJson(Map<String, dynamic> json, this.id)
      : team1 = json['team1'] ?? '',
        team2 = json['team2'] ?? '',
        date = json['date'] ?? '',
        location = json['location'] ?? '',
        time = json['time'] ?? '',
        status = json['status'] ?? '';

  Map<String, dynamic> toJson() => {
    'team1': team1,
    'team2': team2,
    'date': date,
    'location': location,
    'time': time,
    'status': status,
  };
}


class MatchModel extends ChangeNotifier {
  final List<Match> items = [];
  final CollectionReference matchesCollection =
  FirebaseFirestore.instance.collection('matches');

  bool loading = true;
  StreamSubscription<QuerySnapshot>? _subscription;

  MatchModel() {
    // Start listening to real-time updates instead of one-time fetch
    listenToMatches();
  }

  void listenToMatches() {
    loading = true;
    notifyListeners();

    _subscription?.cancel(); // Cancel previous subscription if any
    _subscription = matchesCollection.snapshots().listen(
          (snapshot) {
        items.clear();
        for (var doc in snapshot.docs) {
          var match = Match.fromJson(doc.data()! as Map<String, dynamic>, doc.id);
          items.add(match);
        }
        loading = false;
        notifyListeners();
      },
      onError: (error) {
        print('Error listening to matches: $error');
        loading = false;
        notifyListeners();
      },
    );
  }

  Match? get(String? id) {
    if (id == null) return null;
    return items.firstWhere((match) => match.id == id, orElse: () => null as Match);
  }

  // Remove the old fetch method or keep it if you want for manual refresh
  Future<void> fetch() async {
    items.clear();
    loading = true;
    notifyListeners();

    try {
      final querySnapshot = await matchesCollection.get();

      for (var doc in querySnapshot.docs) {
        var match = Match.fromJson(doc.data()! as Map<String, dynamic>, doc.id);
        items.add(match);
      }
    } catch (e) {
      print('Error fetching matches: $e');
    }

    loading = false;
    notifyListeners();
  }

  Future<void> add(Match match) async {
    loading = true;
    notifyListeners();

    await matchesCollection.add(match.toJson());
    // No need to call fetch(), real-time listener updates items automatically
  }

  Future<void> updateItem(String id, Match match) async {
    loading = true;
    notifyListeners();

    await matchesCollection.doc(id).set(match.toJson());
    // No need to call fetch()
  }

  Future<void> delete(String id) async {
    loading = true;
    notifyListeners();

    await matchesCollection.doc(id).delete();
    // No need to call fetch()
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
