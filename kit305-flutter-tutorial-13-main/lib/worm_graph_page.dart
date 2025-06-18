import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class WormGraphPage extends StatelessWidget {
  final String matchId;
  final String teamA;
  final String teamB;

  const WormGraphPage({
    Key? key,
    required this.matchId,
    required this.teamA,
    required this.teamB,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Worm Graph')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<QuerySnapshot>(
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

            final actions = snapshot.data!.docs
                .map((doc) => doc.data() as Map<String, dynamic>)
                .toList();

            return WormChart(actions: actions, teamA: teamA, teamB: teamB);
          },
        ),
      ),
    );
  }
}

class WormChart extends StatelessWidget {
  final List<Map<String, dynamic>> actions;
  final String teamA;
  final String teamB;

  const WormChart({
    required this.actions,
    required this.teamA,
    required this.teamB,
  });

  @override
  Widget build(BuildContext context) {
    final List<FlSpot> marginSpots = [];
    int scoreA = 0,
        scoreB = 0;

    actions
      ..sort((a, b) =>
          (a['matchTime'] ?? 0).compareTo(b['matchTime'] ?? 0))
      ..forEach((a) {
        final act = a['action'] as String?;
        final team = a['team'] as String?;
        final t = (a['matchTime'] ?? 0).toDouble();

        if (act == 'Goal') {
          if (team == teamA) scoreA += 6;
          if (team == teamB) scoreB += 6;
        } else if (act == 'Behind') {
          if (team == teamA) scoreA += 1;
          if (team == teamB) scoreB += 1;
        }
        marginSpots.add(FlSpot(t, (scoreA - scoreB).toDouble()));
      });

    return AspectRatio(
      aspectRatio: 1.8,
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                // The line chart fills entire space
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: LineChart(
                      LineChartData(
                        minY: -90,
                        maxY: 90,
                        gridData: FlGridData(show: true),
                        lineBarsData: [
                          LineChartBarData(
                            spots: marginSpots,
                            isCurved: false,
                            color: Colors.red,
                            barWidth: 2,
                            dotData: FlDotData(show: false),
                          ),
                        ],
                        titlesData: FlTitlesData(
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: true),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),

                        ),
                        lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                            tooltipBgColor: Colors.black87,
                            getTooltipItems: (spots) =>
                                spots.map((s) {
                                  final t = s.x.toInt();
                                  final diff = s.y.toInt();
                                  return LineTooltipItem(
                                    'Time: ${t}s\nMargin: $diff',
                                    const TextStyle(color: Colors.white),
                                  );
                                }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // The red & blue bar positioned on left inside chart with some padding
                Positioned(
                  top: 0,
                  bottom: 22,
                  left: 0,
                  width: 16,
                  child: Column(
                    children: [
                      Expanded(flex: 1, child: Container(color: Colors.red)),
                      Expanded(flex: 1, child: Container(color: Colors.blue)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Team A Label
              Row(
                children: [
                  Container(width: 16, height: 16, color: Colors.red),
                  const SizedBox(width: 8),
                  Text(
                    teamA,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              // Team B Label
              Row(
                children: [
                  Container(width: 16, height: 16, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    teamB,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}