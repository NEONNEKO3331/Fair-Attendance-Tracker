import 'package:flutter/material.dart';
import '../services/participation_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final data = await ParticipationService.getHistory();
    setState(() => history = data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Participation History")),
      body: history.isEmpty
          ? const Center(child: Text("No participation records yet"))
          : ListView.builder(
              itemCount: history.length,
              itemBuilder: (context, index) {
                final item = history[index];
                return ListTile(
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                  title: Text(item['fairName']),
                  subtitle: Text(item['timestamp']),
                  trailing: Text("+${item['points']} pts",
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                );
              },
            ),
    );
  }
}