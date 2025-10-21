// lib/screens/call_logs/call_logs_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/database_service.dart';
import '../../models/call_log_model.dart';

class CallLogsScreen extends StatefulWidget {
  const CallLogsScreen({Key? key}) : super(key: key);

  @override
  State<CallLogsScreen> createState() => _CallLogsScreenState();
}

class _CallLogsScreenState extends State<CallLogsScreen> {
  List<CallLogModel> _callLogs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCallLogs();
  }

  Future<void> _loadCallLogs() async {
    setState(() => _isLoading = true);

    try {
      final dbService = context.read<DatabaseService>();
      final callLogs = await dbService.getAllCallLogs();

      setState(() {
        _callLogs = callLogs;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading call logs: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteCallLog(CallLogModel callLog) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          'Delete Call Log',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to delete this call log?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await context.read<DatabaseService>().deleteCallLog(callLog.id);
      _loadCallLogs();
    }
  }

  IconData _getCallIcon(CallType type) {
    switch (type) {
      case CallType.incoming:
        return Icons.call_received;
      case CallType.outgoing:
        return Icons.call_made;
      case CallType.missed:
        return Icons.call_missed;
    }
  }

  Color _getCallColor(CallType type) {
    switch (type) {
      case CallType.incoming:
        return Colors.green;
      case CallType.outgoing:
        return Colors.blue;
      case CallType.missed:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_callLogs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.history, size: 80, color: Colors.white24),
            SizedBox(height: 16),
            Text(
              'No call history',
              style: TextStyle(fontSize: 18, color: Colors.white70),
            ),
            SizedBox(height: 8),
            Text(
              'Your call history will appear here',
              style: TextStyle(fontSize: 14, color: Colors.white54),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _callLogs.length,
      itemBuilder: (context, index) {
        final callLog = _callLogs[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: const Color(0xFF1A1A2E),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getCallColor(callLog.callType).withOpacity(0.2),
              child: Icon(
                _getCallIcon(callLog.callType),
                color: _getCallColor(callLog.callType),
              ),
            ),
            title: Text(
              callLog.contactName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('MMM dd, yyyy - HH:mm').format(callLog.timestamp),
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                Text(
                  'Duration: ${callLog.formattedDuration}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteCallLog(callLog),
            ),
          ),
        );
      },
    );
  }
}
