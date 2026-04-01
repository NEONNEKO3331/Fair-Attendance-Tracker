import 'package:flutter/material.dart';
import '../services/participation_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> history = [];
  int totalPoints = 0;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final data = await ParticipationService.getHistory();
    final points = await ParticipationService.getTotalPoints();
    setState(() {
      history = data;
      totalPoints = points;
    });
  }

  Future<void> _deleteRecord(int index) async {
  final deletedPoints = await ParticipationService.deleteParticipation(index);
  
  final newTotal = await ParticipationService.getTotalPoints();

  setState(() {
    history.removeAt(index);
    totalPoints = newTotal;
  });

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text("Record deleted (-$deletedPoints points)")),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Participation History"),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: Text(
                "Total: $totalPoints pts",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: history.isEmpty
          ? const Center(child: Text("No participation records yet"))
          : ListView.builder(
              itemCount: history.length,
              itemBuilder: (context, index) {
                final item = history[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    leading: const Icon(Icons.check_circle, color: Colors.green),
                    title: Text(item['fairName']),
                    subtitle: Text(item['timestamp']),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "+${item['points']} pts",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteRecord(index),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}